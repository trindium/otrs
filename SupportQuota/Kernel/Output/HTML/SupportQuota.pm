# --
# Kernel/Output/HTML/SupportQuota.pm
# Copyright (C) 2001-2014 Deny Dias, http://mexapi.macpress.com.br/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::SupportQuota;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (
        qw(ConfigObject DBObject LayoutObject)
        )
    {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check data
    return if !$Self->{TicketID};

    # get data: customer contracted and used quotas for the current month
    my %Data = ();
    my $SQL = "
        SELECT cc.quota, SUM(ta.time_unit)
        FROM ticket t
        INNER JOIN customer_company cc ON cc.customer_id=t.customer_id
        INNER JOIN time_accounting ta ON ta.ticket_id=t.id
        WHERE
            t.customer_id IN (SELECT customer_id FROM ticket WHERE id = ?)
            AND ta.time_unit IS NOT NULL
            AND EXTRACT(YEAR FROM t.create_time) = EXTRACT(YEAR FROM NOW())
            AND EXTRACT(MONTH FROM t.create_time) = EXTRACT(MONTH FROM NOW())
        GROUP BY t.customer_id";
    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Self->{TicketID} ],
        Limit => 1,
    );
    while (my @Row = $Self->{DBObject}->FetchrowArray()) {
        $Data{ContractQuota} = $Row[0];
        $Data{UsedQuota}     = $Row[1];
    }

    # format and calculate remaining data
    my $ContractQuota  = sprintf '%.1f', $Data{ContractQuota};
    my $UsedQuota      = sprintf '%.1f', $Data{UsedQuota};
    my $AvailableQuota = sprintf '%.1f', $ContractQuota - $UsedQuota;

    my $Template = q~
            <div class="WidgetSimple">
                <div class="Header">
                    <h2>$Text{"Customer Support Quota"}</h2>
                </div>
                <div class="Content">
                    <fieldset class="TableLike FixedLabelSmall Narrow">
                        <label>$Text{"Available"}:</label>
                        <p class="Value">$QData{"Available"}</p>
                        <div class="Clear"></div>
                        <label>$Text{"Used"}:</label>
                        <p class="Value">$QData{"Used"}</p>
                        <div class="Clear"></div>
                        <label>$Text{"Contracted"}:</label>
                        <p class="Value">$QData{"Contracted"}</p>
                        <div class="Clear"></div>
                    </fieldset>
                </div>
            </div>
    ~;

    my $HTML = $Self->{LayoutObject}->Output(
        Template => $Template,
        Data     => {
            Available  => $AvailableQuota,
            Used       => $UsedQuota,
            Contracted => $ContractQuota,
        },
    );

    # add information
    ${ $Param{Data} } =~ s{ (<\!--\sdtl:block:CustomerTable\s-->) }{ $HTML $1 }ixms;

    return $Param{Data};
}

1;