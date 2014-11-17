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
  $edition          = 'express',
  $license_type     = 'evaluation',
  $license          = undef,
  $language         = 'en',
  $features         = [ 'SQL' ],
  $sa_password      = undef,
  $instance_name    = 'MSSQLSERVER',
  $instance_dir     = undef,
  $database_dir     = undef,
  $database_log_dir = undef,
  $backup_dir       = undef,
  $collation        = undef,
  $administrators   = undef,
  $show_progress    = false,
  $force_english    = false,
  $source           = undef,
)
{
  # We do not want to copy Unix modes to Windows, it tends to render files unaccessible
  File { source_permissions => ignore }

  include stdlib

  if ($operatingsystem != 'Windows')
  {
    err("This module works on Windows only!")
    fail("Unsupported OS")
  }
  validate_re($language, ['^(?i)(de|en|es|fr|ja|ko|pt|ru|zh-CHS|zh-CHT)'])
  validate_array($features)
  if (empty($features)) { fail("Unable to continue processing SQL Server since no features were selected") }
  validate_re($edition, ['^(?i)(express|standard|enterprise)$'])
  unless ($edition =~ /^(?i:express)$/)
  {
    validate_re($license_type, ['^(?i)(evaluation|MSDN|Volume|Retail)$'])
    unless ($license_type =~ /^(?i:evaluation)$/)
    {
      validate_string($license)
    }
  }
  $cache_dir = hiera('core::cache_dir', 'c:/windows/temp')
  if (!defined(File["${cache_dir}"]))
  {
    file {"${cache_dir}":
      ensure   => directory,
      provider => windows,
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
          case $language
          {
            /^(?i:de)$/: # German
            {
               $install_language = 'DEU'
               $source_path      = '9/9/B/99BB8518-C818-42EF-A9AA-1A06E4AC1DC6'
            }
            /^(?i:en)$/: # English
            {
               $install_language = 'ENU'
               $source_path      = 'E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB'
            }
            /^(?i:es)$/: # Spanish
            {
               $install_language = 'ESN'
               $source_path      = 'C/A/3/CA36A732-59EC-4CEA-971A-0269B992C82A'
            }
            /^(?i:fr)$/: # French
            {
               $install_language = 'FRA'
               $source_path      = 'B/8/5/B856F507-1B8A-4A5F-BCBF-ABEE9C70CA84'
            }
            /^(?i:ja)$/: # Japanese
            { 
               $install_language = 'JPN'
               $source_path      = '1/C/9/1C95EAB0-F98C-4039-8402-4D7A84D9B290'
            }
            /^(?i:ko)$/: # Korean
            {
               $install_language = 'KOR'
               $source_path      = '5/9/9/5995FEA5-97E8-4A01-BDFB-78E27F4873AC'
            }
            /^(?i:pt)$/: # Portuguese
            {
               $install_language = 'PTB'
               $source_path      = '0/1/5/015567C0-E851-4AC6-964F-9BBA9B31D6BC'
            }
            /^(?i:ru)$/: # Russian
            {
               $install_language = 'RUS'
               $source_path      = '4/E/3/4E38FD5A-8859-446F-8C58-9FC70FE82BB1'
            }
            /^(?i:zh-CHS)$/: # Simplified Chinese
            {
               $install_language = 'CHS'
               $source_path      = 'C/5/A/C5ACFA2B-9DB0-44F3-BD2F-BBC567987C82'
            }
            /^(?i:zh-CHT)$/: # Traditional Chinese
            {
               $install_language = 'CHT'
               $source_path      = '5/5/E/55EA61C3-4CED-455F-B09F-67608D27BEB6'
            }
            default:
            {
              warn("Invalid installation language \"${language}\", defaulting to English")
              $install_language = 'ENU'
            }
          }

          if (member(downcase($features), 'analysis services') or member(downcase($features), 'integration services') or member(downcase($features), 'reporting services'))
          {
            $feature_AS      = member(downcase($features), 'analysis services')    ? { true => ',AS',    default => '' }
            $feature_AS      = member(downcase($features), 'integration services') ? { true => ',IS'   , default => '' }
            $feature_AS      = member(downcase($features), 'reporting services')   ? { true => ',RS',    default => '' }
            $feature_tools   = member(downcase($features), 'tools')                ? { true => ',Tools', default => '' }
            $features_option = "/FEATURES=SQL${feature_AS}${feature_IS}${feature_RS}$(feature_tools}"
            $product_path    = 'ExpressAdv%2064BIT'
            $sql_install     = "SQLEXPRADV_x64_${install_language}.exe"
          }
          elsif (member(downcase($features), 'tools'))
          {
            $features_option = '/FEATURES=SQL,Tools'
            $product_path    = 'ExpressAndTools%2064BIT'
            $sql_install     = "SQLEXPRWT_x64_${install_language}.exe"
          }
          else
          {
            $features_option = '/FEATURES=SQL'
            $product_path    = 'Express%2064BIT'
            $sql_install     = "SQLEXPR_x64_${install_language}.exe"
          }
          $sql_source            = "http://care.dlservice.microsoft.com/dl/download/${source_path}/${product_path}/${sql_install}"
          $silent_option         = $show_progress             ? { true => "/QS", default => "/Q" }
          $enu_option            = $force_english             ? { true => "/ENU", default => '' }
          $instance_name_option  = empty($instance_name)      ? { true => "/INSTANCENAME=\"MSSQLSERVER\"", default => "/INSTANCENAME=\"${instance_name}\"" }
          $instance_dir_option   = empty($instance_dir)       ? { true => '', default => "/INSTANCEDIR=\"${instance_dir}\"" }
          $security_option       = empty($sa_password)        ? { true => '', default => "/SECURITYMODE=SQL /SAPWD=\"${sa_password}\"" }
          $database_dir_option   = empty($database_dir)       ? { true => '', default => "/SQLUSERDBDIR=\"${database_dir}\"" }
          $log_dir_option        = empty($database_log_dir) ? { true => '', default => "/SQLUSERDBLOGDIR=\"${database_log_dir}\"" }
          $backup_dir_option     = empty($backup_dir)         ? { true => '', default => "/SQLBACKUPDIR=\"${backup_dir}\"" }
          $collation_option      = empty($collation)          ? { true => '', default => "/SQLCOLLATION=\"${collation}\"" }
          $administrators_option = empty($administrators)     ? { true => "/SQLSYSADMINACCOUNTS=\"${::hostname}\\Administrator\"", default => "/SQLSYSADMINACCOUNTS=\"${administrators}\"" }
          $options               = "${silent_option} ${features_option} ${enu_option} ${instance_name_option} ${instance_dir_option} ${security_option} ${database_dir_option} ${log_dir_option} ${backup_dir_option} ${collation_option}"

          debug("Downloading ${sql_source} into ${cache_dir}/${sql_install}")
          exec {"sqlserver-install-download":
            command  => "((new-object net.webclient).DownloadFile('${sql_source}','${cache_dir}/${sql_install}'))",
            creates  => "${cache_dir}/${sql_install}",
            provider => powershell,
            require  => [
                          File["${cache_dir}"],
                        ]
          }

          debug("SQL Install Options: ${options}")
          exec {"sqlserver-install-run":
            command  => "${cache_dir}/${sql_install} /IACCEPTSQLSERVERLICENSETERMS /ACTION=install ${options} /TCPENABLED=1",
            creates  => "C:/Program Files/Microsoft SQL Server/MSSQL12.MSSQLSERVER/MSSQL/binn/sqlservr.exe",
            cwd      => "${cache_dir}",
            provider => windows,
            timeout  => 900,
            require  => [
                          File["${cache_dir}"],
                          Exec['sqlserver-install-download'],
                        ]
          }

        }
        'standard':
        {
          # See: http://msdn.microsoft.com/en-us/library/ms144259.aspx#Install
          validate_string($source)

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
          # SQL Server 2014 Express
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/Express%2064BIT/SQLEXPR_x64_ENU.exe'

          # SQL Server 2014 Express with tools
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/ExpressAndTools%2064BIT/SQLEXPRWT_x64_ENU.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/B/8/5/B856F507-1B8A-4A5F-BCBF-ABEE9C70CA84/ExpressAndTools%2064BIT/SQLEXPRWT_x64_FRA.exe'

          # SQL Server 2014 Management Studio (64b)
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/MgmtStudio%2064BIT/SQLManagementStudio_x64_ENU.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/1/C/9/1C95EAB0-F98C-4039-8402-4D7A84D9B290/MgmtStudio%2064BIT/SQLManagementStudio_x64_JPN.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/B/8/5/B856F507-1B8A-4A5F-BCBF-ABEE9C70CA84/MgmtStudio%2064BIT/SQLManagementStudio_x64_FRA.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/9/9/B/99BB8518-C818-42EF-A9AA-1A06E4AC1DC6/MgmtStudio%2064BIT/SQLManagementStudio_x64_DEU.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/C/A/3/CA36A732-59EC-4CEA-971A-0269B992C82A/MgmtStudio%2064BIT/SQLManagementStudio_x64_ESN.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/C/5/A/C5ACFA2B-9DB0-44F3-BD2F-BBC567987C82/MgmtStudio%2064BIT/SQLManagementStudio_x64_CHS.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/5/5/E/55EA61C3-4CED-455F-B09F-67608D27BEB6/MgmtStudio%2064BIT/SQLManagementStudio_x64_CHT.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/5/9/9/5995FEA5-97E8-4A01-BDFB-78E27F4873AC/MgmtStudio%2064BIT/SQLManagementStudio_x64_KOR.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/0/1/5/015567C0-E851-4AC6-964F-9BBA9B31D6BC/MgmtStudio%2064BIT/SQLManagementStudio_x64_PTB.exe'
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/4/E/3/4E38FD5A-8859-446F-8C58-9FC70FE82BB1/MgmtStudio%2064BIT/SQLManagementStudio_x64_RUS.exe'

          # SQL Server 2014 with Advanced Services
          #$sql_source  = 'http://care.dlservice.microsoft.com/dl/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/ExpressAdv%2064BIT/SQLEXPRADV_x64_ENU.exe'

          # SQL Express Server 2012
          #$sql_source  = 'http://download.microsoft.com/download/8/D/D/8DD7BDBA-CEF7-4D8E-8C16-D9F69527F909/ENU/x64/SQLEXPR_x64_ENU.exe'
