param (
    [string]$Letter
)

Write-Host "Long-running job for letter '$Letter' started..."

# Simulate long-running task (replace with your actual task)
Start-Sleep -Seconds 60

Write-Host "Long-running job for letter '$Letter' completed."
