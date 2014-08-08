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

    # get data
    my %Data = ();

    # initial sql statement with mandatory data
    my $SQL_PRE = "
        SELECT cc.quota AS Cquota,
               Sum(ta.time_unit) AS Uquota
        FROM   customer_company cc
               INNER JOIN ticket t
                      ON t.customer_id = cc.customer_id
               LEFT OUTER JOIN time_accounting ta
                      ON ta.ticket_id = t.id
        WHERE  cc.customer_id = (SELECT customer_id
                                FROM    ticket
                                WHERE   id = ?)
               AND ta.time_unit IS NOT NULL";

    # additional sql statement matching for the recurrence period
    my $Recurrence = $Self->{ConfigObject}->Get('SupportQuota::Preferences::Recurrence');
    my $RecurrenceLabel = "";
    my $SQL_RECURRENCE = "";
    if ( $Recurrence eq 'month' ) {
        $RecurrenceLabel = "(Monthly)";
        $SQL_RECURRENCE = "
               AND Extract(year FROM ta.create_time) = Extract(year FROM Now())
               AND Extract(month FROM ta.create_time) = Extract(month FROM Now())";
    } elsif ( $Recurrence eq 'year' ) {
        $RecurrenceLabel = "(Yearly)";
        $SQL_RECURRENCE = "
               AND Extract(year FROM ta.create_time) = Extract(year FROM Now())";
    } else {
        $RecurrenceLabel = "";
    }

    # compose final sql statement
    my $SQL = "${SQL_PRE} ${SQL_RECURRENCE}";

    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Self->{TicketID} ],
        Limit => 1,
    );
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $Data{ContractQuota} = $Row[0];
        $Data{UsedQuota}     = $Row[1];
    }

    # format and calculate remaining data
    my $ContractQuota  = sprintf '%.1f', $Data{ContractQuota};
    my $UsedQuota      = sprintf '%.1f', $Data{UsedQuota};
    my $AvailableQuota = sprintf '%.1f', $ContractQuota - $UsedQuota;

    # exit if no quota is configured for the customer and this is not desired in config
    if (
        $ContractQuota == '0'
        && $Self->{ConfigObject}->Get('SupportQuota::Preferences::EmptyContractDisplay') == '0'
        )
        { return; }

    my $Template = q~
            <div class="WidgetSimple">
                <div class="Header">
                    <h2>$Text{"Customer Support Quota"} $Text{"$Data{"Recurrence"}"}</h2>
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
            Recurrence => $RecurrenceLabel
        },
    );

    # add information
    ${ $Param{Data} } =~ s{ (<\!--\sdtl:block:CustomerTable\s-->) }{ $HTML $1 }ixms;

    return $Param{Data};
}

1;
