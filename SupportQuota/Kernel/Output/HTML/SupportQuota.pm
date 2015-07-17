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

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::DB
    Kernel::Output::HTML::Layout
    Kernel::System::Web::Request
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    $Self->{TicketID} = $ParamObject->GetParam( Param => 'TicketID' );

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
               AND ta.time_unit IS NOT NULL
        GROUP BY cc.customer_id";

    # additional sql statement matching for the recurrence period
    my $Recurrence = $ConfigObject->Get('SupportQuota::Preferences::Recurrence');
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

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Self->{TicketID} ],
        Limit => 1,
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        # initialize undefined data sources
        if ( defined $Row[0] ) {
            $Data{ContractQuota} = $Row[0];
        } else {
            $Data{ContractQuota} = 0;
        }
        if ( defined $Row[1] ) {
            $Data{UsedQuota}     = $Row[1];
        } else {
            $Data{UsedQuota}     = 0;
        }
    }

    # format and calculate remaining data
    my $ContractQuota  = sprintf '%.1f', $Data{ContractQuota};
    my $UsedQuota      = sprintf '%.1f', $Data{UsedQuota};
    my $AvailableQuota = sprintf '%.1f', $Data{ContractQuota} - $Data{UsedQuota};

    # exit if no quota is configured for the customer and this is not desired in config
    if (
        $ContractQuota == 0
        && $ConfigObject->Get('SupportQuota::Preferences::EmptyContractDisplay') == 0
    )
    { return; }

    my $Template = q~
            <div class="WidgetSimple">
                <div class="Header">
                    <h2>[% Translate("Customer Support Quota") | html %] [% Translate(Data.Recurrence) | html %]</h2>
                </div>
                <div class="Content">
                    <fieldset class="TableLike FixedLabelSmall Narrow">
                        <label>[% Translate("Available") | html %]:</label>
                        <p class="Value">[% Data.Available | html %]</p>
                        <div class="Clear"></div>
                        <label>[% Translate("Used") | html %]:</label>
                        <p class="Value">[% Data.Used | html %]</p>
                        <div class="Clear"></div>
                        <label>[% Translate("Contracted") | html %]:</label>
                        <p class="Value">[% Data.Contracted | html %]</p>
                        <div class="Clear"></div>
                    </fieldset>
                </div>
            </div>
    ~;

    my $HTML = $LayoutObject->Output(
        Template => $Template,
        Data     => {
            Available  => $AvailableQuota,
            Used       => $UsedQuota,
            Contracted => $ContractQuota,
            Recurrence => $RecurrenceLabel
        },
    );

    # add information
    ${ $Param{Data} } =~ s{ (\[\% \s+ RenderBlockStart\("CustomerTable"\) \s+ \%\]) }{ $HTML $1 }ixms;

    return $Param{Data};
}

1;
