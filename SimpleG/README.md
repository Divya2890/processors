### Steps for creating executables after cloning the GP12 repo

1. Copy over the database.tab and aggregate.tab within GP12 Folder and run the following commands in order :
 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;``tablo.exe -wfp database.tab``,

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;``ltg.py database``,
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;``tablo.exe -wfp aggregate.tab``,
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;``ltg.py aggregate``
  
2. This step creates intermediatory files and linux executables needed to run the dataclean and dataproc scripts of SimpleG model

