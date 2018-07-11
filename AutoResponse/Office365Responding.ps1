<#
Prerequisites:
-Microsoft Exchange Web Services Managed API 2.2
-Userrights to create a scheduled Task

Credits to https://sysadminben.wordpress.com/2015/10/27/reading-emails-from-office365-account-using-powershell/
Credits to http://www.garrettpatterson.com/2014/04/18/checkread-messages-exchangeoffice365-inbox-with-powershell/
Donwload DLL from here https://www.microsoft.com/en-us/download/details.aspx?id=42951
#>
$Workfolder = "C:\Users\grossriederp\Documents\Powershell_Public\AutoResponse"

#Creating config
if(!(Test-Path "$Workfolder\Settings.txt")){
    $ExampleConfig = "[General]
MyMail=pascal.grossrieder@learning.ifa.ch
DayAbsent=Friday
Domain=ifa.ch
CheckEverXMinutes=5
[SendingMail]
From=blabla.ch
SmtpServer=smpt.blabla.ch
Subject=Out of Office.
MyOutOfOfficeMessage=Jeweils Freitags nicht im Office.
[Debugging]
Debugging=False"
    $ExampleConfig | Out-File -FilePath "$Workfolder\Settings.txt"
    Write-Host "Please check the config file ("$Workfolder\Settings.txt") `r`n and add the needed details, you will be asked for your password when you run this script again." -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to continue."
}

#Loading the config
Get-Content "$Workfolder\Settings.txt" | foreach-object -begin { $config=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $config.Add($k[0], $k[1]) } }

#Configuration
#Configuration to log in
$MyMail = $config.MyMail         #Adress used in Office365
$Domain = $config.Domain               #Domain name used for the authentication process in office 365 "mycompany.com" for example
$DayAbsent = $config.DayAbsent         #On what days should the script run
$CheckEverXMinutes = [int]$config.CheckEverXMinutes     #Interval to check for new messages
$Debugging = [bool]$config.Debugging


if($Debugging){
    Start-Transcript -Path "$Workfolder\Transcript.log"
    $DebugPreference = Continue
}


#To save your password secure in a file
if(!(Test-Path $Workfolder\cred.txt)){
    Read-Host -AsSecureString -Prompt "Type your Password" | ConvertFrom-SecureString | Out-File -FilePath "$Workfolder\cred.txt" -Force
}
$Password = Get-Content -Path "$Workfolder\cred.txt" | ConvertTo-SecureString

#Configuration to send messages
$From = $config.From #The adress the mail will be sent from, if possible use the same domain in the adress as the smtpserver in order to avoid the junk folder :)
$SmtpServer = $config.SmtpServer
$Subject = $config.Subject
$MyOutOfOfficeMessage = $config.MyOutOfOfficeMessage

<#
    Example using GMX as SMTP
    Read-Host -AsSecureString | ConvertFrom-SecureString  #Use this line to save your password to a file
    $Password = Get-Content C:\temp\cred.txt | ConvertTo-SecureString
    $Credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist "mymail@gmx.net",$password
    $Subject = "MySubject"
    $To = "recipient@mail.ch"
    $From = "mymail@gmx.net"
    $MessageBody = "MyMessage"
    $SMTPServer = "smtp.gmx.net"
    $SMTPPort = "587"
    Send-MailMessage -Body "$MessageBody" -To  $To -from $From -subject $Subject -SmtpServer $SMTPServer -Credential $Credentials -Port $SMTPPort -UseSsl
#>

function Get-Office365Senders($O365Mail, [securestring]$Password, $Domain){
    $SenderList = New-object System.Collections.ArrayList
    [Reflection.Assembly]::LoadFile( "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll") | Out-Null
    $s = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)
    $s.Credentials = New-Object Net.NetworkCredential($O365Mail, $Password, $Domain)
    $s.Url = new-object Uri("https://outlook.office365.com/EWS/Exchange.asmx");
    $inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($s,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)
    $iv = new-object Microsoft.Exchange.WebServices.Data.ItemView(50)
    $inboxfilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::And)
    $ifisread = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::IsRead,$false)
    $inboxfilter.add($ifisread)
    $msgs = $s.FindItems($inbox.Id, $inboxfilter, $iv) | Select-Object -Property Sender
    foreach($sender in $msgs){
        $SenderList.Add([string]$sender.Sender.Address) | Out-Null
    }
    return $SenderList
}

if (!(Test-Path -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll")){
    throw "The Required Web Services Managed API 2.2 is not available, please download and install it. Download it at https://www.microsoft.com/en-us/download/details.aspx?id=42951"
}

if ((get-date).DayOfWeek -notlike "$DayAbsent") {
    Write-Host "It is not $DayAbsent, you need to define $((get-date).DayOfWeek) in the script in order to auto respond today."
}
else {
    $SentMailsLog = "$Workfolder\Sentmails.log"
    Remove-Item -Path $SentMailsLog -Force -ErrorAction SilentlyContinue

    while ((get-date).DayOfWeek -like "$DayAbsent") {
        $SenderList = Get-Office365Senders -O365Mail $MyMail -Password $Password -Domain $Domain
        foreach ($Line in $SenderList) {
            $To = $Line
            if ((get-content $SentMailsLog -erroraction silentlycontinue) -contains $To) {
                Write-Debug "$(get-date): $To has already received a out of office message, skipping."
                continue
            }
            else {
                $To | Out-File -Append -FilePath $SentMailsLog -Force
                Write-Host "$(get-date): Sending mail to $To"
                Send-MailMessage -Body $MyOutOfOfficeMessage  -To  $To -from $From -subject $Subject -SmtpServer $SmtpServer
            }
        }
        Start-Sleep -Seconds ($CheckEverXMinutes*60)
    }
}

if($Debugging){
    Stop-Transcript
}

