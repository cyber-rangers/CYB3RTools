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
        [System.IO.FileInfo]$Path,
        [switch]$Recurse
    )

    if ($Recurse) {
        $ObjectsToAnalyze = Get-ChildItem -Path $Path -Recurse
    } else {
        $ObjectsToAnalyze = Get-ChildItem -Path $Path
    }

    foreach ($ObjectToAnalyze in $ObjectsToAnalyze) {
        $ObjectToAnalyze | Get-Item -Stream * | Select-Object -Property FileName,Stream,Length
    }
}