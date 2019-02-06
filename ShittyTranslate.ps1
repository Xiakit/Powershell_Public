<#

Stole this script from here: https://gallery.technet.microsoft.com/scriptcenter/Google-Translate-via-36574cef
And made this shitty

#> 
 
Function Show-CrappyTranslation 
{ 
      [CmdletBinding(DefaultParametersetName = 'Console')] 
      param 
      ( 
            [ValidateSet('Afrikaans','Albanian','Arabic','Azerbaijani','Basque','Bengali','Belarusian','Bulgarian','Catalan','Chinese Simplified','Chinese Traditional','Croatian', 
                        'Czech','Danish','Dutch','English','Esperanto','Estonian','Filipino','Finnish','French','Galician','Georgian','German','Greek','Gujarati','Haitian Creole', 
                        'Hebrew','Hindi','Hungarian','Icelandic','Indonesian','Irish','Italian','Japanese','Kannada','Korean','Latin','Latvian','Lithuanian','Macedonian','Malay', 
                        'Maltese','Norwegian','Persian','Polish','Portuguese','Romanian','Russian','Serbian','Slovak','Slovenian','Spanish','Swahili','Swedish','Tamil','Telugu', 
                  'Thai','Turkish','Ukrainian','Urdu','Vietnamese','Welsh','Yiddish') 
            ] 
            [String]$From = 'English', 
 
            [ValidateSet('Afrikaans','Albanian','Arabic','Azerbaijani','Basque','Bengali','Belarusian','Bulgarian','Catalan','Chinese Simplified','Chinese Traditional','Croatian', 
                        'Czech','Danish','Dutch','English','Esperanto','Estonian','Filipino','Finnish','French','Galician','Georgian','German','Greek','Gujarati','Haitian Creole', 
                        'Hebrew','Hindi','Hungarian','Icelandic','Indonesian','Irish','Italian','Japanese','Kannada','Korean','Latin','Latvian','Lithuanian','Macedonian','Malay', 
                        'Maltese','Norwegian','Persian','Polish','Portuguese','Romanian','Russian','Serbian','Slovak','Slovenian','Spanish','Swahili','Swedish','Tamil','Telugu', 
                  'Thai','Turkish','Ukrainian','Urdu','Vietnamese','Welsh','Yiddish') 
            ] 
            [String]$To, 
 
            [String]$Text, 
 
            [Parameter(parametersetname='Console' )] 
            [Switch]$Console 
      ) 
 
 
      $LanguageHashTable =  
      @{ 
            Afrikaans='af' 
            Albanian='sq' 
            Arabic='ar' 
            Azerbaijani='az' 
            Basque='eu' 
            Bengali='bn' 
            Belarusian='be' 
            Bulgarian='bg' 
            Catalan='ca' 
            'Chinese Simplified'='zh-CN' 
            'Chinese Traditional'='zh-TW' 
            Croatian='hr' 
            Czech='cs' 
            Danish='da' 
            Dutch='nl' 
            English='en' 
            Esperanto='eo' 
            Estonian='et' 
            Filipino='tl' 
            Finnish='fi' 
            French='fr' 
            Galician='gl' 
            Georgian='ka' 
            German='de' 
            Greek='el' 
            Gujarati='gu' 
            Haitian ='ht' 
            Creole='ht' 
            Hebrew='iw' 
            Hindi='hi' 
            Hungarian='hu' 
            Icelandic='is' 
            Indonesian='id' 
            Irish='ga' 
            Italian='it' 
            Japanese='ja' 
            Kannada='kn' 
            Korean='ko' 
            Latin='la' 
            Latvian='lv' 
            Lithuanian='lt' 
            Macedonian='mk' 
            Malay='ms' 
            Maltese='mt' 
            Norwegian='no' 
            Persian='fa' 
            Polish='pl' 
            Portuguese='pt' 
            Romanian='ro' 
            Russian='ru' 
            Serbian='sr' 
            Slovak='sk' 
            Slovenian='sl' 
            Spanish='es' 
            Swahili='sw' 
            Swedish='sv' 
            Tamil='ta' 
            Telugu='te' 
            Thai='th' 
            Turkish='tr' 
            Ukrainian='uk' 
            Urdu='ur' 
            Vietnamese='vi' 
            Welsh='cy' 
            Yiddish='yi' 
      } 
 
      if ($pscmdlet.ParameterSetName -eq 'Console') 
      { 
            $Output =  New-Object System.Collections.ArrayList
            foreach($Word in $Text.Split()){
                $Word
                $URL = 'http://www.google.com/translate_t?hl=en&ie=UTF8&text={0}&langpair={1}|{2}' -f $Word, $LanguageHashTable[$from],  $LanguageHashTable[$to] 
                $WebClient = New-Object System.Net.WebClient 
                $WebClient.Encoding = [System.Text.Encoding]::UTF8 
                $Result = $WebClient.DownloadString($url) 
                $TrResult = $Result.Substring($Result.IndexOf('id=result_box') + 22, 1000); 
                $word = [regex]::Match($TrResult,'(?s)(?<=onmouseout.*\>).*?(?=\<)')|  ForEach-Object { $_.Groups.value  -replace '&#39;' ,"'"}
                $Output.Add($word) | Out-Null
            }
            Return $Output -join " "  
      } 
} 
 
 