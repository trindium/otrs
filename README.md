# OTRS Modules Sources and Packages

This is a collection of OTRS modules source code and compiled packages. All the content here is developed and maintained by me.

For more information, please read the README.md in each module directory.

## OTRS Module Development Commands

The following is a list of handful commands for OTRS module development, debugging and package building.

Run as root in the development machine only. **DO NOT RUN THE COMMANDS BELLOW IN A PRODUCTION SYSTEM.**

### Module Install

```
su otrs -c "/opt/otrs/dev/module-tools/link.pl /opt/otrs/dev/SupportQuota /opt/otrs"
```

Then run `AdminSysConfig` in the browser.

### Module Uninstall

```
/opt/otrs/dev/module-tools/remove_links.pl /opt/otrs
```

### Module Debug

```
/opt/otrs/bin/otrs.RebuildConfig.pl;/opt/otrs/bin/otrs.DeleteCache.pl
sudo perl /opt/otrs/bin/otrs.SetPermissions.pl --otrs-user=otrs --web-group=www-data /opt/otrs
sudo service apache2 restart
sudo tail -f /var/log/apache2/error.log
```

### Package/Repository Building

```
/opt/otrs/bin/otrs.PackageManager.pl -a build -p /opt/otrs/dev/SupportQuota/SupportQuota.sopm
rm /opt/otrs/dev/packages/SupportQuota-*.opm
mv /tmp/SupportQuota-*.opm /opt/otrs/dev/packages/
/opt/otrs/bin/otrs.PackageManager.pl -a index -d /opt/otrs/dev/packages > /opt/otrs/dev/packages/otrs.xml
```