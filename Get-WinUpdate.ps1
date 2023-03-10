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
            
            $i = 0
            foreach ($data in $data_raw) {

                if ($i -eq 0) {
                    $server_name = $data.MachineName
                }
                else {
                    $server_name = ""
                }
            
                $kb_name = $data.Message | `
                    ForEach-Object { $_ -replace ("successfully changed to the Installed.", "") `
                        -replace ("Package ", "") `
                        -replace ("was state.", "") }
        
                $Install_date = $data.TimeCreated
        
                $user = $data.UserID
                if ($data.UserID -eq "S-1-5-18") {
                    $user = "System"
                }
    
                $last_update = (New-TimeSpan -Start ($data.TimeCreated) -End (Get-Date)).Days
    
                $status = ""
                if ($last_update -lt "30") {
                    $status = "Not OK"
                }
    
                else {
                    $status = "OK"
                }

                $total_patch_installed = $data_raw.Length

                [PSCustomObject]@{
                    Server              = $server_name
                    KB                  = $kb_name
                    InstallDate         = $Install_date
                    User                = $user
                    "LastUpdate (Days)" = $last_update
                    Status              = $status
                    TotalPatch          = $total_patch_installed
                }

                $i = $i + 1
            }
        }
    }

    $result | Select-Object Server, KB, InstallDate, User, "LastUpdate (Days)", Status, TotalPatch | Format-Table -AutoSize
}

Get-WinUpdate -object DESKTOP-9CKGQK2, DESKTOP-9CKGQK2
