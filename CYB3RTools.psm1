function Set-CRConsoleTitle {
    param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$TitleText
    )

    $host.ui.RawUI.WindowTitle = $TitleText
}

Export-ModuleMember -Function Set-CRConsoleTitle