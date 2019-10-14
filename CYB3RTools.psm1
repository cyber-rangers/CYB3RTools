function Set-ConsoleTitle {
    <#
       .SYNOPSIS
       Sets the console window title to the defined text.
       
       .DESCRIPTION
       Sets the console window title to the defined text.

       .PARAMETER TitleText
       New title text.

       .EXAMPLE
       C:\PS> Set-ConsoleTitle -TitleText '<<<This window is for installation>>>'
       Configures the current console window title text to <<<This window is for installation>>>

    #>
	[cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,HelpMessage='Enter new console title.')][ValidateNotNullOrEmpty()][string]$TitleText
    )

    $host.ui.RawUI.WindowTitle = $TitleText
}

function Save-ScreenCapture
{
    <#
       .SYNOPSIS
       Takes the screeshot of all displays to bmp file.
       
       .DESCRIPTION
       Takes the screeshot of all displays to bmp file. You can define duration for which screeshots should be taken and how long it should wait before each screeshoting cycle.

       .PARAMETER OutputFolder
       Output folder to store final screenshots in BMP format.

       .PARAMETER RepetitionDurationSeconds
       Duration in seconds for how long screenshots should be taken.

       .PARAMETER RepetitionWaitMilliseconds
       Duration in milliseconds for how long the script should wait before each screenshotting cycle during the defined RepetitionDurationSeconds.

       .EXAMPLE
       C:\PS>  Save-ScreenCapture
       Initiates single screenshot for each display and save outputs to the TEMP folder.

       .EXAMPLE
       C:\PS>  Save-ScreenCapture -OutputFolder 'C:\Users\Foo\AppData\Local\SCRs' -RepetitionDurationSeconds 3600 -RepetitionWaitMilliseconds 300000
       Initiates screenshotting to run for 1 hour with 5 minutes waiting interval and saves output files to the folder C:\Users\Foo\AppData\Local\SCRs
    #>
    [CmdletBinding()]
    param(
        [string]$OutputFolder = "$env:Temp",
        [int]$RepetitionDurationSeconds = 0,
        [int]$RepetitionWaitMilliseconds = 0
     )
    
    Add-Type -AssemblyName System.Windows.Forms
 
    if (!(Test-Path $OutputFolder)) {New-Item $OutputFolder -ItemType Directory -Force | Out-Null}
    $stopwatch =  [System.Diagnostics.Stopwatch]::StartNew()
    do {
        foreach ($SingleScreen in $([System.Windows.Forms.Screen]::AllScreens | Sort-Object -Property DeviceName)) {
            [string]$SingleScreeDeviceName = $SingleScreen.DeviceName.TrimStart('\\').split('\')[-1]
            Write-Verbose "Taking screenshot from $SingleScreeDeviceName"
            $filename = "SCR-$((Get-Date).ToString('yyyyMMdd-HHmmss-fff'))-$SingleScreeDeviceName.bmp"
            $outputpath = Join-Path $OutputFolder $fileName
            $BitmapObj = New-Object System.Drawing.Bitmap($SingleScreen.Bounds.Width, $SingleScreen.Bounds.Height)
            $GraphicsObj = [System.Drawing.Graphics]::FromImage($BitmapObj)
            $GraphicsObj.CopyFromScreen($SingleScreen.Bounds.X, $SingleScreen.Bounds.Y, 0, 0, $SingleScreen.Bounds.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
            $GraphicsObj.Dispose()
            $BitmapObj.Save($outputpath)
        }
        if ([int]$($stopwatch.Elapsed.TotalMilliseconds) -le $($RepetitionDurationSeconds*1000)) {Start-Sleep -Milliseconds $RepetitionWaitMilliseconds}
    } until (
        [int]$($stopwatch.Elapsed.TotalMilliseconds) -gt $($RepetitionDurationSeconds*1000)
    )
}

function Find-ItemADS
{
    <#
       .SYNOPSIS
       Finds Alternate Data Streams in files in specific folder(s).
       
       .DESCRIPTION
       Finds Alternate Data Streams in files in specific folder(s).

       .PARAMETER Path
       Location where to find alternate data streams.

       .PARAMETER Recurse
       Gets alternate data streams in the specified location and in all child items of the location.

       .EXAMPLE
       C:\PS>  Find-ItemADS -Path C:\Users -Recurse
       This example finds alternate data streams in files that are located in the specified directory and its subdirectories.
    #>
    [CmdletBinding()]
    Param(
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "Folder does not exist" 
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Path argument must be a Folder."
            }
            return $true
        })]
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$Path,
        [switch]$Recurse,
        [switch]$ShowContent
    )

    if ($Recurse) {
        $ObjectsToAnalyze = Get-ChildItem -Path $Path -Recurse
    } else {
        $ObjectsToAnalyze = Get-ChildItem -Path $Path
    }

    foreach ($ObjectToAnalyze in $ObjectsToAnalyze) {
        if ($ShowContent) {
            $ObjectToAnalyze | Get-Item -Stream * | Where-Object {$_.stream -ne ':$DATA'} | Select-Object -Property FileName,Stream,Length,@{n='Content';e={
                return $(Get-Content -Path "$($_.FileName):$($_.stream)")
            }}
        } else {
            $ObjectToAnalyze | Get-Item -Stream * | Where-Object {$_.stream -ne ':$DATA'} | Select-Object -Property FileName,Stream,Length
        }
    }
}

function New-ItemADS {
    <#
    .SYNOPSIS
        Creates Alternate Data Streams in specific files or folders.
    .DESCRIPTION
        Creates Alternate Data Streams in specific files or folders.
    .PARAMETER Stream
        Name of alternate data stream.
    .PARAMETER Content
        Content of the alternate data stream.
    .PARAMETER ContentEncoding
        Specified the content encoding type.
    .PARAMETER ItemType
        Type of item to hold the alternate data stream.
    .PARAMETER Path
        Path for the existing file or folder to hold the alternate data stream.
    .EXAMPLE
        PS C:\> <example usage>
        This example creates directory with alternate data stream.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Stream,
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][ValidateSet('Ascii','UTF8')][string]$ContentEncoding,
        [Parameter(Mandatory)][ValidateSet('File','Directory')][string]$ItemType,
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
            throw "Path does not exist" 
            }
            return $true
        })]
        [System.IO.FileInfo]$Path
    )

    switch ($ItemType) {
        'File' {write-host 'This function is currently not implemented'}
        'Directory' {
            Set-Content $('{0}:{1}' -f $Path,$Stream) -Value $Content -Encoding $ContentEncoding -Force
        }
    }
}