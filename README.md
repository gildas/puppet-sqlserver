sqlserver
=========

## Description

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
  license      => ''
}
```

Valid editions are: express, standard, enterprise.
Valid license types are: evaluation, MSDN, Volume, Retail.

Notes:
- Express edition ignores the license type and the license,
- MSDN, Volume, and Retail license types require a license,

License
-------


Contact
-------


Support
-------

Please log tickets and issues at our [Projects site](http://projects.example.com)
