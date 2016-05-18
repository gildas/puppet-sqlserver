sqlserver
=========

Description
-----------

Microsoft SQL Server package installer for PuppetLabs.

Overview
--------

The SQL Server module provides manifest classes to install various editions of Microsoft SQL Server 2014.

Setup
-----

Simply load the module via [Puppet Forge](https://forge.puppetlabs/gildas/sqlserver):

```sh
puppet module install gildas-sqlserver
```

Usage
-----

To install SQL Server, include the maim class in your node definition:

```Puppet
include sqlserver
```

This will download SQL Server Express in English and install the features SQL and create the instance 'MSSQLSERVER'.

You can install other editions via:

```Puppet
class {'sqlserver':
  edition      => 'standard',
  license_type => 'Retail'
  license      => 'H0Y11-FA8KE-L1CEN-SE890-AHAH3',
}
```

Valid editions are: express, standard, enterprise.
Valid license types are: evaluation, MSDN, Volume, Retail.

> Express edition ignores the license type and the license,

> MSDN, Volume, and Retail license types require a license

See the next paragraph for a full list of options.

### Options
The class supports the following options (alphabetical order):

- administrators
  This option contains the DOMAIN\USER, DOMAIN\GROUP used for the Administrators of this SQL Server instance.
  + Possible Values: *undef*, Windows NT account identifier.
  + Default value: *undef*
- backup_dir
  This option specifies the directory for backup files.
  If *undef*, the backup folder will be: *InstallSQLDataDir*/*SQLInstanceID*/MSSQL/Backup
  + Possible Values: *undef*, folder
  + Default value: *undef*
- collation
  This option specifies the collation for this SQL Server instance
  + Possible Values: *undef*, collation identifier
  + Default value: *undef*
- database_dir
  This option tells where the database data files should be stored.
  If not provided, this will be: *InstallSQLDataDir*/*SQLInstanceID*/MSSQL/Data
  + Possible Values: *undef*, folder
  + Default value: *undef*
- database_log_dir
  This option tells where the database data files should be stored.
  If not provided, this will be: *InstallSQLDataDir*/*SQLInstanceID*/MSSQL/Data
  + Possible Values: *undef*, folder
  + Default value: *undef*
- edition
  This option tells which SQL Server Edition will be installed.
  + Possible Values: Express, Standard, Enterprise.
  + Default value: Express
- ensure
  This option tells if the module should install SQL Server or uninstall it.
  + Possible Values: installed, uninstalled.
  + Default value: installed
- features
  This is an array of features to install. This option is case-independent.
  + Possible values: SQL, Analysis Services, Integration Services, Reporting Services, Tools.
  + Default value: SQL
- force_english
  When true, installs SQL Server in English on a localized OS with a localized install package.
  + Possible Values: true, false
  + Default value: false
- instance_dir
  This option tells where instance-specific components should be installed.
  + Possible Values: undef, folder path.
  + Default value: *undef*
- instance_name
  This option contains the name of the instance to install.
  + Possible Values: *string*
  + Default value: MSSQLSERVER
- language
  This is the language to install software with. This option is case-independent.
  + Possible values: de, en, es, fr, ja, ko, pt, ru, zh-CHS, zh-CHT.
  + Default value: en.
- license
  This options contains the license key from Microsoft.
  The value is ignored for SQL Express and for the Evaluation edition.
  + Possible Values: *undef*, *string*
  + Default value: *undef*
- license_type
  This option contains the type of license to use. This option is ignored when installing SQL Express.
  + Possible Values: Evaluation, MSDN, Volume, Retail.
  + Default value: Evaluation
- manage_firewall
  If **true**, the manifest will create firewall rules to accept incoming SQL traffic.
  + Possible Values: true, false.
  + Default value: **true**
- sa_password
  If provided, SQL Server will be installed with Windows and SQL authentication. If not, Windows authentication only will be used.
  + Possible Values: *undef*, *string*
  + Default value: *undef*
- show_progress
  This option controls if a progress bar should be displayed while installing SQL Server
  + Possible Values: true, false.
  + Default value: **false**
- source
  This option specifies the path of the ISO containing the SQL Server installation.

  When installing SQL Express, if this option is used, it should point to the path where the installation is stored.

  Only local and UNC sources are supported at the moment.
  + Possible Values: *undef*, folder
  + Default value: *undef*
- source_user
  This option specifies the user to authenticate with the source.
  + Possible Values: *undef*, string
  + Default value: *undef*
- source_password
  This option specifies the password to authenticate with the source.
  + Possible Values: *undef*, string
  + Default value: *undef*

Notes and Caveats:
> By default only SQL is installed! Do not forget to add the feature 'Tools' to get Management Studio and other SQL tools.
