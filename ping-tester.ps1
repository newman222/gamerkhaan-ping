 $servers = @(
    "1.1.1.1",
    "4.2.2.2",
    "eu-epic.gamerkhaan.com",
    "uae-epic.gamerkhaan.com",
    "uae.gamerkhaan.com",
    "eu.gamerkhaan.com"
)

# Updated display names to use a space for better color splitting
 $serverDisplayNames = @{
    "1.1.1.1" = "🌐 1.1.1.1"
    "4.2.2.2" = "🌐 4.2.2.2"
    "eu-epic.gamerkhaan.com" = "🎮 EpicGames EU"
    "uae-epic.gamerkhaan.com" = "🎮 EpicGames UAE"
    "uae.gamerkhaan.com" = "🕹️ GamerKhaan UAE"
    "eu.gamerkhaan.com" = "🕹️ GamerKhaan EU"
}

 $headerInterval = 15
 $columnWidth = 20  # Increased a bit for emojis

function Write-Header {
    param($Servers, $ColumnWidth, $DisplayNames)
    foreach ($server in $Servers) {
        $displayName = $DisplayNames[$server]
        if (-not $displayName) { $displayName = $server }
        
        # Calculate padding for the entire display name
        $totalPadding = $ColumnWidth - $displayName.Length
        $leftPadding = [math]::Floor($totalPadding / 2)
        $rightPadding = $ColumnWidth - $leftPadding - $displayName.Length
        Write-Host (" " * $leftPadding) -NoNewline

        # --- Color Logic ---
        if ($displayName -like "*GamerKhaan*") {
            # Splits "🕹️ GamerKhaan UAE" into parts
            $parts = $displayName -split ' ', 3
            Write-Host $parts[0] -NoNewline # Emoji
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Yellow # "GamerKhaan"
            Write-Host " " -NoNewline
            Write-Host $parts[2] -NoNewline -ForegroundColor White  # "EU" or "UAE"
        } elseif ($displayName -like "*EpicGames*") {
            # Splits "🎮 EpicGames EU" into parts
            $parts = $displayName -split ' ', 3
            Write-Host $parts[0] -NoNewline # Emoji
            Write-Host " " -NoNewline
            Write-Host $parts[1] -NoNewline -ForegroundColor Red    # "EpicGames"
            Write-Host " " -NoNewline
            Write-Host $parts[2] -NoNewline -ForegroundColor White  # "EU" or "UAE"
        } else {
            # Default coloring for public DNS servers
            $headerColor = "Cyan"
            if ($displayName -like "*1.1.1.1*") { $headerColor = "White" }
            elseif ($displayName -like "*4.2.2.2*") { $headerColor = "Magenta" }
            Write-Host $displayName -NoNewline -ForegroundColor $headerColor
        }
        # --- End Color Logic ---
        
        Write-Host (" " * $rightPadding) -NoNewline
    }
    Write-Host ""
    Write-Host ("═" * ($ColumnWidth * $Servers.Count)) -ForegroundColor Cyan
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
Write-Host @"
   ___           ___           ___      
  /  /\         /  /\         /  /\     
 /  /:/_       /  /:/        /  /:/_    
/  /:/ /\     /  /:/        /  /:/ /\   
/  /:/ /:/_   /  /:/  ___   /  /:/ /::\  
/__/: /:/ /\ /__/:/  /  /\ /__/:/ /:/:\ 
/  /:/ /:/  \  \:\ /  /:/ \  \:\/:/~/:/
/__/:/ /:/    \  \:\  /:/   \  \::/ /:/
/  /:/ /:/      \  \:\/:/     \__\/ /:/
/__/:/ /:/       \  \::/        /__/: /
\__\/  \:\        \__\/         \__\/ :
    \  \:\                       /__/ /
     \__\/                       \__\/ 

GamerKhaan Ping Monitor - Level Up Your Connection! 🎉
"@ -ForegroundColor Cyan
Write-Host "Quest started at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames
Write-Host "Pinging servers in 2 seconds... Get ready! 🚀" -ForegroundColor Gray
Start-Sleep -Seconds 2

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
        foreach ($server in $servers) {
            $latency = $currentPingResults[$server]
            $serverData = $pingData[$server]
            if ($latency -eq "Timeout") {
                $serverData.Timeouts++
            } else {
                $serverData.Latencies.Add([int]$latency)
            }
            $color = "White"
            if ($latency -eq "Timeout") {
                $text = "Timeout ⚠️"
                $latencyText = $text
                $msText = ""
            } else {
                $latencyText = [string]$latency
                $msText = " ms"
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
            Write-Host (" " * $leftPadding) -NoNewline
            Write-Host $latencyText -NoNewline -ForegroundColor $color
            if ($msText) {
                Write-Host "ms" -NoNewline -ForegroundColor Magenta
            }
            Write-Host (" " * $rightPadding) -NoNewline
        }
        Write-Host ""
        $rowCounter++
        if ($rowCounter -eq 1 -or $rowCounter % $headerInterval -eq 0) {
            Write-Host ""
            Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames
        }
        Start-Sleep -Milliseconds 500  # Smoother update
    }
}
finally {
    $endTime = Get-Date
    $duration = $endTime - $startTime
    if ($runspacePool -ne $null) {
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    Write-Host "`nQuest completed! Ping monitor stopped." -ForegroundColor Yellow
    Write-Host "Total playtime: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Gray
    Write-Host "`n==================== Epic Summary ====================" -ForegroundColor Cyan
    foreach ($server in $servers) {
        $displayName = $serverDisplayNames[$server]
        if (-not $displayName) { $displayName = $server }
        $data = $pingData[$server]
        $totalPings = $data.Latencies.Count + $data.Timeouts
        if ($totalPings -eq 0) {
            Write-Host "${displayName}: No pings logged. 😔" -ForegroundColor Gray
            continue
        }
        $packetLoss = [math]::Round(($data.Timeouts / $totalPings) * 100, 2)
        $packetLossDisplay = "{0:0.0}" -f $packetLoss
        $packetLossColor = if ($packetLoss -eq 0) { "Green" } else { "Red" }
        $lossIcon = if ($packetLoss -eq 0) { "✅" } else { "❌" }
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
            $minIcon = "🏆"
            $maxIcon = "⚡"
            $avgIcon = "📊"
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
        Write-Host $displayName -NoNewline -ForegroundColor Cyan
        Write-Host ":" -ForegroundColor White
        Write-Host "  Packet Loss: " -NoNewline -ForegroundColor Gray
        Write-Host "$packetLossDisplay% $lossIcon" -ForegroundColor $packetLossColor
        Write-Host "  Min Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $min -NoNewline -ForegroundColor $minColor
        Write-Host " " -NoNewline
        Write-Host "ms $minIcon" -ForegroundColor Magenta
        Write-Host "  Max Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $max -NoNewline -ForegroundColor $maxColor
        Write-Host " " -NoNewline
        Write-Host "ms $maxIcon" -ForegroundColor Magenta
        Write-Host "  Avg Ping: " -NoNewline -ForegroundColor Gray
        Write-Host $avg -NoNewline -ForegroundColor $avgColor
        Write-Host " " -NoNewline
        Write-Host "ms $avgIcon" -ForegroundColor Magenta
        Write-Host ""
    }
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "Online Gaming Perfected ! 💪" -ForegroundColor Green
}
