#
# Module manifest for module 'CYB3RTools'
#
# Generated by: Jan Marek (Cyber Rangers)
#
# Generated on: 5/8/2019
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'CYB3RTools.psm1'

# Version number of this module.
ModuleVersion = '1.0.4'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '46169a8a-2a40-4f61-ab08-7bd9f9f00414'

# Author of this module
Author = 'Jan Marek, Cyber Rangers'

# Company or vendor of this module
CompanyName = 'Cyber Rangers'

# Copyright statement for this module
Copyright = '(c) 2019 Jan Marek, Cyber Rangers. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Penetration Testing and Red Team Operations tools.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
ProcessorArchitecture = 'None'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Security','Pentesting','RTO','PSModule'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/cyber-rangers/CYB3RTools/blob/master/LICENSE.md'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/cyber-rangers/CYB3RTools'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @"
 - Added Invoke-CRScreenshot function
"@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}