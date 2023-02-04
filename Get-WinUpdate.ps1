Clear-Host
#$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
function Get-WinUpdate {

    param(
        [Parameter(Mandatory)]
        [array]$object
    )

    $result = foreach ($server in $object) {
        Invoke-Command -ComputerName $server -EnableNetworkAccess -ScriptBlock {
            $data_raw = Get-WinEvent -LogName "Setup" | Select-Object -Property * | Where-Object { $_.Message -like "*successfully changed to the Installed*" }
            
            foreach ($data in $data_raw) {
                $server_name = $data.MachineName
    
                $kb_name = $data.Message | `
                ForEach-Object { $_ -replace ("successfully changed to the Installed.", "") `
                -replace ("Package ", "") `
                -replace ("was state.", "") }
    
                $Install_date = $data.TimeCreated
    
                $user = $data.UserID
                if ($data.UserID -eq "S-1-5-18") {
                    $user = "System"
                }
    
                [PSCustomObject]@{
                    Server      = $server_name
                    KB          = $kb_name
                    InstallDate = $Install_date
                    User        = $user
                }
            }
        }
    }

    $result | Select-Object Server,KB,InstallDate,User | Format-Table -AutoSize
}
Get-WinUpdate -object $env:COMPUTERNAME
