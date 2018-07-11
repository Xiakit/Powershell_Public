function Invoke-Adfunction {
    Param
    (

        [switch]$Remove,
        [switch]$Add,
        [string]$Csvpath = ".\male_names.csv" #Current folder as default
    )
    if ($Remove) {
        $CsvFile = Import-Csv -Path $Csvpath -Delimiter ";"
        foreach ($Line in $CsvFile) {
            Remove-ADUser -Identity $Line.Name -Confirm:$false
        }
    
    }
    if($Add) {
        $CsvFile = Import-Csv -Path $csvpath -Delimiter ";"

        foreach ($Line in $CsvFile) {
            New-ADUser -Name $Line.Name
            $Line.name
            $UserObject = Get-ADUser $Line.Name
            $Password = ConvertTo-SecureString -AsPlainText $Line.Passwort -Force
            $UserObject |Set-ADAccountPassword -NewPassword $Password

            $Groups = $Line.Group.split()
            foreach($Group in $Groups){
                [string]$UserGroup = $Group
                $GroupObject = Get-ADGroup -Filter {Name -like $UserGroup}
                if($GroupObject -eq $null){
                    "$Group Group not found"
                    continue
                }
                $GroupObject | Add-ADGroupMember -Members $UserObject
            }
            $UserObject | Set-ADUser -Enabled $true
        }
    }
}