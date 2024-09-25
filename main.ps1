param (
    [string]$ScheduleFile = "/app/schedule.json",  # Default schedule file path
    [bool]$IsDevelopment = $true,                 # Flag for development mode
	[int]$IntervalInSeconds = 10
)

# Path to the job script
$jobScript = "./job.ps1"

# Function to check if the current time matches any scheduled time
function IsTimeToRun {
    param (
        [string[]]$times
    )

    $currentTime = (Get-Date).ToString("HH:mm")
    return $times -contains $currentTime
}

# Function to generate a development schedule with each letter starting from the current time
function GetDevelopmentSchedule {
    param (
        [array]$letters
    )

    $schedule = @()
    $startTime = Get-Date
    $i = 0

    foreach ($letter in $letters) {
        # Create a time for each letter, starting from the current time and adding a minute for each subsequent letter
        $time = ($startTime.AddMinutes($i)).ToString("HH:mm")
        $schedule += @{ letter = $letter; times = @($time) }
        $i++
    }

    return $schedule
}

function IsJobRunning {
    param (
        [string]$jobName
    )

	$job = Get-Job | Where-Object { $_.Name -eq $jobName -and $_.State -eq "Running" }

	if ($job -eq $null) {
		return $false
	}

	return $true
}

# Retrieve the schedule at the start based on development or production mode
if ($IsDevelopment) {
    # Development mode: create dynamic times starting from now, spaced one minute apart
    $letters = "a".."z"
    $schedule = GetDevelopmentSchedule $letters
} else {
    # Production mode: load the schedule from the JSON file
    if (Test-Path $ScheduleFile) {
        $schedule = Get-Content $ScheduleFile | ConvertFrom-Json
    } else {
        Write-Host "Schedule file not found."
        exit 1
    }
}

# Infinite loop to check periodically
while ($true) {
    Write-Host "Checking schedule..."

    # Check and handle any completed jobs
    $completedJobs = Get-Job | Where-Object { $_.State -eq 'Completed' }
    foreach ($job in $completedJobs) {
        Write-Host "'$($job.Name)' completed."
        $result = Receive-Job -Job $job
		Write-host "'$($job.Name)' received."
        Remove-Job -Job $job
        Write-Host "'$($job.Name)' removed."
    }

    # Loop through each scheduled letter
    foreach ($item in $schedule) {
        $letter = $item.letter
        $times = $item.times
		$jobName = "UserSync-$letter"

		if (IsJobRunning $jobName) {
			Write-Host "'$jobName' already running." 
			continue;
		}

        # Check if the current time matches any scheduled time for this letter
        if (IsTimeToRun $times) {
            Write-Host "'$jobName' starting."

            # Start the job script in the background with the letter as a parameter
            Start-Job -FilePath $jobScript -ArgumentList $letter -Name $jobName | Out-Null

            Write-Host "'$jobName' started."
        }
    }

    # Sleep for specified interval before checking again
    Start-Sleep -Seconds $IntervalInSeconds
}
