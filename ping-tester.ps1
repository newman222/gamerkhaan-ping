# --- Fully CMD-Compatible Version with Simple Characters ---

 $servers = @(
    "1.1.1.1",
    "4.2.2.2",
    "eu-epic.gamerkhaan.com",
    "uae-epic.gamerkhaan.com",
    "uae.gamerkhaan.com",
    "eu.gamerkhaan.com"
)

# --- Changed: Updated names and removed [DNS] and <3 ---
 $serverDisplayNames = @{
    "1.1.1.1" = "1.1.1.1"
    "4.2.2.2" = "4.2.2.2"
    "eu-epic.gamerkhaan.com" = "EpicGames EU"
    "uae-epic.gamerkhaan.com" = "EpicGames UAE"
    "uae.gamerkhaan.com" = "GamerKhaan UAE"
    "eu.gamerkhaan.com" = "GamerKhaan EU"
}

 $headerInterval = 15
# --- Changed: Adjusted column width for the new names ---
 $columnWidth = 18

function Write-Header {
    param($Servers, $ColumnWidth, $DisplayNames)
    $serverCount = $Servers.Count
    $i = 0
    foreach ($server in $Servers) {
        $i++
        $displayName = $DisplayNames[$server]
        if (-not $displayName) { $displayName = $server }
        
        $totalPadding = $ColumnWidth - $displayName.Length
        $leftPadding = [math]::Floor($totalPadding / 2)
        $rightPadding = $ColumnWidth - $leftPadding - $displayName.Length
        
        Write-Host (" " * [math]::Max(0, $leftPadding)) -NoNewline

        # --- Changed: Updated color logic for separate name parts ---
        if ($displayName -like "*GamerKhaan*") {
            $parts = $displayName -split ' '
            Write-Host $parts[0] -NoNewline -ForegroundColor White # "GamerKhaan"
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Yellow # "EU" or "UAE"
        } elseif ($displayName -like "*EpicGames*") {
            $parts = $displayName -split ' '
            Write-Host $parts[0] -NoNewline -ForegroundColor Red    # "EpicGames"
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Yellow # "EU" or "UAE"
        } else {
            $headerColor = "Cyan"
            if ($displayName -like "*1.1.1.1*") { $headerColor = "White" }
            elseif ($displayName -like "*4.2.2.2*") { $headerColor = "Magenta" }
            Write-Host $displayName -NoNewline -ForegroundColor $headerColor
        }
        
        # --- Changed: More robust newline handling for CMD ---
        if ($i -eq $serverCount) {
            Write-Host (" " * [math]::Max(0, $rightPadding)) # No -NoNewline for the last item
        } else {
            Write-Host (" " * [math]::Max(0, $rightPadding)) -NoNewline
        }
    }
    Write-Host ("=" * ($ColumnWidth * $Servers.Count)) -ForegroundColor Cyan
}

 $pingData = @{}
foreach ($server in $servers) {
    $pingData[$server] = @{
        Latencies = New-Object System.Collections.Generic.List[int]
        Timeouts = 0
    }
}

 $startTime = Get-Date

Clear-Host
# --- Changed: Removed emojis from the banner ---
Write-Host @"


                                                                                                                                     
                                                                                                                                     
        GGGGGGGGGGGGG               AAA               MMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRRRRRRRRRRR         
     GGG::::::::::::G              A:::A              M:::::::M             M:::::::ME::::::::::::::::::::ER::::::::::::::::R        
   GG:::::::::::::::G             A:::::A             M::::::::M           M::::::::ME::::::::::::::::::::ER::::::RRRRRR:::::R       
  G:::::GGGGGGGG::::G            A:::::::A            M:::::::::M         M:::::::::MEE::::::EEEEEEEEE::::ERR:::::R     R:::::R      
 G:::::G       GGGGGG           A:::::::::A           M::::::::::M       M::::::::::M  E:::::E       EEEEEE  R::::R     R:::::R      
