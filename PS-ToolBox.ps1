$art = @'
 _    _      _                            _          _____               _   _                       
| |  | |    | |                          | |        |  __ \             | | | |                      
| |  | | ___| | ___ ___  _ __ ___   ___  | |_ ___   | |  \/_   _ _   _  | |_| | ___ _ __ ___   ___   
| |/\| |/ _ \ |/ __/ _ \| '_ ` _ \ / _ \ | __/ _ \  | | __| | | | | | | |  _  |/ _ \ '_ ` _ \ / _ \  
\  /\  /  __/ | (_| (_) | | | | | |  __/ | || (_) | | |_\ \ |_| | |_| | | | | |  __/ | | | | | (_) | 
 \/  \/ \___|_|\___\___/|_| |_| |_|\___|  \__\___/   \____/\__,_|\__, | \_| |_/\___|_| |_| |_|\___/  
                                                                  __/ |                              
                                                                 |___/                               
______                      _____ _          _ _   _____           _______                           
| ___ \                    /  ___| |        | | | |_   _|         | | ___ \                          
| |_/ /____      _____ _ __\ `--.| |__   ___| | |   | | ___   ___ | | |_/ / _____  __                
|  __/ _ \ \ /\ / / _ \ '__|`--. \ '_ \ / _ \ | |   | |/ _ \ / _ \| | ___ \/ _ \ \/ /                
| | | (_) \ V  V /  __/ |  /\__/ / | | |  __/ | |   | | (_) | (_) | | |_/ / (_) >  <                 
\_|  \___/ \_/\_/ \___|_|  \____/|_| |_|\___|_|_|   \_/\___/ \___/|_\____/ \___/_/\_\                
'@ 

Write-Host $art -ForegroundColor Yellow -BackgroundColor DarkMagenta

# Prompt for server IP address

$server =  $(Write-Host "Enter server IP address: " -ForegroundColor Cyan -NoNewLine; Read-Host)

function MainMenu {
    Write-Host "Current Server: $server" -ForegroundColor Yellow -BackgroundColor DarkGreen
    Write-Host "Please select an option: " -ForegroundColor Cyan
    Write-Host "1. Get Hard Disk Capacity" -ForegroundColor Green
    Write-Host "2. IIS Show site status" -ForegroundColor Green
    Write-Host "3. Sys Info" -ForegroundColor Green
    Write-Host "4. Change Server" -ForegroundColor Green
    Write-Host "5. Exit" -ForegroundColor Red

    $option = $(Write-Host "Enter option (1-5): " -ForegroundColor Cyan -NoNewLine; Read-Host)

    switch ($option) {
        1 {
            $disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3"
            foreach ($disk in $disks) {
                $capacity = [math]::Round($disk.Size / 1GB, 2)
                $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
                $usedSpace = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                
                # Set colors based on free space
                if ($freeSpace -lt 40) {
                    $freeSpaceColor = "Red"
                } elseif ($freeSpace -lt 80) {
                    $freeSpaceColor = "Yellow"
                } else {
                    $freeSpaceColor = "Green"
                }
                
                # Set colors for used and total space
                $usedSpaceColor = "Cyan"
                $capacityColor = "Green"
                
                Write-Host "$($disk.DeviceID) - Total: $($capacity.ToString('N2')) GB" -ForegroundColor $capacityColor
                Write-Host "Used: $($usedSpace.ToString('N2')) GB" -ForegroundColor $usedSpaceColor
                Write-Host "Free: $($freeSpace.ToString('N2')) GB" -ForegroundColor $freeSpaceColor
                Write-Host ""
            }
        }
        2 {
             Write-Host "Server: $server" -ForegroundColor Yellow
             $appPools = Invoke-Command -ComputerName $server -ScriptBlock {
             Import-Module WebAdministration
             Get-ChildItem IIS:\AppPools | Select-Object -Property Name, State
            }
            $totalAppPools = $appPools.Count
            $currentAppPoolIndex = 0
            foreach ($appPool in $appPools) {
                $appPoolName = $appPool.Name
                $appPoolState = $appPool.State
                if ($appPoolState -eq "Stopped") {
                    $appPoolStateColor = "Red"
                } else {
                    $appPoolStateColor = "Green"
                }
                Write-Host "  $($appPoolName) - $($appPoolState)" -ForegroundColor $appPoolStateColor
                if ($appPool.State -eq "Stopped") {
                    $choice = $(Write-Host "Do you want to start the application pool $($appPoolName)? (Y/N): " -ForegroundColor Cyan -NoNewLine; Read-Host) 
                    if ($choice -eq "Y") {
                        Invoke-Command -ComputerName $server -ScriptBlock {
                            param($appPool)
                            import-Module WebAdministration
                            Start-WebAppPool -Name $appPool
                    } -ArgumentList $appPoolName
                    Write-Host "Application pool $($appPoolName) started." -ForegroundColor Green
                } else {
                    Write-Host "Application pool $($appPoolName) not started." -ForegroundColor Red
                }
            }
          }
        }
        3 {
$choices = @{
    '1' = 'Get-Service';
    '2' = 'Get-Process';
    '3' = 'Get-EventLog';
    '4' = 'Get-NetIPAddress';
    '5' = 'Get-NetAdapter';
    '6' = 'MainMenu';
}

$validChoice = $false

while(-not $validChoice) {
    Write-Host "1. Show Services" -ForegroundColor Green
    Write-Host "2. Show Process" -ForegroundColor Green
    Write-Host "3. Show EventLog" -ForegroundColor Green
    Write-Host "4. Display NetIPAddress" -ForegroundColor Green
    Write-Host "5. Display NetAdapter" -ForegroundColor Green
    Write-Host "6. Back" -ForegroundColor Red

    $choice = $(Write-Host "Enter option (1-7): " -ForegroundColor Cyan -NoNewLine; Read-Host)

    if ($choices.ContainsKey($choice)) {
        $validChoice = $true
        $command = $choices[$choice]
        Invoke-Expression $command 
    } else {
        Write-Host "Invalid choice. Please try again."
    }
   }
 }
        4 {
         $newserver = $(Write-Host "Please Enter New Server-IP: "  -ForegroundColor Cyan -NoNewLine; Read-Host)
         $server = $newserver
         MainMenu
         }
        5 {
            Write-Host "Exiting script."  -ForegroundColor Red
            return
        }
        default {
            Write-Host "Invalid option. Please select a valid option."  -ForegroundColor Red
        }
    }

    $choice = $(Write-Host "Would you like to return to the main menu? (Y/N): "  -ForegroundColor Cyan -NoNewLine; Read-Host) 
    if ($choice -eq "Y") {
        MainMenu
    } else {
        Write-Host "Exiting script." -ForegroundColor Red
        return
    }
}

MainMenu