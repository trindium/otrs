# OTRS Support Quota Add-on

This OTRS Add-on module provides an easy to use interface to control customer contracted work unit quotas.

By entering a quota to each Customer Company in your OTRS system and taking care to set the proper CustomerCompanyID on your tickets (easy if you use PostMaster Filters), this add-on is able to get the total work unit quota available to a particular customer, how many work units were used in the current period (current month) and how many work units are available to that customer in the same period. If the available quota is negative, there will be extra bucks in the end of the month.

The above information then appears in a widget under agent TicketZoom interface so your agents can
easily decide what to do based on your process on how to charge (or not) for beyond quota customers.

The screenshot bellow shows how the Support Quota works in the agent GUI:

![Support Quota Add-on in action](https://raw.githubusercontent.com/denydias/otrs/master/SupportQuota/SupporQuota.png)

## Instalation

Right in this repo, there is an [OTRS Package](https://github.com/denydias/otrs/tree/master/packages) (SupportQuota-0.0.1.opm) ready to install. Download it, open your OTRS and go to 'Admin > Package Management'. Then choose the downloaded package under 'Install Package' button.

The package installation takes care of the only database change required. For the matter of the record, it is:

```sql
ALTER TABLE customer_company ADD quota SMALLINT;
```

After installation is done, you have to **manually** change your `Kernel/Config.pm` file as per the example bellow:

```perl
    # Custom CustomerCompany for Support Quota Add-on     #
    # --------------------------------------------------- #

    $Self->{CustomerCompany} = {
        Name   => 'Database Backend',
        Module => 'Kernel::System::CustomerCompany::DB',
        Params => {
            Table => 'customer_company',
            CaseSensitive => 0,
        },

        CustomerCompanyKey             => 'customer_id',
        CustomerCompanyValid           => 'valid_id',
        CustomerCompanyListFields      => [ 'customer_id', 'name' ],
        CustomerCompanySearchFields    => ['customer_id', 'name'],
        CustomerCompanySearchPrefix    => '',
        CustomerCompanySearchSuffix    => '*',
        CustomerCompanySearchListLimit => 250,
        CacheTTL                       => 60 * 60 * 24, # use 0 to turn off cache

        Map => [
            [ 'CustomerID',             'CustomerID', 'customer_id', 0, 1, 'var', '', 0 ],
            [ 'CustomerCompanyName',    'Customer',   'name',        1, 1, 'var', '', 0 ],
            [ 'CustomerCompanyStreet',  'Street',     'street',      1, 0, 'var', '', 0 ],
            [ 'CustomerCompanyZIP',     'Zip',        'zip',         1, 0, 'var', '', 0 ],
            [ 'CustomerCompanyCity',    'City',       'city',        1, 0, 'var', '', 0 ],
            [ 'CustomerCompanyCountry', 'Country',    'country',     1, 0, 'var', '', 0 ],
            [ 'CustomerCompanyURL',     'URL',        'url',         1, 0, 'var', '$Data{"CustomerCompanyURL"}', 0 ],
            [ 'CustomerCompanyComment', 'Comment',    'comments',    1, 0, 'var', '', 0 ],
            [ 'CustomerCompanyQuota',   'Quota',      'quota',       1, 0, 'int', '', 0 ],
            [ 'ValidID',                'Valid',      'valid_id',    0, 1, 'int', '', 0 ],
        ],
    };
```

Note the new `CustomerCompanyQuota` field in the map.

And that's it. Enjoy your extra $$$.

## To Do

I'm not a Perl developer. I did the best I could to write this add-on with the core functionality in place. So, there are lots to improve in it for which pull requests are more than welcome.

As an start point, I'll give you the following items as a 'To Do List':

* Properly implement the OTRS template mechanism.
* Add localization support (Brazilian Portuguese is hardcoded). If you need the strings that need translation, open an issue and I'll be more than pleased to provide them.
* Add the widget to AgentCustomerInformationCenter.
* Add visual cues to over quota customers.
* Provide notification methods to automatically reply to customers working beyond the contracted quota upon new tickets.

This is just to name a few. I'm open to more.

## License

Copyright (C) 2001-2014 Deny Dias.

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file COPYING for license information (AGPL). If you did not receive this file, see http://www.gnu.org/licenses/agpl.txt.