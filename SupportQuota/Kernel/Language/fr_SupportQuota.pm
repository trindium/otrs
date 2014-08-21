# --
# Kernel/Language/fr_SupportQuota.pm
# Copyright (C) 2014 denydias
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --


package Kernel::Language::fr_SupportQuota;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    $Lang->{'Customer Support Quota'} = 'Crédit temps du client';
    $Lang->{'Available'}              = 'Disponible';
    $Lang->{'Used'}                   = 'Consommé';
    $Lang->{'Contracted'}             = 'Contracté';
    $Lang->{'(Monthly)'}              = '(Mensuel)';
    $Lang->{'(Yearly)'}               = '(Annuel)';
}

1;
