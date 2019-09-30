# PSU

## Project Notes

Author:             Chris Dabel
Create Date:        9/20/2019


## How to Push to Production:
Before publishing any changes, log onto IHR ETL server (APVEP32146) as any user having Github Enterprise access. 
The code on the server is mapped via Git to the Github Enterprise repository called "sec-dev/data-eng", 
(The full URL is _https://github.optum.com/sec-dev/data-eng.git_ ). The code files on the server are under 
`C:\projects\data-eng\ihr\psu`


### Steps:
1. `cd to "C:\projects\data-eng"` and ensure the remote repo is set to *https://github.optum.com/sec-dev/data-eng.git*
   You can run `git remote --v` from command line to verify this.
2. "`git pull`" to get the latest changes.
   Once any new changes are pulled/merged to this local repository, then nothing further needs to be done. The SQL Server Agent job will use these files automatically.

Note that if you are logged into the IHR ETL Server as the service account user (as of 09/30/2019, this user is **CEXP_LOAD**), then instead of the steps above, you may run the following command to pull latest changes:
`cd C:\projects\data-eng && runas /profile /env /user:MS\<Your Github Enterprise LDAP User Name> "git pull"`

Then enter your LDAP password to execute the git pull command).
