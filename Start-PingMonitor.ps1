function Start-PingMonitor{
<#
.Synopsis
   This function was created to monitor my local internet connection as the connection would drop frequently.
.DESCRIPTION
   This function was created to monitor my local internet connection as the connection would drop frequently.
   I needed proof to my Internet provider that the connectivity was dropping so I had to log up/down status of
   certain IP's I needed to monitor.
.EXAMPLE
   Start-PingMonitor -Count 10 -Computer 8.8.8.8 -LogPath c:\temp\pinglog.csv
   Pings 8.8.8.8 - 10 times and logs the results in c:\temp\pinglog.csv
.EXAMPLE
   Start-PingMonitor -Count unlimited -Computer 8.8.8.8 -LogPath c:\temp\pinglog.csv -Verbose
   Pings 8.8.8.8 -forever and logs the results in c:\temp\pinglog.csv.  Verbose gives you status on the screen.
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        [String[]]$Computer,
        $Count = 4,
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    $Ping = @()

    #Test if path exists, if not, create it
    If (-not (Test-Path (Split-Path $LogPath) -PathType Container)){   
        Write-Verbose "Folder doesn't exist $(Split-Path $LogPath), creating..."
        New-Item (Split-Path $LogPath) -ItemType Directory | Out-Null
    }

    #Test if log file exists, if not add a header row
    If (-not (Test-Path $LogPath)){
        Write-Verbose "Log file doesn't exist: $($LogPath), creating..."
        Add-Content -Value '"TimeStamp","Source","Destination","IPV4Address","Status","ResponseTime"' -Path $LogPath
    }

    #Log collection loop
    If ($Count -like "unlimited"){
        While ($true) {
            Write-output "Pinging forever - Press Ctrl-C antime to stop..."
            foreach ($Comp in $Computer){
                Write-Verbose "Start Ping monitoring of $Comp forever..."
                $Ping = Get-WmiObject Win32_PingStatus -Filter "Address = '$Comp'" | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.__Server }},@{Label="Destination";Expression={ $_.Address }},IPv4Address,@{Label="Status";Expression={ If ($_.StatusCode -ne 0) {"DOWN"} Else {"UP"}}},ResponseTime
                $Result = $Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime | ConvertTo-Csv -NoTypeInformation
                $Result[1] | Add-Content -Path $LogPath
                Write-verbose ($Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime | Format-Table -AutoSize | Out-String)
            }#Foreach
            Write-Verbose "Beginning 10 Sec Sleep..."
            Start-Sleep -Seconds 10
        }#While
    }#IF
    else{
         While ($Count -gt 0) {
            foreach ($Comp in $Computer){
                Write-Verbose "Start Ping monitoring of $Comp for $Count times..."
                $Ping = Get-WmiObject Win32_PingStatus -Filter "Address = '$Comp'" | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.__Server }},@{Label="Destination";Expression={ $_.Address }},IPv4Address,@{Label="Status";Expression={ If ($_.StatusCode -ne 0) {"DOWN"} Else {"UP"}}},ResponseTime
                $Result = $Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime | ConvertTo-Csv -NoTypeInformation
                $Result[1] | Add-Content -Path $LogPath
                Write-verbose ($Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime | Format-Table -AutoSize | Out-String)
            }#ForEach
            Write-Verbose "Beginning 10 Sec Sleep..."
            Write-output "Pinging $count times - Press Ctrl-C antime to stop..."
            Start-Sleep -Seconds 10
            $Count --
        }#While   
    }#Else
}