# --
# Kernel/Language/de_SupportQuota.pm
# Copyright (C) 2014 denydias
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --


package Kernel::Language::de_SupportQuota;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    $Lang->{'Available'}              = 'Verfügbar';
    $Lang->{'Customer Support Quota'} = 'Quota Kundensupport';
    $Lang->{'Used'}                   = 'Verbraucht';
    $Lang->{'Contracted'}             = 'Vertrag';
    $Lang->{'(Monthly)'}              = '(Monatlich)';
    $Lang->{'(Yearly)'}               = '(Jährlich)';
}

1;
