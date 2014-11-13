# == Class: sqlserver
#
# Full description of class sqlserver here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { sqlserver:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class sqlserver(
  $ensure           = installed,
  $edition          = 'edition',
  $license_type     = 'evaluation',
  $license          = undef,
  $language         = 'en',
  $features         = [ 'SQL' ],
  $instance_name    = 'MSSQLSERVER',
  $instance_dir     = undef,
  $sa_password      = undef,
  $database_dir     = undef,
  $database_log_dir = undef,
  $backup_dir       = undef,
  $collation        = undef,
  $administrators   = undef,
  $source           = undef,
)
{
  if ($operatingsystem != 'Windows')
  {
    err("This module works on Windows only!")
    fail("Unsupported OS")
  }
  validate_re($edition, ['^(?i)(express|standard|enterprise)$'])
  unless ($edition =~ /^(?i:express)$/)
  {
    validate_re($license_type, ['^(?i)(evaluation|MSDN|Volume|Retail)$'])
    unless ($license_type =~ /^(?i:evaluation)$/)
    {
      validate_string($license)
    }
  }


  case $ensure
  {
    installed:
    {
      notice("Installing Microsoft SQL Server ${edition}")
      case $edition
      {
        'express':
        {
          $sql_source  = 'http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPR_x64_ENU.exe'
          $sql_install = url_parse($sql_source, 'filename')

          exec {"sqlserver-install-download":
            command  => "((new-object net.webclient).DownloadFile('${sql_source}','${core::cache_dir}/${sql_install}'))",
            creates  => "${core::cache_dir}/${sql_install}",
            provider => powershell,
            require  => [
                          File["${core::cache_dir}"],
                        ]
          }

          exec {"sqlserver-install-run":
            command  => "${core::cache_dir}/${sql_install} /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SQL,AS,RS,IS,Tools /INSTANCENAME=\"MSSQLSERVER\" /SECURITYMODE=SQL /SAPWD=\"${sa_password}\" /TCPENABLED=1",
            creates  => "C:/Program Files/Microsoft SQL Server/MSSQL11.MSSQLSERVER/MSSQL/binn/sqlservr.exe",
            cwd      => "${core::cache_dir}",
            provider => windows,
            timeout  => 900,
            require  => [
                          File["${core::cache_dir}"],
                          Exec['sqlserver-install-download'],
                        ]
          }

        }
        'standard':
        {
          # See: http://msdn.microsoft.com/en-us/library/ms144259.aspx#Install
          validate_array($features)
          validate_string($instance)
          validate_string($source)
          if (empty($features)) { fail("Unable to install SQL Server since no features were selected") }

          # TODO: implement other features
          # With Analysis Services:
          # setup.exe ... /FEATURES=...,AS,... /ASSYSADMINACCOUNTS="LAB\Administrator"
          # With Integration Services:
          # setup.exe ... /FEATURES=...,IS,...
          # With Reporting Services:
          # setup.exe ... /FEATURES=...,RS,...
          $features_option = '/FEATURES=SQL'

          $instance_name_option  = empty($instance_name)      ? { true => "/INSTANCENAME=\"MSSQLSERVER\"", default => "/INSTANCENAME=\"${instance_name}\"" }
          $instance_dir_option   = empty($instance_dir)       ? { true => '', default => "/INSTANCEDIR=\"${instance_dir}\"" }
          $license_option        = empty($license)            ? { true => '', default => "/PID=\"${license}\"" }
          $security_option       = empty($sa_password)        ? { true => '', default => "/SECURITYMODE=SQL /SAPWD=\"${sa_password}\"" }
          $database_dir_option   = empty($database_dir)       ? { true => '', default => "/SQLUSERDBDIR=\"${database_dir}\"" }
          $database_log_dir_option = empty($database_log_dir) ? { true => '', default => "/SQLUSERDBLOGDIR=\"${database_log_dir}\"" }
          $backup_dir_option     = empty($backup_dir)         ? { true => '', default => "/SQLBACKUPDIR=\"${backup_dir}\"" }
          $collation_option      = empty($collation)          ? { true => '', default => "/SQLCOLLATION=\"${collation}\"" }
          $administrators_option = empty($administrators)     ? { true => "/SQLSYSADMINACCOUNTS=\"${::hostname}\\Administrator\"", default => "/SQLSYSADMINACCOUNTS=\"${administrators}\"" }

          $dir_option = "${instance_dir_option} ${database_dir_option} ${database_log_dir_option} ${backup_dir_option}"

          case $source
          {
            /^smb:\/\//:
            {
              fail("Not implemented yet! (smb://)")
            }
            /^\\\\.*/:
            {
              $credentials  = pscredential(hiera('sqlserver::source::user'), hiera('sqlserver::source::password'))
              $creds_option = "-Credential ${credentials}"
              $mount_share  = "New-PSDrive -Name Z \"${source}\" -PSProvider FileSystem ${mount_creds_options}"
              $mount_iso    = "Mount-DiskImage -ImagePath \"${source}\""
              $install      = "${mount_share} ; ${mount_iso} ; Z:\\Setup.exe"
            }
            default: { fail("Unsupported source \"${source}\"") }
          }

          exec {'sqlserver-install':
            command  => "${install} /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install ${features_option} ${instance_name_option} ${security_option} ${administrators_option} ${dir_option} ${collation_option} /TCPENABLED=1 ${license_option}",
            creates  => "C:/Program Files/Microsoft SQL Server/MSSQL11.MSSQLSERVER/MSSQL/binn/sqlservr.exe",
            timeout  => 900,
            provider => powershell
          }

          firewall::rule { 'SQLServer':
            rule        => 'SQLServer-Instance-In-TCP',
            ensure      => enabled,
            create      => true,
            display     => 'SQLServer Instance (TCP-In)',
            description => 'Inbound Rule to access the SQLServer instance [TCP 1433]',
            action      => 'Allow',
            direction   => 'Inbound',
            protocol    => 'TCP',
            local_port  => 1433,
            require     => Exec['sqlserver-install'],
          }
        }
        'enterprise':
        {
        }
      }
    }
    uninstalled:
    {
      notice('Uninstalling Microsoft SQL Server')
    }
    default:
    {
      fail("Unsupported ensure \"${ensure}\"")
    }
  }


  #TODO: Open the firewall for the TCP connection to SQL Server
}
