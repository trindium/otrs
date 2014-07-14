# OTRS Support Quota Add-on

This OTRS Add-on module provides an easy to use interface to control customer contracted work unit quotas.

By entering a quota to each Customer Company in your OTRS system and taking care to set the proper 'CustomerCompanyID' on your tickets (easy if you use PostMaster Filters), this add-on is able to get the total work unit quota available to a particular customer, how many work units were used in the current period (current month) and how many work units are available to that customer in the same period. If the available quota is negative, there will be extra bucks in the end of the month.

The above information then appears in a widget under agent TicketZoom interface so your agents can
easily decide what to do based on your process on how to charge (or not) for beyond quota customers.

The screenshot bellow shows how the Support Quota works in the agent GUI:

![Support Quota Add-on in action](https://raw.githubusercontent.com/denydias/otrs/master/SupportQuota/SupporQuota.png)

## Instalation

Right in this repo, there is an [OTRS Package](https://github.com/denydias/otrs/tree/master/packages) (SupportQuota-0.0.1.opm) ready to install. Download it, open your OTRS and go to Admin > Package Manager. Then choose the downloaded package under 'Install Package' button.

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

* ~~Properly implement the OTRS template mechanism.~~ (done by [reneeb](https://github.com/reneeb) in 6c35790b230104b2124fb2b8a61f63feba4b56bf)
* ~~Add localization support (Brazilian Portuguese is hardcoded). If you need the strings that need translation, open an issue and I'll be more than pleased to provide them.~~ (done by [reneeb](https://github.com/reneeb) in 6c35790b230104b2124fb2b8a61f63feba4b56bf)
* Add the widget to AgentCustomerInformationCenter.
* Add visual cues to over quota customers.
* Provide notification methods to automatically reply to customers working beyond the contracted quota upon new tickets.

This is just to name a few. I'm open to more.

## How To Use It

There are many use cases (aka support process) where this add-on could fit. I can't imagine it all. As such, I'll describe how one can use it under a use case I know better: myself.

1. Each one of your customers (**their companies, not their people**) should have an entry under Admin > Customer (`AdminCustomerCompany`).

2. For each customer company, set the quota for that customer. This is an integer from 0 to 65535 which corresponds to the customer contract (i.e. 8h, 16h, 24h, 720h). Leave it blank or 0 (zero) if you don't know or the customer has an unlimited service.

3. (OPTIONAL, but recommended) Set a Postmaster Filter for any of your customer companies like this:

    ```
    From: .*@customerdomain.com
    X-OTRS-CustomerNo: customername
    ```

    This ensures that any new ticket get the proper 'CustomerCompanyID' properly set when a new support email arrive.

    **Caveat:** If an agent open a ticket, the 'CustomerCompanyID' should be set manually. The same applies for phone tickets if.

4. (OPTIONAL, but recommended) Go to Admin > SysConfig > Ticket > Frontend::Agent and set:

   ```
   Ticket::Frontend::TimeUnits: (work units)
   Ticket::Frontend::NeedAccountedTime: yes
   ```

   This ensures that every agent action upon a ticket needs to be time accounted.

5. Now that you are all set on OTRS side, every time an agent get into a new ticket to work on it, the time accounted to a particular customer is shown in the little panel at right. If the customer have no quota available, the agent can request a written authorization to charge the above quota service or just deny further developments.

### Usage Notes

The Support Quota widget in TicketZoom shows the quota for the current month only and just for the particular 'CustomerCompanyID' set to the ticket. If you need to get a report by the end of the month to charge the extra work units, you must go to Admin > SQL Box and run a query like:

```sql
SELECT t.tn "Ticket #",
   t.title Title,
   t.customer_id Customer,
   SUM(ta.time_unit) "Work Units",
   DATE_FORMAT(t.create_time, "%h:%m:%s %d/%m/%Y") Created
FROM ticket t
   LEFT JOIN time_accounting ta ON ta.ticket_id=t.id
WHERE
   ta.time_unit is not null
   AND t.customer_id="CustomerCompanyID"
   AND year(t.create_time) = year(now())
   AND month(t.create_time) = month(now())
GROUP BY t.tn
ORDER BY t.create_time
```

Don't forget to change `CustomerCompanyID` above to the one the matches your customer in OTRS.

From within SQL Box you can save a CSV file so you can share straight with the customer.

## References

To write this OTRS add-on, my first one, I counted on many references. Bellow I list the main ones:

1. [OTRS 3.3 - Developer Manual](http://otrs.github.io/doc/manual/developer/3.3/en/html/index.html)

2. From OtterHub e.V. User Forums:

    [How to add a field in the company details window](http://forums.otterhub.org/viewtopic.php?f=53&t=18627)

    [Problem with adding new fields to customer_company](http://forums.otterhub.org/viewtopic.php?f=62&t=25080)

    [Custom Field on "Add Customer" page](http://forums.otterhub.org/viewtopic.php?f=53&t=11508)

    [Add "next ticket" button in AgentTicketZoom](http://forums.otterhub.org/viewtopic.php?f=64&t=16586)

3. [Zuny Repo](https://github.com/znuny)

4. [OTRS Package that allows SMS sending](https://github.com/richieri/SmsEvent)

I'd like to acknowledge and thanks all the above list.

## License

Copyright (C) 2001-2014 Deny Dias.

This software comes with ABSOLUTELY NO WARRANTY. For details, see the enclosed file COPYING for license information (AGPL). If you did not receive this file, see http://www.gnu.org/licenses/agpl.txt.