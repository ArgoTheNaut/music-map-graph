$artists = Import-Csv .\artists.csv

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

$artists | foreach {$recommendations.Remove($_.Authors)}

$reccObjects = $recommendations.Keys | foreach {
    [PSCustomObject]@{Name=$_; Weight=$recommendations[$_]}
} | Sort-Object -Property Weight -Descending

0..30 | foreach {$reccObjects[$_]}
