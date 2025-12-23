# =================================================================================
# Gamer's Real-Time Server Ping Monitor (Columnar Log with Periodic Headers)
#
# DESCRIPTION:
# This script continuously pings a list of game servers and DNS resolvers, 
# and appends results as a new row in a column-based, scrollable log 
# with custom colors and names.
#
# USAGE:
# 1. Run this script in a PowerShell terminal.
# 2. The headers will appear, and script will pause for 2 seconds.
# 3. The first line of ping data will appear, followed by another header.
# 4. From then on, new rows are added, and headers appear every 25 lines.
# 5. Press CTRL+C to stop script.
#
# TIP:
# To see more history, right-click the PowerShell title bar -> Properties ->
# Layout tab -> increase the "Screen Buffer Size" Height.
# =================================================================================

# --- CONFIGURATION ---
# Add or remove server names from this list, in the desired order
 $servers = @(
    "1.1.1.1",
    "4.2.2.2",
    "eu-epic.gamerkhaan.com",
    "uae-epic.gamerkhaan.com",
    "uae.gamerkhaan.com",
    "eu.gamerkhaan.com"
)

# Mapping of full server names to shorter, cleaner display names
 $serverDisplayNames = @{
    "1.1.1.1"                  = "1.1.1.1"
    "4.2.2.2"                  = "4.2.2.2"
    "eu-epic.gamerkhaan.com" = "EpicGames-EU"
    "uae-epic.gamerkhaan.com" = "EpicGames-UAE"
    "uae.gamerkhaan.com"       = "Gamerkhaan-UAE"
    "eu.gamerkhaan.com"       = "Gamerkhaan-EU"
}

# Number of rows of ping data to show before reprinting the headers (after the first run)
 $headerInterval = 15

# --- SCRIPT ---

# Define a fixed width for each column. Reduced for tighter spacing.
 $columnWidth = 18

# A helper function to print the headers to avoid code duplication
function Write-Header {
    param($Servers, $ColumnWidth, $DisplayNames)
    # Print the server names as headers
    foreach ($server in $Servers) {
        $displayName = $DisplayNames[$server]
        if (-not $displayName) {
            $displayName = $server
        }

        # Calculate padding to center the entire display name
        $totalPadding = $ColumnWidth - $displayName.Length
        $leftPadding = [math]::Floor($totalPadding / 2)
        $rightPadding = $ColumnWidth - $leftPadding - $displayName.Length

        # Write the left padding
        Write-Host (" " * $leftPadding) -NoNewline

        # --- Write of name parts with different colors ---
        if ($displayName -like "*Gamerkhaan*") {
            $prefix = "Gamerkhaan-"
            $suffix = $displayName.Substring($prefix.Length)
            Write-Host $prefix -NoNewline -ForegroundColor Red
            Write-Host $suffix -NoNewline -ForegroundColor White
        }
        elseif ($displayName -like "*EpicGames*") {
            $prefix = "EpicGames-"
            $suffix = $displayName.Substring($prefix.Length)
            Write-Host $prefix -NoNewline -ForegroundColor Yellow
            Write-Host $suffix -NoNewline -ForegroundColor White
        }
        else {
            # For other servers (like 1.1.1.1), use the old logic
            $headerColor = "White"
            if ($displayName -eq "1.1.1.1") { $headerColor = "White" }
            elseif ($displayName -eq "4.2.2.2") { $headerColor = "Magenta" }
            Write-Host $displayName -NoNewline -ForegroundColor $headerColor
        }

        # Write the right padding
        Write-Host (" " * $rightPadding) -NoNewline
    }
    Write-Host "" # Move to the next line after printing all headers
    # Print a separator line
    Write-Host ("-" * ($ColumnWidth * $Servers.Count)) -ForegroundColor Gray
}

# --- Step 1: Print the Header and Pause ---
Clear-Host
Write-Host "==================== Gamer Server Ping Monitor (Columns) ====================" -ForegroundColor Cyan
Write-Host "Monitoring started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "" # Add a blank line for spacing

