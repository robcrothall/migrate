#+-------------------------------------------------------------------+  
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |  
#|{>/-------------------------------------------------------------\<}|           
#|: | Author:  Aman Dhally                                        | :|           
#| :| Email:   amandhally@gmail.com
#|: | Purpose: Smart Backup and create folder by Date       
#| :|          
#|: |           						                    
#| :|          
#|: |         		Date: 29 November 2011 
#|: |                            
#| :| 	/^(o.o)^\    Version: 1          						  |: | 
#|{>\-------------------------------------------------------------/<}|
#| = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = : = |
#+-------------------------------------------------------------------+


#System Variable for backup Procedure

# $date = Get-Date -Format d.MMMM.yyyy
 $date = Get-Date -Format yyyy.MM.dd
# New-PSDrive -Name "Backup" -PSProvider Filesystem -Root "\\T_Server\Tally"
# $source = "C:\Tally\Data\"
 $source = "C:\Users\rob\Documents\ADS Tasks\"
 $destination = "E:\Backup\$date"
 $path = test-Path $destination
 
#Email Variables

 $smtp = "Exchange-server"
 $from = "Tally Backup <tally.backup@xyz.com>"
 $to = "Aman Dhally <amandhally@gmail.com>"
 $body = "Log File of TALLY bacupk is attached, backup happens on of Date: $date"
 $subject = "Backup on $date"
 
# Backup Process started

 if ($path -eq $true) {
    write-Host "Directory Already exists"
#    Remove-PSDrive "Backup"  
    } elseif ($path -eq $false) {
#            cd backup:\
            cd E:\Backup\
            mkdir $date
            copy-Item  -Recurse $source -Destination $destination
            $backup_log = Dir -Recurse $destination | out-File "$destination\backup_log.txt"
            $attachment = "$destination\backup_log.txt"
#Send an Email to User 
#            send-MailMessage -SmtpServer $smtp -From $from -To $to -Subject $subject -Attachments $attachment -Body $body -BodyAsHtml
            write-host "Backup Sucessfull"
            cd c:\
 
# Remove-PSDrive "Backup"  
 }
 pause
 