<#
Prerequisites:
-Microsoft Exchange Web Services Managed API 2.2
-Userrights to create a scheduled Task

Credits to https://sysadminben.wordpress.com/2015/10/27/reading-emails-from-office365-account-using-powershell/
Credits to http://www.garrettpatterson.com/2014/04/18/checkread-messages-exchangeoffice365-inbox-with-powershell/
Donwload DLL from here https://www.microsoft.com/en-us/download/details.aspx?id=42951
#>
$Workfolder = $PSScriptRoot

#Creating config
if(!(Test-Path "$Workfolder\Settings.txt")){
    $ExampleConfig = "[General settings]
DayAbsent=Thursday
CheckEverXMinutes=5

[Office365 settings]
MyMail=pascal.grossrieder@yrbrands.com
Domain=yrbrands.com

[Mail configuration]
From=pascal.grossrieder@gmx.net	
Subject=Out of Office.
Body=Jeweils Freitags nicht im Office.

[SMTP config]
SmtpServer=smtp.gmx.net
SmtpUser=pascal.grossrieder@gmx.net
Port=587
UseSmtpLogin=True
UseSSL=True

[Debugging]
Debugging=False

"
    $ExampleConfig | Out-File -FilePath "$Workfolder\Settings.txt"
    Write-Host "Please check the config file ("$Workfolder\Settings.txt") `r`n and add the needed details, you will be asked for your password when you run this script again." -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter to continue."
    Exit
}

#Loading the config
$ConfigContent = Get-Content "$Workfolder\Settings.txt"
$Config = @{}
foreach($Line in $ConfigContent){
  $Line = [regex]::Split($Line,"=")
  if(($Line[0].CompareTo("") -ne 0) -and ($Line[0].StartsWith("[") -ne $True)){
      $Config.Add($Line[0], $Line[1])
  }
}

#Configuration
$MyMail = $config.MyMail               #Adress used in Office365
$Domain = $config.Domain               #Domain name used for the authentication process in office 365 "mycompany.com" for example
$DayAbsent = $config.DayAbsent         #On what days should the script run
$CheckEverXMinutes = [int]$config.CheckEverXMinutes     #Interval to check for new messages
$Debugging = $config.Debugging   #Displays more info

if(($Debugging -like "True")){
    Start-Transcript -Path "$Workfolder\Transcript.log"
    $DebugPreference = Continue
}

#To save your password secure in a file
if(!(Test-Path $Workfolder\cred.txt)){
    Read-Host -AsSecureString -Prompt "Type your Office365 Password" | ConvertFrom-SecureString | Out-File -FilePath "$Workfolder\cred.txt" -Force
}
$Office365Password = Get-Content -Path "$Workfolder\cred.txt" | ConvertTo-SecureString

if($config.UseSmtpLogin -like "True"){
    if(!(Test-Path $Workfolder\smtpcred.txt)){
        Read-Host -AsSecureString -Prompt "Type your SMTP providers password usually your mail-password" | ConvertFrom-SecureString | Out-File -FilePath "$Workfolder\smtpcred.txt" -Force
    }
    $SmptUser = $Config.SmtpUser
    $SmptPassword = Get-Content $Workfolder\smtpcred.txt | ConvertTo-SecureString
    $Credentials = New-Object -typename System.Management.Automation.PSCredential -argumentlist $SmptUser,$SmptPassword
}

#Configuration to send messages
$ParamsSendmail = @{
    From = $config.From
    SmtpServer = $config.SmtpServer
    Subject = $config.Subject
    Body = $config.Body
    UseSSL = if($config.UseSSL -like "True"){$true}else{$false}
    Port= [int]$config.Port
    Credential = $Credentials
}
#Removing unused keys and values
foreach($param in $ParamsSendmail.GetEnumerator()){
    if($param.Value -eq "" -and $param.Value -ne $true -and $param.Value -ne $false){
        Write-Host $param.Name
        $ParamsSendmail.Remove($param.Name)
    }
}

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
    Write-Host -ForegroundColor Red "The Required Web Services Managed API 2.2 is not available, please download and install it. Download it at https://www.microsoft.com/en-us/download/details.aspx?id=42951"
    Read-Host "Press enter to continue"
    Exit
}

if ((get-date).DayOfWeek -notlike "$DayAbsent") {
    Write-Host "It is not $DayAbsent, you need to define $((get-date).DayOfWeek) in the script in order to auto respond today."
}
else {
    $SentMailsLog = "$Workfolder\Sentmails.log"
    Remove-Item -Path $SentMailsLog -Force -ErrorAction SilentlyContinue

    while ((get-date).DayOfWeek -like "$DayAbsent") {
        $SenderList = Get-Office365Senders -O365Mail $MyMail -Password $Office365Password -Domain $Domain
        foreach ($Line in $SenderList) {
            $To = $Line
            if ((get-content $SentMailsLog -erroraction silentlycontinue) -contains $To) {
                Write-Debug "$(get-date): $To has already received a out of office message, skipping."
                continue
            }
            else {
                $To | Out-File -Append -FilePath $SentMailsLog -Force
                Write-Host "$(get-date): Sending mail to $To"
                $ParamsSendmail.Add("To",$To)
                Send-MailMessage @ParamsSendmail 
            }
        }
        Start-Sleep -Seconds ($CheckEverXMinutes*60)
    }
}

if($Debugging){
    Stop-Transcript
}

