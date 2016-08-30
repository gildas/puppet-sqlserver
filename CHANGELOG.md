##2016-08-30 - Version 0.2.7
###Summary

 This release contains puppet module dependency fixes

##2016-05-18 - Version 0.2.6
###Summary

 This release contains bug fixes 

###Features

###Bugfixes
- Fixed all warnings/errors from Puppet Lint

##2016-05-18 - Version 0.2.5
###Summary

 This release contains bug fixes 

###Features

###Bugfixes
- Better metadata descriptions for the forge.

##2016-05-18 - Version 0.2.4
###Summary

 This release contains bug fixes and allows to prevent the manifest from updating the firewall.

###Features
- New option to not update the firewall. (By default: the firewall is updated)

###Bugfixes
- Typos


##2014-12-19 - Version 0.2.1
###Summary

 This release brings UNC paths to the source option for SQL Server Express install.

###Features
- The source option supports UNC paths.
- If the source option is a UNC path, source_user and source_password will be used to authenticate.

###Bugfixes


##2014-12-19 - Version 0.2.0
###Summary

This release allows to use the source option with the SQL Server Express install.

This allows to avoid downloading the install from the Internet and use a local folder.

###Features
- If the source option is not empty, it should point to a folder where the install can be found.

###Bugfixes



##2014-12-19 - Version 0.1.0
###Summary

This is the initial release.

Only the SQL Server Express install really works.

More work later will need to happen for SQL Server Standard and Enterprise.
