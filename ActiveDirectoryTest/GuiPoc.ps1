[void][System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Core")
$Form = New-Object system.Windows.Forms.Form
$Form.Text = "Poor Man's Active Directory Management"
$Form.TopMost = $true
$Form.Width = 622
$Form.Height = 384
$Path = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Path)

$CSVView = New-Object system.windows.Forms.ListView
$CSVView.Text = "CSVView"
$CSVView.Width = 382
$CSVView.Height = 204
$CSVView.location = new-object system.drawing.point(77, 73)
$Form.controls.Add($CSVView)

$csvpath = New-Object system.windows.Forms.TextBox
$csvpath.Text = "C:\Users\Administrator\Desktop\male_names.csv"
$csvpath.Width = 294
$csvpath.Height = 20
$csvpath.location = new-object system.drawing.point(162, 30)
$csvpath.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($csvpath)

$CsvPath_ = New-Object system.windows.Forms.Label
$CsvPath_.Text = "Path to CSV:"
$CsvPath_.AutoSize = $true
$CsvPath_.Width = 25
$CsvPath_.Height = 10
$CsvPath_.location = new-object system.drawing.point(74, 30)
$CsvPath_.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($CsvPath_)

$CreateUser = New-Object system.windows.Forms.Button
$CreateUser.Text = "Create User"
$CreateUser.Width = 98
$CreateUser.Height = 32
$CreateUser.Add_Click( {
        $CsvFile = Import-Csv -Path $csvpath.Text -Delimiter ";"
        Foreach ($item in $CSVView.SelectedItems) {
            $Username = $item.Text
            Foreach ($Line in $CsvFile) {
                if ($Line.Name -like $Username) {
                    New-ADUser -Name $Line.Name
                    $UserObject = Get-ADUser $Line.Name
                    $Password = ConvertTo-SecureString -AsPlainText $Line.Passwort -Force
                    $UserObject |Set-ADAccountPassword -NewPassword $Password
                    foreach ($Group in ($Line.Group.split())) {
                        [string]$UserGroup = $Group
                        $GroupObject = Get-ADGroup -Filter {Name -like $UserGroup}
                        if ($GroupObject -eq $null) {
                            "$Group Group not found"
                            continue
                        }
                        $GroupObject | Add-ADGroupMember -Members $UserObject
                    }
                    $UserObject | Set-ADUser -Enabled $true
                }
            }
        }
    })

$CreateUser.location = new-object system.drawing.point(479, 87)
$CreateUser.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($CreateUser)

$ListADUsers = New-Object system.windows.Forms.Button
$ListADUsers.Text = "List ADUsers"
$ListADUsers.Width = 98
$ListADUsers.Height = 32
$ListADUsers.Add_Click( {
        try {
            $ADUsers = Get-ADUser -Filter {Name -like "*"} | Select-Object -ExpandProperty Name
            $CSVView.clear()
            Foreach ($ADUser in $ADUsers) {
                $CSVView.items.Add($ADUser)
            }
        }
        catch {
            Write-Host "User not found"
        }
    })
$ListADUsers.location = new-object system.drawing.point(478, 136)
$ListADUsers.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($ListADUsers)

$DeleteUser = New-Object system.windows.Forms.Button
$DeleteUser.Text = "Delete User"
$DeleteUser.Width = 98
$DeleteUser.Height = 32
$DeleteUser.Add_Click( {
        foreach ($item in $CSVView.SelectedItems) {
            $Username = $item.Text
            Get-ADUser -Filter {name -like $Username} | Remove-AdUser -confirm:$false
        }
    })
$DeleteUser.location = new-object system.drawing.point(477, 187)
$DeleteUser.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($DeleteUser)

$OK = New-Object system.windows.Forms.Button
$OK.Text = "OK"
$OK.Width = 116
$OK.Height = 32
$OK.Add_Click( {
        $Ok.DialogResult = [System.Windows.Forms.DialogResult]::Ok
    })
$OK.location = new-object system.drawing.point(81, 301)
$OK.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($OK)

$Cancel = New-Object system.windows.Forms.Button
$Cancel.Text = "Cancel"
$Cancel.Width = 116
$Cancel.Height = 32
$Cancel.Add_Click( {
        $Cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    })
$Cancel.location = new-object system.drawing.point(228, 300)
$Cancel.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($Cancel)

$LoadButton = New-Object system.windows.Forms.Button
$LoadButton.Text = "Load"
$LoadButton.Width = 96
$LoadButton.Height = 30
$LoadButton.Add_Click( {
        if (Test-Path -Path ($csvpath.Text)) {
            $filepath = $csvpath.Text
            $content = Import-Csv -Path $filepath -Delimiter ";"
            $columns = $content | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty name
            $columns | ForEach-Object { $CSVView.Columns.Add($_)}
            $CSVView.Clear()
            foreach ($line in $content) {
                $CSVView.Items.Add(([string]$line.Name))
            }
        }
    })
$LoadButton.location = new-object system.drawing.point(479, 29)
$LoadButton.Font = "Microsoft Sans Serif,10"
$Form.controls.Add($LoadButton)

[void]$Form.ShowDialog()
$Form.Dispose()