# Claude Code Status Line for PowerShell
# Displays: Model | Context Usage | Cost | Git Branch | Directory

# Read JSON input from stdin
$inputJson = [Console]::In.ReadToEnd()
$data = $inputJson | ConvertFrom-Json

# Extract model name
$model = $data.model.display_name

# Calculate context window usage percentage
$contextPercent = 0
if ($null -ne $data.context_window.current_usage) {
    $currentTokens = $data.context_window.current_usage.input_tokens +
                     $data.context_window.current_usage.cache_creation_input_tokens +
                     $data.context_window.current_usage.cache_read_input_tokens
    $contextSize = $data.context_window.context_window_size

    if ($contextSize -gt 0) {
        $contextPercent = [math]::Round(($currentTokens / $contextSize) * 100)
    }
}

# Get current directory name
$currentDir = Split-Path -Leaf $data.workspace.current_dir

# Extract session cost
$costUSD = 0.0
if ($null -ne $data.cost -and $null -ne $data.cost.total_cost_usd) {
    $costUSD = $data.cost.total_cost_usd
}
# Format cost as currency (e.g., $0.01)
$costFormatted = '${0:F4}' -f $costUSD

# Get git branch if in a git repo
$gitBranch = ""
$gitPath = Join-Path $data.workspace.current_dir ".git"
if (Test-Path $gitPath) {
    try {
        $headPath = Join-Path $gitPath "HEAD"
        if (Test-Path $headPath) {
            $headContent = Get-Content $headPath -Raw
            if ($headContent -match 'ref: refs/heads/(.+)') {
                $branch = $matches[1].Trim()
                $gitBranch = " | $branch"  # Plain text, no ANSI codes
            }
        }
    } catch {
        # Silently ignore git errors
    }
}

# Build status line without ANSI codes (plain text for better compatibility)
# Add visual indicators for context usage level
$contextIndicator = if ($contextPercent -gt 80) { "!!!" } elseif ($contextPercent -gt 60) { "!!" } else { "" }

# Output status line
Write-Output "[$model] Context: ${contextPercent}%${contextIndicator} | Cost: ${costFormatted} | [${currentDir}]${gitBranch}"
