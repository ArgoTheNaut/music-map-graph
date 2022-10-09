$artists = Import-Csv .\artists.csv

$replaceStrings = @{
    "the" = "*"
    " "   = "*"
}

function duration-toSeconds($str){
    $timeSec = 0
    [int[]]$parts = $str -split ":"
    $timeSec += $parts[0] * 60 * 60
    $timeSec += $parts[1] * 60
    $timeSec += $parts[2]
    $timeSec
}

$artists | foreach {$_.PlayTime = duration-toSeconds $_.PlayTime}

$recommendations = @{}

Write-host 'Generating weights'
$artists | foreach {$a = $_.Authors; $pt = $_.PlayTime
    $webPageFilePath = ".\artistWebPages\$a.html"
    # Filter out artist names from raw HTML
    $relatedArtists = Get-Content $webPageFilePath -ErrorAction SilentlyContinue | where {$_.Contains('<a href="')} | where {-not $_.Contains('id=s0')} | foreach {$_.Substring($_.IndexOf(">")+1)} | foreach {$_.Substring(0,$_.IndexOf("<")).toLower()}
    # Write-Host $relatedArtists
    $relatedArtists | foreach {
        if(-not $recommendations[$_]){$recommendations[$_] = 0}
        $recommendations[$_] += $pt
    }
}

$reccObjects = $recommendations.Keys | foreach {
    [PSCustomObject]@{Name=$_; Weight=$recommendations[$_]; AlreadyKnown=0}
} | Sort-Object -Property Weight -Descending

Write-Host "Accounting for what you already listened to..."
$artists | foreach {
    $a = $_
    $replaceStrings.Keys | foreach {$a.Authors = $a.Authors.Replace($_, $replaceStrings[$_])}
    $reccObjects | foreach {
        if($_.Name -like $a.Authors){
            $_.Weight -= $a.PlayTime * $a.PlayTime
            $_.AlreadyKnown += $a.PlayTime
        }
    }
}

$reccObjects = $reccObjects | Sort-Object -Property Weight -Descending


# $artists | foreach {$recommendations.Remove($_.Authors)}

0..30 | foreach {$reccObjects[$_]}
