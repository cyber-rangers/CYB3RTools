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
        [Parameter(Mandatory = $true, HelpMessage = 'Enter new console title.')][ValidateNotNullOrEmpty()][string]$TitleText
    )

    $host.ui.RawUI.WindowTitle = $TitleText
}

function Save-ScreenCapture {
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
 
    if (!(Test-Path $OutputFolder)) { New-Item $OutputFolder -ItemType Directory -Force | Out-Null }
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
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
        if ([int]$($stopwatch.Elapsed.TotalMilliseconds) -le $($RepetitionDurationSeconds * 1000)) { Start-Sleep -Milliseconds $RepetitionWaitMilliseconds }
    } until (
        [int]$($stopwatch.Elapsed.TotalMilliseconds) -gt $($RepetitionDurationSeconds * 1000)
    )
}

function Find-ItemADS {
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
       Find-ItemADS -Path C:\Temp -Recurse
       This example finds alternate data streams in files that are located in the C:\Temp directory and its subdirectories.
    #>
    [CmdletBinding()]
    Param(
        [ValidateScript( {
                if (!$($_ | Test-Path) ) {
                    throw "Folder does not exist" 
                }
                if (!$($_ | Test-Path -PathType Container) ) {
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
    }
    else {
        $ObjectsToAnalyze = Get-ChildItem -Path $Path
    }

    foreach ($ObjectToAnalyze in $ObjectsToAnalyze) {
        if ($ShowContent) {
            $ObjectToAnalyze | Get-Item -Stream * | Where-Object { $_.stream -ne ':$DATA' } | Select-Object -Property FileName, Stream, Length, @{n = 'Content'; e = {
                    return $(Get-Content -Path "$($_.FileName):$($_.stream)")
                }
            }
        }
        else {
            $ObjectToAnalyze | Get-Item -Stream * | Where-Object { $_.stream -ne ':$DATA' } | Select-Object -Property FileName, Stream, Length
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
        New-ItemADS -Path 'C:\Temp' -Name 'ADSFile.txt' -StreamName 'Secrets' -StreamContent 'This is secret content' -ContentEncoding Ascii -ItemType File
        Creates file ADSFile.txt in C:\Temp with alternate data stream Secrets.
    .EXAMPLE
        New-ItemADS -Path 'C:\Temp' -Name 'ADSFolder' -StreamName 'Secrets' -StreamContent 'This is secret content' -ContentEncoding Ascii -ItemType Directory
        Creates directory ADSFolder in C:\Temp with alternate data stream Secrets.
    .EXAMPLE
        New-ItemADS -Path 'C:\Temp' -Name 'ADSFileWithBinary.txt' -StreamName 'SecretBinary' -StreamContent ([System.IO.File]::ReadAllBytes("C:\Source\Coreinfo.exe")) -ContentEncoding Byte -ItemType File
        Creates file with ADS containing CoreInfo.exe binary in alternate data stream Secrets.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$StreamName,
        [Parameter(Mandatory)]$StreamContent,
        [Parameter(Mandatory)][ValidateSet('Ascii', 'Byte', 'UTF8')][string]$ContentEncoding,
        [Parameter(Mandatory)][ValidateSet('File', 'Directory')][string]$ItemType,
        [ValidateScript( {
                if (!$($_ | Test-Path) ) {
                    throw "Path does not exist" 
                }
                return $true
            })]
        [System.IO.FileInfo]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    $FullName = Join-Path $Path $Name

    if ($ItemType -eq 'Directory') {
        if (Test-Path $FullName) {
            throw ('Item {0} already exists.' -f $FullName)
        }
        New-Item $FullName -ItemType Directory -Force | Out-Null
    }
    Set-Content $('{0}:{1}' -f $FullName, $StreamName) -Value $StreamContent -Encoding $ContentEncoding
}

function Watch-Defense {
    <#
    .SYNOPSIS
        Waits until detects potential monitoring or analysis tool.
    .DESCRIPTION
        Waits until detects potential monitoring or analysis tool.
    #>
    [cmdletbinding()]
    param()
    $JobName = Get-Random
    Register-WMIEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 3 WHERE TargetInstance ISA 'Win32_Process' AND (TargetInstance.Name = 'mmc.exe' OR TargetInstance.Name = 'taskmgr.exe' OR TargetInstance.Name = 'procexp.exe' OR TargetInstance.Name = 'procexp64.exe')"`
        -sourceIdentifier "WatchDefense$JobName" -action { 'Detected' } | out-null

    Write-Verbose "Watching defense processes..."
    do {
        Start-Sleep -Seconds 1
    }
    until ($(Get-Job -Name "WatchDefense$JobName" | Select-Object -ExpandProperty HasMoreData) -eq $true)
    Write-Verbose "Defense Detected!"
    Get-Job -Name "WatchDefense$JobName" | stop-job -passthru | remove-job -Force
}

function Enable-PSTranscription {
    [CmdletBinding()]     param($OutputDirectory, [Switch] $IncludeInvocationHeader)

    [string]$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
    if (!$(Test-Path $RegistryPath)) { $null = New-Item $RegistryPath -Force }

    Set-ItemProperty $RegistryPath -Name EnableTranscripting -Value 1

    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("OutputDirectory")) { Set-ItemProperty $RegistryPath -Name OutputDirectory -Value $OutputDirectory }

    if ($IncludeInvocationHeader) { Set-ItemProperty $RegistryPath -Name IncludeInvocationHeader -Value 1 } 
}

function Disable-PSTranscription { Remove-Item HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription -Force -Recurse }

function Enable-PSScriptBlockLogging {
    [string]$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if (!$(Test-Path $RegistryPath)) { $null = New-Item $RegistryPath -Force }          Set-ItemProperty $RegistryPath -Name EnableScriptBlockLogging -Value "1" 
}

function Disable-PSScriptBlockLogging { Remove-Item 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Force -Recurse }

function Enable-PSScriptBlockInvocationLogging {
    [string]$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
    if (!$(Test-Path $RegistryPath)) { $null = New-Item $RegistryPath -Force }

    Set-ItemProperty $RegistryPath -Name EnableScriptBlockInvocationLogging -Value "1" 
}

function Disable-PSScriptBlockInvocationLogging {
    [string]$RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
    if (!$(Test-Path $RegistryPath)) { $null = New-Item $RegistryPath -Force }

    Set-ItemProperty $RegistryPath -Name EnableScriptBlockInvocationLogging -Value "0" 
}

function Disable-ExecutionPolicy {($ctx = $ExecutionContext.GetType().getfield("_context","nonpublic,instance").getvalue($ExecutionContext)).gettype().getfield("_authorizationManager","nonpublic,instance").setvalue($ctx, (New-Object System.Management.Automation.AuthorizationManager "Microsoft.PowerShell"))}

function Send-FileLinesToAzLA {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][string]$AzLAWorkspaceID,
        [Parameter(Mandatory = $true)][string]$AzLAPrimaryKey,
        [Parameter(Mandatory = $true)][string]$AzLACustomLogName,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [int]$Paging = 1000
    )

    Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
        #function source: https://docs.microsoft.com/cs-cz/azure/azure-monitor/platform/data-collector-api
        $xHeaders = "x-ms-date:" + $date
        $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)

        $sha256 = New-Object System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
        return $authorization
    }

    Function Post-LogAnalyticsData ($customerId, $sharedKey, $POSTBody, $logType, $TimeStampField = "") {
        #function source: https://docs.microsoft.com/cs-cz/azure/azure-monitor/platform/data-collector-api
        $method = "POST"
        $contentType = "application/json"
        $resource = "/api/logs"
        $rfc1123date = [DateTime]::UtcNow.ToString("r")
        $contentLength = $POSTBody.Length
        $signature = Build-Signature `
            -customerId $customerId `
            -sharedKey $sharedKey `
            -date $rfc1123date `
            -contentLength $contentLength `
            -method $method `
            -contentType $contentType `
            -resource $resource
        $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

        $headers = @{
            "Authorization"        = $signature;
            "Log-Type"             = $logType;
            "x-ms-date"            = $rfc1123date;
            "time-generated-field" = $TimeStampField;
        }

        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $POSTBody -UseBasicParsing
        return $response.StatusCode

    }


    function Send-DataToAzureLA {
        [cmdletbinding()]
        param (
            [string]$LogName,
            $Data,
            [string]$WorkspaceID,
            [string]$WorkspaceKey)

        $DataJSON = $Data | ConvertTo-JSON
        $DataJSONBytes = [System.Text.Encoding]::UTF8.GetBytes($DataJSON)
        $postresult = Post-LogAnalyticsData -customerId $WorkspaceID -sharedKey $WorkspaceKey -logType $LogName -PostBody $DataJSONBytes

        return $postresult
    }

    Write-Host "$(get-date -Format s) Started" -ForegroundColor white -BackgroundColor blue

    $objects_paged = New-Object -TypeName System.Collections.ArrayList

    $LineNumber = 1
    $PreviousSendLineNumber = 0
    [System.IO.File]::ReadLines($FilePath) | ForEach-Object {
        Write-Verbose "Processing line $LineNumber"
        Remove-Variable -Name obj -ErrorAction SilentlyContinue
        Remove-Variable -Name objProps -ErrorAction SilentlyContinue
        if (!$($_ -eq $null -or $_ -eq '')) {
            $objProps = @{
                FileName = $(Get-Item $FilePath | Select-Object -ExpandProperty Name)
                FileLine = $_
            }
            $obj = New-Object -TypeName psobject -ArgumentList $objProps    
            $objects_paged.Add($obj) | Out-Null
        }

        if ($LineNumber%$Paging -eq 0) {
            Write-Host "$(get-date -Format s) Sending $($PreviousSendLineNumber+1) - $LineNumber lines to AzLA..." -ForegroundColor black -BackgroundColor Yellow
            $result = Send-DataToAzureLA -Data $objects_paged -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
            if ($result -ne 200) {
                throw "$(get-date -Format s) Error Sending Data to Azure Log Analytics"
            } else {
                Write-Host "$(get-date -Format s) `tSuccessfully completed." -ForegroundColor black -BackgroundColor green
            }
            $objects_paged.Clear()
            $PreviousSendLineNumber = $LineNumber
        }
        $LineNumber++
    }

    #remaining paged objects
    Write-Host "$(get-date -Format s) Sending $($PreviousSendLineNumber+1) - $LineNumber lines to AzLA..." -ForegroundColor black -BackgroundColor Yellow
    $result = Send-DataToAzureLA -Data $objects_paged -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
    if ($result -ne 200) {
        throw "$(get-date -Format s) Error Sending Data to Azure Log Analytics"
    } else {
        Write-Host "$(get-date -Format s) `tSuccessfully completed." -ForegroundColor black -BackgroundColor green
    }

    Write-Host "$(get-date -Format s) Completed." -ForegroundColor white -BackgroundColor blue
}