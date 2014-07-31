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
  $ensure = installed,
  $sa_password,
  $edition,
  $license_type,
  $license = undef
)
{
  if ($operatingsystem != 'Windows')
  {
    err("This module works on Windows only!")
    fail("Unsupported OS")
  }
  validate_re($edition, ['^(?i)(express|standard|enterprise)$'])
  validate_re($license_type, ['^(?i)(evaluation|MSDN|Volume|Retail)$'])

  case $ensure
  {
    installed:
    {
      notice("Installing Microsoft SQL Server #{$edition}")
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
          $credentials  = pscredential('AddToDomainAPAC', 'Interactive!')
          $creds_option = "-Credential ${credentials}"
          $isopath      = '\\tyofiles\AppShare\Microsoft\MSDN\SQLServer\2012\en_sql_server_2012_standard_edition_with_sp1_x64_dvd_1228198.iso'
          exec {'sqlserver-install':
            command  => "New-PSDrive -Name Z -Root \\\\tyofiles\\AppShare ${creds_option} ; Mount-DiskImage -ImagePath '${isopath}' ; Z:\\Setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SQL,AS,RS,IS,Tools /INSTANCENAME=\"MSSQLSERVER\" /SECURITYMODE=SQL /SAPWD=\"${sa_password}\" /TCPENABLED=1",
            creates  => "C:/Program Files/Microsoft SQL Server/MSSQL11.MSSQLSERVER/MSSQL/binn/sqlservr.exe",
            provider => powershell
          }
          #onlyif   => "\$drive = ((Get-DiskImage -ImagePath '${isopath}') | Get-Volume);;if((test-path '${isopath}') -and (\$drive -eq \$null)){}else{exit 1}",
          
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
  }


  #TODO: Open the firewall for the TCP connection to SQL Server
}