G:::::G                        A:::::A:::::A          M:::::::::::M     M:::::::::::M  E:::::E               R::::R     R:::::R      
G:::::G                       A:::::A A:::::A         M:::::::M::::M   M::::M:::::::M  E::::::EEEEEEEEEE     R::::RRRRRR:::::R       
G:::::G    GGGGGGGGGG        A:::::A   A:::::A        M::::::M M::::M M::::M M::::::M  E:::::::::::::::E     R:::::::::::::RR        
G:::::G    G::::::::G       A:::::A     A:::::A       M::::::M  M::::M::::M  M::::::M  E:::::::::::::::E     R::::RRRRRR:::::R       
G:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A      M::::::M   M:::::::M   M::::::M  E::::::EEEEEEEEEE     R::::R     R:::::R      
G:::::G        G::::G     A:::::::::::::::::::::A     M::::::M    M:::::M    M::::::M  E:::::E               R::::R     R:::::R      
 G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A    M::::::M     MMMMM     M::::::M  E:::::E       EEEEEE  R::::R     R:::::R      
  G:::::GGGGGGGG::::G   A:::::A             A:::::A   M::::::M               M::::::MEE::::::EEEEEEEE:::::ERR:::::R     R:::::R      
   GG:::::::::::::::G  A:::::A               A:::::A  M::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R      
     GGG::::::GGG:::G A:::::A                 A:::::A M::::::M               M::::::ME::::::::::::::::::::ER::::::R     R:::::R      
        GGGGGG   GGGGAAAAAAA                   AAAAAAAMMMMMMMM               MMMMMMMMEEEEEEEEEEEEEEEEEEEEEERRRRRRRR     RRRRRRR      
                                                                                                                                        


                                                                                                                                                                                                                                                                       
KKKKKKKKK    KKKKKKKHHHHHHHHH     HHHHHHHHH               AAA                              AAA               NNNNNNNN        NNNNNNNN
K:::::::K    K:::::KH:::::::H     H:::::::H              A:::A                            A:::A              N:::::::N       N::::::N
K:::::::K    K:::::KH:::::::H     H:::::::H             A:::::A                          A:::::A             N::::::::N      N::::::N
K:::::::K   K::::::KHH::::::H     H::::::HH            A:::::::A                        A:::::::A            N:::::::::N     N::::::N
KK::::::K  K:::::KKK  H:::::H     H:::::H             A:::::::::A                      A:::::::::A           N::::::::::N    N::::::N
  K:::::K K:::::K     H:::::H     H:::::H            A:::::A:::::A                    A:::::A:::::A          N:::::::::::N   N::::::N
  K::::::K:::::K      H::::::HHHHH::::::H           A:::::A A:::::A                  A:::::A A:::::A         N:::::::N::::N  N::::::N
  K:::::::::::K       H:::::::::::::::::H          A:::::A   A:::::A                A:::::A   A:::::A        N::::::N N::::N N::::::N
  K:::::::::::K       H:::::::::::::::::H         A:::::A     A:::::A              A:::::A     A:::::A       N::::::N  N::::N:::::::N
  K::::::K:::::K      H::::::HHHHH::::::H        A:::::AAAAAAAAA:::::A            A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::N
  K:::::K K:::::K     H:::::H     H:::::H       A:::::::::::::::::::::A          A:::::::::::::::::::::A     N::::::N    N::::::::::N
KK::::::K  K:::::KKK  H:::::H     H:::::H      A:::::AAAAAAAAAAAAA:::::A        A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N
K:::::::K   K::::::KHH::::::H     H::::::HH   A:::::A             A:::::A      A:::::A             A:::::A   N::::::N      N::::::::N
K:::::::K    K:::::KH:::::::H     H:::::::H  A:::::A               A:::::A    A:::::A               A:::::A  N::::::N       N:::::::N
K:::::::K    K:::::KH:::::::H     H:::::::H A:::::A                 A:::::A  A:::::A                 A:::::A N::::::N        N::::::N
KKKKKKKKK    KKKKKKKHHHHHHHHH     HHHHHHHHHAAAAAAA                   AAAAAAAAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN
                                                                                                                                     
                                                                                                                                     
                                                                                                                                     
                                                                                                                                     
                                                                                                                                     
                                                                                                                                     
                                                                                                                                                                   
                                                      
GamerKhaan Ping Monitor - Online Gaming Perfected!
"@ -ForegroundColor Cyan
Write-Host "Quest started at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames
Write-Host "Pinging servers in 2 seconds... Get ready!" -ForegroundColor Gray

 $runspacePool = $null
