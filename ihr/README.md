# PSU - Persistent Super Users

## Project Notes

Author:             Chris Dabel

Create Date:        9/20/2019


## How to Push to Production:
Before publishing any changes, log onto IHR ETL server (APVEP32146) as any user having Github Enterprise access. 
The code on the server is mapped via Git to the Github Enterprise repository called **sec-dev/data-eng**, 
(The full URL is _https://github.optum.com/sec-dev/data-eng.git_ ). The code files on the server are under `C:\projects\data-eng\ihr\psu`.


### Steps:
1. `cd to "C:\projects\data-eng"` and ensure the remote repo is set to *https://github.optum.com/sec-dev/data-eng.git*.
   You can run `git remote --v` from command line to verify this.
2. "`git pull`" to get the latest changes.
   Once any new changes are pulled/merged to this local repository, then nothing further needs to be done. The SQL Server Agent job will use these files automatically.

Note that if you are logged into the IHR ETL Server as the service account user (as of 09/30/2019, this user is **CEXP_LOAD**), then instead of the steps above, run the following command to pull latest changes:
`cd C:\projects\data-eng && runas /profile /env /user:MS\<Your Github Enterprise LDAP User Name> "git pull"`

Then enter your LDAP password to execute the git pull command).


## Automation Details
The SQL Server Agent job for PSU is called **SuperUser**. 
It runs once monthly on the 26th of every month at 4:00 AM Central time. 

The employees below, who provide us the data, have all committed to provide the latest period's data by, at the latest, the 25th of each month.

- Andrew Clark (_andrew.clark@uhc.com_) owns the M&R PSU files, and has committed to have the latest files loaded **by the 25th** of every month.
- Brent Keckhaver (_brent.keckhaver@uhc.com_) owns the C&S files, and has committed to have the latest files loaded **by the 15th** of each month.
- Joshua Nadke (_joshua_nadke@uhc.com_) owns the E&I files, and has committed to have the latest files loaded **by the second Friday** of each month.


## Data
Each file represents the latest, rolling 12-month lookback period of Super Users across their respective LOB (Line of Business).

Every time the files are loaded, they are full files, meaning that the files contain all superusers for the given lookback period.

We are loading all Super Users from each LOB to our SQL Server database table:
    - Server:    **APVEP32146**
    - Database:  **IHR_RAP**
    - Schema:    **Member**
    - Table:     **SuperUser_All_LOBs**

To get Persistent Super Users (PSUs), filter the 'Is_PSU' column where it equals to 1.

Around 5% of all members are Super Users. Several factors help the HCE team to classify a member as a super user, an important factor being total healthcare spend. 
The scoring algorithms that differentiates between Superusers and Persistent Super Users incorporate factors such as:
        - utilization/spend
        - risk scores
        - limited demographics
        - medical/rx expense utilization and trends
        - chronic and comorbidity characteristics

These Super Users are scored by a statistical model built in SAS which incorporates factors about the members and outputs a number between 0 and 1. If the Member's score exceeds the threshold, or cutoff, then they are classified as a PSU. 
Each LOB has its own unique scoring algorithm and which score cutoff which is fixed.
