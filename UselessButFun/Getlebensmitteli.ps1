$global:csvpath = "$Psscriptroot\Lebensmitteli.csv"
function Get-Product {
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            ParameterSetName='Find')]
        $Name,

        # Param2 help description
        [int]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            ParameterSetName='Find')]
        $Menge,

        [switch]
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2,
            ParameterSetName='List')]
        $List,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 3,
            ParameterSetName='Find')]
        $csv = (Import-Csv -Delimiter ";" -Path $global:csvpath)
    )
    if($List){
        $csv | Sort-Object -Property Name | ft
        return
    }


    foreach ($entry in $csv) {
        $entry.Kcal = [int]$entry.Kcal
        $entry.Protein = [int]$entry.Protein
        $entry.Fett = [int]$entry.Fett
        $entry.Kohlenhydrate = [int]$entry.Kohlenhydrate
        $entry.Energiedichte = [int]$entry.Energiedichte
    }

    $Line = $csv[($csv.Name.IndexOf([string]$Name))]
    "Kcal: " + [int]$Line.Kcal * $menge / 100 + "g"
    "Protein: " + [int]$Line.Protein * $menge / 100 + "g"
    "Fett: " + [int]$Line.Fett * $menge / 100 + "g" 
    "Kohlenhydrate: " + [int]$Line.Kohlenhydrate * $menge / 100 + "g"
}

Function Prepare-Day(){
    $Liste = Import-Csv -Path $global:csvpath -Delimiter ";"
    $HauptBestandteil = $Liste.GetEnumerator() | Where-Object {$_.Beilage -like "Nein" }
    $Beilagen = $Liste | Where-Object {$_.Beilage -like "Ja" -and $_.Snackable -like "Nein"}
    $Snacks = $Liste | Where-Object {$_.Snackable -like "Ja"}

    $Beilagen[(Get-Random -min 0 -max $Beilagen.Count)]
    $HauptBestandteil[(Get-Random -min 0 -max $HauptBestandteil.Count)]
    $Snacks[(Get-Random -min 0 -max $Snacks.Count)]
}