function Set-CRConsoleTitle {
    <#
       .SYNOPSIS
       Sets the console window title to the defined text.
       
       .DESCRIPTION
       Sets the console window title to the defined text.

       .PARAMETER TitleText
       New title text.

       .EXAMPLE
       C:\PS> Set-CRConsoleTitle -TitleText '<<<This window is for installation>>>'
       Configures the current console window title text to <<<This window is for installation>>>

    #>
	[cmdletbinding()]
    param(
    [Parameter(Mandatory=$true,HelpMessage='Enter new console title.')][ValidateNotNullOrEmpty()][string]$TitleText
    )

    $host.ui.RawUI.WindowTitle = $TitleText
}