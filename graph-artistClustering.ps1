<#
.SYNOPSIS
    Reads the local file .\artists.txt
#>


# Library Import
Import-Module PSGraph

$pss = $PSScriptRoot
$artistsBasePath = "$pss\artistWebPages"
if(-not (Test-Path $artistsBasePath)){mkdir $artistsBasePath}

Function Get-Timestamp {
    $d = Get-Date
    "$($d.Year)$($d.Month)$($d.Day)__$($d.Hour)$($d.Minute)$($d.Second)"
}

# Initialize artist list
[string[]]$artists = Get-Content "$pss\artists.txt" | Sort-Object                           # Initialize as list to acquire
### $artists = ls $artistsBasePath | % {$_.Name} | % {$_.Substring(0, $_.IndexOf("."))}     # Initialize as list of acquired .html files

$edges = @()                                     # directed connections between nodes denote the destination appeared in the list of the source node
$baseUrl = "https://www.music-map.com/"
$webClient = (New-Object System.Net.WebClient)

$i=0

$artists | foreach {
    Write-Progress -Activity "Processing $_" -PercentComplete ([int]($i*100/$artists.Length))
    $i++
    $webPageFilePath = "$artistsBasePath\$_.html"
    $artistName = $_
    $artistUrlSuffix = $_.Replace(" ","+")                 # Convert artist name to search string for web client
    $VersionSite = $baseUrl + $artistUrlSuffix

    try {
        if(-not (Test-Path $webPageFilePath)){
            $webClient.DownloadFile($VersionSite, $webPageFilePath)
            Write-host "Downloaded data for $artistName"
        }

        # Filter out artist names from raw HTML
        $relatedArtists = Get-Content $webPageFilePath | where {$_.Contains('<a href="')} | where {-not $_.Contains('id=s0')} | foreach {$_.Substring($_.IndexOf(">")+1)} | foreach {$_.Substring(0,$_.IndexOf("<")).toLower()}

        $artistEdges = 0  # Count amount of edges created for this artist
        $relatedArtists | foreach {$ra = $_
            if($artists | where {$_ -like $ra}){   # Check if the related artist from the HTML appears anywhere in the input artist list
                $edges += [PSCustomObject]@{src = $artistName;dest = $ra}                # Add an edge between the two artists
                $artistEdges++                                                           # Increment edge count
            }
        }
        
        if($artistEdges){Write-Host "Edges for artist $artistName - $artistEdges"}      # Report edge count for each arist

    } catch {
        Write-Host "Error for artist: $artistName     -  $_"
        Set-Content -Value "" -Path $webPageFilePath
    }
}

Write-Progress -Completed "Done"

$graph = graph d {        # Generate the graph
    # $artists | foreach {node $_ @{style='filled'} }    # Option to generate a node for every artist that appears even if they have no edges
    $edges | foreach {edge -From $_.src -to $_.dest}     # Draw all edges in the graph
} 

# Export the graph and save the image locally
$graph | Export-PSGraph -ShowGraph -DestinationPath "$pss\outputs\$(Get-Timestamp).png" -LayoutEngine Hierarchical
