[CmdletBinding()]
param(
    [parameter()]
    [string]$copy,
    [parameter()]
    [string]$break,
    [parameter()]
    [string]$build,
    [parameter()]
    [switch]$clean = $false
)

function BuildFile($file) 
{
    #Write-Host "file passed is $file"
    $outfile = [convert]::FromBase64String($file.Hash)
    return $outfile
}
function BreakFile($file) 
{
    #Write-Host "path is $file"
    $broken = [convert]::ToBase64String([IO.File]::ReadAllBytes($file))
    return $broken
}
if($copy -eq '' -and $build -eq '' -and $break -eq '' -and $clean -eq $false)
{
    #Write-Host "Break is: $break | Build is: $build"
    Write-Host -ForegroundColor Red "[ERROR]::No suppied args!"
    Write-Host -ForegroundColor Yellow "Usage: breaks files into base64 strings, and reassembles them from a single file"
    write-Host -ForegroundColor Yellow "    -copy : copies the contents of mat-blk.log on the current host to the clipboard (experimental)"
    Write-Host -ForegroundColor Yellow "    -break : takes a filepath and breaks file into a base64 string, and store as a file in C:\users\public\mat-blk.log. If file already exists, appends a comma ',' and the supplied file as another string"
    Write-Host -ForegroundColor Yellow "    -build : Takes a filepath that goes to the file from -build and converts all line items in the list to their file formats. Files are built and then created in $pwd\files"
}
else 
{
    $splk = "C:\users\$env:USERNAME\AppData\Roaming\Code\logs\mat-blk.log"

    if($copy)
    {
        Get-Content -Path $splk | Set-Clipboard
    }

    if($build)
    {
        if(Test-Path $build)
        {
            New-Item -ItemType Directory -Path .\files -Force | Out-Null
            $import = import-csv $build
            foreach($line in $import)
            {
                $newBytes = BuildFile($line)
                $newfile = New-Item -Path $pwd\files\ -Name $line.Name
                [IO.File]::WriteAllBytes($newfile, $newBytes)
                #[IO.File]::WriteAllBytes($line.Name, $newBytes)
                $count++
            }

            Write-Host -ForegroundColor Green "Built: $count files in $pwd\files"
        }
        else
        {
            Write-Host -ForegroundColor Yellow "[ERROR]::unable to resolve path: $build"
        }
    }
    elseif($break)
    {
        $brkstr = BreakFile($break)
        $fileProps = Get-ItemProperty -Path $break
    }

    if(Test-Path $splk)
    {
        Write-Host "file exists, appending."
        $csvfile = import-csv $splk
        $csvfile.Name = $fileProps.Name
        $csvfile.Hash = $brkstr
        $csvfile | Export-Csv $splk -Append
    }
    else 
    {
        Write-Host "File does not exist. Creating."
        $hashes = [PSCustomObject]@{
            Name = $fileProps.Name
            Hash = $brkstr
        }
        Export-Csv -Path $splk -InputObject $hashes
    }
    if($clean -eq $true)
    {
        Remove-Item $splk
        Write-Host -ForegroundColor Green "Erased logs at $splk"
    }
}