# Print the initial header
Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames

# Add a small pause to let the user see the header before the pings start
Write-Host "Starting pings in 2 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 1

# --- Step 2: Start the Main Ping Loop ---
# It's good practice to clean up the runspace pool when the script is stopped
 $runspacePool = $null
try {
    # Create a Runspace Pool to run scripts in parallel
    $runspacePool = [RunspaceFactory]::CreateRunspacePool(1, [int]$servers.Count)
    $runspacePool.Open()

    # Initialize a counter for the rows
    $rowCounter = 0

    # This is the main loop that keeps the pings running
    while ($true) {
        # --- Step 2a: Kick off all ping jobs in parallel ---
        $runspaces = @()
        foreach ($server in $servers) {
            $powershell = [PowerShell]::Create().AddScript({
                param($ServerName)
                # Send one ping. -ErrorAction SilentlyContinue hides red text for timeouts.
                Test-Connection -ComputerName $ServerName -Count 1 -ErrorAction SilentlyContinue
            }).AddParameter("ServerName", $server)
            
            $powershell.RunspacePool = $runspacePool
            $runspaces += [PSCustomObject]@{
                Server = $server
                PowerShell = $powershell
                Result = $powershell.BeginInvoke()
            }
        }

        # --- Step 2b: Wait for all jobs to complete with a timeout ---
        $currentPingResults = @{}
        foreach ($runspace in $runspaces) {
            # --- FIX: Wait for a maximum of 1500ms for each ping to complete ---
            if ($runspace.Result.AsyncWaitHandle.WaitOne(1500)) {
                # It completed in time, get the result
                $pingResult = $runspace.PowerShell.EndInvoke($runspace.Result)
                $latency = if ($pingResult) { $pingResult.ResponseTime } else { "Timeout" }
            } else {
                # It timed out, set latency to "Timeout"
                $latency = "Timeout"
                # We still need to call EndInvoke to clean up, but it might throw an error
                try { $runspace.PowerShell.EndInvoke($runspace.Result) } catch { }
            }
            # Store results in a hash table for easy lookup
            $currentPingResults[$runspace.Server] = $latency
            $runspace.PowerShell.Dispose()
        }

        # --- Step 2c: Display the new results as a single row ---
        foreach ($server in $servers) {
            $latency = $currentPingResults[$server]
            
            # --- UPDATED: UNIVERSAL COLOR LOGIC ---
            $color = "White" # Default color
            $text = "$latency ms"

            if ($latency -eq "Timeout") {
                $color = "White"
                $text = "Timeout"
            }
            elseif ($latency -lt 75) {
                $color = "Green"
            }
            elseif ($latency -ge 75 -and $latency -le 110) {
                $color = "DarkYellow"
            }
            elseif ($latency -gt 110) {
                $color = "Red"
            }
            
            # Center the text within the full column width to ensure alignment
            $padding = ($columnWidth - $text.Length) / 2
            $leftPadding = [math]::Floor($padding)
            $rightPadding = [math]::Ceiling($padding)
            $outputText = (" " * $leftPadding) + $text + (" " * $rightPadding)
            
            Write-Host $outputText -NoNewline -ForegroundColor $color
        }
        
        Write-Host "" # Move to the next line for the next round of pings
        $rowCounter++

        # --- Reprint headers after the first line, and then periodically ---
        if ($rowCounter -eq 1 -or $rowCounter % $headerInterval -eq 0) {
            Write-Host "" # Add a little space before the next header block
            Write-Header -Servers $servers -ColumnWidth $columnWidth -DisplayNames $serverDisplayNames
        }

        # Wait for 0.55 seconds before the next round of pings
        Start-Sleep -Seconds 0.55
    }
}
finally {
    # This block runs when you press CTRL+C to ensure the pool is closed properly
    if ($runspacePool -ne $null) {
        $runspacePool.Close()
        $runspacePool.Dispose()
        Write-Host "`nPing monitor stopped. Runspace pool closed." -ForegroundColor Yellow
    }
}