try {
    $runspacePool = [RunspaceFactory]::CreateRunspacePool(1, [int]$servers.Count)
    $runspacePool.Open()
    $rowCounter = 0
    while ($true) {
        $runspaces = @()
        foreach ($server in $servers) {
            $powershell = [PowerShell]::Create().AddScript({
                param($ServerName)
                Test-Connection -ComputerName $ServerName -Count 1 -ErrorAction SilentlyContinue
            }).AddParameter("ServerName", $server)
            $powershell.RunspacePool = $runspacePool
            $runspaces += [PSCustomObject]@{
                Server = $server
                PowerShell = $powershell
                Result = $powershell.BeginInvoke()
            }
        }
        $currentPingResults = @{}
        foreach ($runspace in $runspaces) {
            if ($runspace.Result.AsyncWaitHandle.WaitOne(1500)) {
                $pingResult = $runspace.PowerShell.EndInvoke($runspace.Result)
                $latency = if ($pingResult) { $pingResult.ResponseTime } else { "Timeout" }
            } else {
                $latency = "Timeout"
                try { $runspace.PowerShell.EndInvoke($runspace.Result) } catch { }
            }
            $currentPingResults[$runspace.Server] = $latency
            $runspace.PowerShell.Dispose()
        }
        
        $serverCount = $servers.Count
        $i = 0
        foreach ($server in $servers) {
            $i++
            $latency = $currentPingResults[$server]
            $serverData = $pingData[$server]
            if ($latency -eq "Timeout") {
                $serverData.Timeouts++
                $text = "Timeout!"
                $latencyText = $text
                $msText = ""
            } else {
                $serverData.Latencies.Add([int]$latency)
                $latencyText = [string]$latency
                $msText = "ms"
            }
            
            $color = "White"
            if ($latency -eq "Timeout") {
                $color = "Red"
            } else {
                if ($server -like "*uae*") {
                    if ($latency -lt 75) { $color = "Green" }
                    elseif ($latency -le 100) { $color = "Yellow" }
                    else { $color = "Red" }
                } else {
                    if ($latency -lt 110) { $color = "Green" }
                    elseif ($latency -le 135) { $color = "Yellow" }
                    else { $color = "Red" }
                }
            }
            
            $fullText = $latencyText + $msText
            $padding = ($columnWidth - $fullText.Length) / 2
            $leftPadding = [math]::Floor($padding)
            $rightPadding = [math]::Ceiling($padding)
            
            Write-Host (" " * [math]::Max(0, $leftPadding)) -NoNewline
            Write-Host $latencyText -NoNewline -ForegroundColor $color
            if ($msText) {
                # --- Changed: ms text color to Red ---
                Write-Host $msText -NoNewline -ForegroundColor Red
            }
            
            # --- Changed: More robust newline handling for CMD ---
            if ($i -eq $serverCount) {
                Write-Host (" " * [math]::Max(0, $rightPadding)) # No -NoNewline for the last item
            } else {
                Write-Host (" " * [math]::Max(0, $rightPadding)) -NoNewline
            }
        }
        
        $rowCounter++
        if ($rowCounter -eq 1 -or $rowCounter % $headerInterval -eq 0) {
            Write-Host ""
            Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames
        }
        Start-Sleep -Milliseconds 500
    }
}
finally {
    $endTime = Get-Date
    $duration = $endTime - $startTime
    if ($runspacePool -ne $null) {
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    Write-Host "`nQuest completed!" -ForegroundColor Yellow
    Write-Host "Total playtime: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    Write-Host "`n==================== Summary ====================" -ForegroundColor Cyan
    foreach ($server in $servers) {
        $displayName = $serverDisplayNames[$server]
        if (-not $displayName) { $displayName = $server }
        $data = $pingData[$server]
        $totalPings = $data.Latencies.Count + $data.Timeouts
        if ($totalPings -eq 0) {
            # --- Changed: Using color pattern for server name here too ---
            if ($displayName -like "*GamerKhaan*") {
                $parts = $displayName -split ' '
                Write-Host $parts[0] -NoNewline -ForegroundColor White
                Write-Host " " -NoNewline
                Write-Host $parts[1] -NoNewline -ForegroundColor Yellow
            } elseif ($displayName -like "*EpicGames*") {
                $parts = $displayName -split ' '
                Write-Host $parts[0] -NoNewline -ForegroundColor Red
                Write-Host " " -NoNewline
                Write-Host $parts[1] -NoNewline -ForegroundColor Yellow
            } else {
                $headerColor = "Cyan"
                if ($displayName -like "*1.1.1.1*") { $headerColor = "White" }
                elseif ($displayName -like "*4.2.2.2*") { $headerColor = "Magenta" }
                Write-Host $displayName -NoNewline -ForegroundColor $headerColor
            }
            Write-Host ": No pings logged." -ForegroundColor Gray
            continue
        }
        $packetLoss = [math]::Round(($data.Timeouts / $totalPings) * 100, 2)
        $packetLossDisplay = "{0:0.0}" -f $packetLoss
        $packetLossColor = if ($packetLoss -eq 0) { "Green" } else { "Red" }
        # --- Changed: Removed [OK] and [LOSS] icons ---
        
        if ($data.Latencies.Count -gt 0) {
            $min = ($data.Latencies | Measure-Object -Minimum).Minimum
            $max = ($data.Latencies | Measure-Object -Maximum).Maximum
            $avg = [math]::Round(($data.Latencies | Measure-Object -Average).Average, 2)
            if ($server -like "*uae*") {
                $minColor = if ($min -lt 75) { "Green" } elseif ($min -le 100) { "Yellow" } else { "Red" }
                $maxColor = if ($max -lt 75) { "Green" } elseif ($max -le 100) { "Yellow" } else { "Red" }
                $avgColor = if ($avg -lt 75) { "Green" } elseif ($avg -le 100) { "Yellow" } else { "Red" }
            } else {
                $minColor = if ($min -lt 110) { "Green" } elseif ($min -le 135) { "Yellow" } else { "Red" }
                $maxColor = if ($max -lt 110) { "Green" } elseif ($max -le 135) { "Yellow" } else { "Red" }
                $avgColor = if ($avg -lt 110) { "Green" } elseif ($avg -le 135) { "Yellow" } else { "Red" }
            }
            $minIcon = "[MIN]"
            $maxIcon = "[MAX]"
            $avgIcon = "[AVG]"
        } else {
            $min = "N/A"
            $max = "N/A"
            $avg = "N/A"
            $minColor = "Gray"
            $maxColor = "Gray"
            $avgColor = "Gray"
            $minIcon = ""
            $maxIcon = ""
            $avgIcon = ""
        }
        
        # --- Changed: Using color pattern for server name here too ---
        if ($displayName -like "*GamerKhaan*") {
            $parts = $displayName -split ' '
            Write-Host $parts[0] -NoNewline -ForegroundColor White
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Yellow
        } elseif ($displayName -like "*EpicGames*") {
            $parts = $displayName -split ' '
            Write-Host $parts[0] -NoNewline -ForegroundColor Red
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Yellow
        } else {
            $headerColor = "Cyan"
            if ($displayName -like "*1.1.1.1*") { $headerColor = "White" }
            elseif ($displayName -like "*4.2.2.2*") { $headerColor = "Magenta" }
            Write-Host $displayName -NoNewline -ForegroundColor $headerColor
        }
        Write-Host ":" -ForegroundColor White
        Write-Host "  Packet Loss: " -NoNewline -ForegroundColor Gray
        # --- Changed: Removed icon from this line ---
        Write-Host "$packetLossDisplay%" -ForegroundColor $packetLossColor
        Write-Host "  Min Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $min -NoNewline -ForegroundColor $minColor
        Write-Host " " -NoNewline
        # --- Changed: ms color to Red, icon color to Green ---
        Write-Host "ms " -NoNewline -ForegroundColor Red
        Write-Host $minIcon -ForegroundColor Green
        Write-Host "  Max Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $max -NoNewline -ForegroundColor $maxColor
        Write-Host " " -NoNewline
        # --- Changed: ms color to Red, icon color to Red ---
        Write-Host "ms " -NoNewline -ForegroundColor Red
        Write-Host $maxIcon -ForegroundColor Red
        Write-Host "  Avg Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $avg -NoNewline -ForegroundColor $avgColor
        Write-Host " " -NoNewline
        # --- Changed: ms color to Red, icon color to Yellow ---
        Write-Host "ms " -NoNewline -ForegroundColor Red
        Write-Host $avgIcon -ForegroundColor Yellow
        Write-Host ""
    }
    Write-Host "=================================================" -ForegroundColor Cyan
    # --- Changed: Removed emoji from final message ---
    Write-Host "Thanks for playing Games!" -ForegroundColor Green
}
