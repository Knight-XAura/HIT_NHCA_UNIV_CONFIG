# Check if script is running as an Administrator, if not rerun the script as Administartor
##Requires -RunAsAdministrator

Write-Host $PID
read-host
# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "Running without administrative privileges. Attempting to elevate..."
    Start-Sleep -Seconds 1

    # Re-launch the script with elevated privileges
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Your elevated code goes here
Write-Host "Running with administrative privileges!"
Start-Sleep -Seconds 1

# Set the Execution Policy to allow the script to run
Set-ExecutionPolicy -ExecutionPolicy Bypass # Current Script Execution Policy only

# Change directories to the folder this script exists in
cd $PSScriptRoot

# Call functions.ps1 to pair the heart of our code with the brains
. .\functions.ps1

# Check Folder Exist in C: and if not then Copy folder, if failed then ask to try again or close the script
if ($PSScriptRoot -ne "C:\HIT_NHCA_UNIV_CONFIG") {
    while (-not $isSuccessful) {
        try {
            # Perform the copy operation recursively and preserve attributes
            Copy-Item -Path . -Destination C:\ -Recurse -Force

            Write-Host "Files copied successfully to: C:\HIT_NHCA_UNIV_CONFIG"
            $isSuccessful = $true
        }
        catch {
            # If the copy operation fails, display a warning message
            Write-Host "Failed to copy files. Error: $_"

            # Ask if the user wants to try again
            $isRetrying = Read-Host "Do you want to try again? (Yes/No)"
            if ($isRetrying -ne "Yes") {
                $isSuccessful = $false
            }

            else {
                return # Exits if the user doesn't want to retry and keeps from deleting files - This is for making troubleshooting much easier
            }

            # Delete the destination folder if it exists before retrying
            if (Test-Path -Path C:\HIT_NHCA_UNIV_CONFIG -PathType Container) {
                Remove-Item -Path C:\HIT_NHCA_UNIV_CONFIG -Recurse -Force
            }
        }
        # Define the path to the script in the other location
        $scriptPath = "C:\HIT_NHCA_UNIV_CONFIG\logic.ps1"

        # Rerun the script from the specified location
        Start-Process -UseNewEnvironment -RedirectStandardError "C:\output.txt" -FilePath "powershell.exe" -ArgumentList "-File '$scriptPath'"

        # Close the current script
        Stop-Process -Id $PID

    }
}

# Get Stage script was on
$stage = (Get-ItemProperty -Path "HKLM:\Software\HNUC" -Name "Stage" -ErrorAction SilentlyContinue).Stage











































$CT_ARange = 1..4
while ($CT_ARange -notcontains $ConfigType) {
	$ConfigType = Read-Host "Submit the number associated with the configuration process you'd like to use:`n1. Pre-Config, 2. Post Config, 3. Full Config, 4. Repair Menu"
}

If (1 -contains $ConfigType) {
	$CS_ARange = 1..2
	While ($CS_ARange -notcontains $ConfigStage) {
		$ConfigStage = Read-Host "Submit the number associated with the Config Stage you are at:`n1. Pre-Domain and 2. Post Domain"
	}
}

$DT_ARange = 1..2
while ($DT_ARange -notcontains $DeviceType) {
	$DeviceType = Read-Host "Submit the number associated with the type of machine:`n1. Laptop and 2. Desktop"
}

if ($DeviceType -eq "1") {
	$isLaptop = $true
}

$CL_ARange = 1..2
while ($CL_ARange -notcontains $ConfigLocation) {
	$ConfigLocation = Read-Host "Submit the number associated with the Location of the machine:`n1. Onsite and 2. Remote"
}

if ($ConfigLocation -eq "2") {
	$isRemote = $true
}