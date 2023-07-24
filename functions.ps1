### Heart of Configuration Script ###

### Do System Checks and Find where the script should start ###

### 0.1 

### 1.1 Set System Power Settings ###

function Change-SystemTimeoutStart {
	Powercfg /Change monitor-timeout-ac 0
	Powercfg /Change monitor-timeout-dc 0
	Powercfg /Change standby-timeout-ac 0
	Powercfg /Change standby-timeout-dc 0

}

### 1.2 Check Enclosure Type ###

function Get-ComputerType {
    $desktopChassisTypes = @(3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21)

    $systemEnclosure = Get-WmiObject Win32_SystemEnclosure

    if ($desktopChassisTypes -contains $systemEnclosure.ChassisTypes[0]) {
        return "Desktop"
    }
    else {
        return Check-PluggedIn
    }
}

### 1.3 Check Battery Status ###

function Get-BatteryStatus {
    $batteryReport = Get-WmiObject Win32_Battery
    if ($batteryReport) {
        $status = $batteryReport.EstimatedChargeRemaining
        $percentage = $batteryReport.EstimatedChargeRemaining
        $powerStatus = $batteryReport.PowerOnline

        # Convert status to text representation
        $statusText = switch ($status) {
            2 { "Fully Charged" }
            3 { "Discharging" }
            4 { "Charging" }
            5 { "Waiting for Charging" }
            6 { "Waiting for Discharging" }
            default { "Check Status Manually" }
        }
    }
    else {
        Write-Host "Battery information not available. Please check manually"
        Read-Host
    }

    if ($batteryReport) {
        Write-Host "Battery Status: $($batteryReport.Status)"
        Write-Host "Battery Percentage: $($batteryReport.Percentage)%"

        if ($batteryReport.Percentage -lt 50 -and -not $batteryReport.PowerStatus) {
            Write-Host "Battery is less than 50% and not plugged in."
            Read-Host "Press Enter to continue..."
        }
    }
}

### 1.4 Create Variable Persistent between reboots  ###

function Add-StageKey {
   if (Test-Path -Path "HKLM:\Software\HNUC") {
        # Define the name and value of the persistent variable
        $variableName = "Stage"
        $variableValue = "0"

        # Retrieve the value of the persistent variable
        $existingValue = Get-ItemProperty -Path "HKLM:\Software\HNUC" -Name $variableName | Select-Object -ExpandProperty $variableName

        # Check if the persistent variable exists and display its value
        if ($existingValue) {
            # Create or update the variable in the Windows Registry
            New-ItemProperty -Path "HKLM:\Software\HNUC" -Name $variableName -Value $variableValue -PropertyType String -Force
        } else {
            Write-Host "Persistent variable '$variableName' exists, but its value is empty."
        }
    }
}



### Download and Install/Uninstall Software ###

### 2.1 Determine Local or Internet for small downloads ### # Is this really needed?



### 2.2. Queue Internet Software Downloads ###

function Add-SoftwareDownloadQueue {
	Start-BitsTransfer -DisplayName "OpenVPN" -Source https://openvpn.net/downloads/openvpn-connect-v3-windows.msi -Destination .\HIT_NHCA_Downloads\VPN\OpenVPN.msi -Asynchronous -Priority Foreground
	# Start-BitsTransfer -DisplayName "Ninite" -Source https://ninite.com/7zip-chrome/ninite.exe -Destination .\HIT_NHCA_Downloads\Ninite.exe -Asynchronous -Priority Foreground
	Start-BitsTransfer -DisplayName "Adobe" -Source http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320064/AcroRdrDC2001320064_en_US.exe -Destination .\HIT_NHCA_Downloads\Adobe_Reader_DC.exe -Asynchronous -Priority Foreground
}

### 2.3. Check Transfers and run complete ###

function Check-SoftwareDownloadQueue {
	Start Powershell {
		While (Get-BitsTransfer) {
			Get-BitsTransfer | ForEach-Object {Get-BitsTransfer | Where JobState -eq "Transferred" | Complete-BitsTransfer}
			Get-BitsTransfer | ForEach-Object {Get-BitsTransfer | Where JobState -eq "TransientError" | Resume-BitsTransfer}
			Get-BitsTransfer | ForEach-Object {Get-BitsTransfer | Where JobState -eq "TransientError" | Start-BitsTransfer}
			Get-BitsTransfer | ForEach-Object {Get-BitsTransfer | Where JobState -eq "Suspended" | Resume-BitsTransfer}
			Get-BitsTransfer
			Start-Sleep -s 15
		}
	}
}

### 2.1. Uninstall Office ### # Need to test downloading this and find how to retrieve script and then can uninstall office that way making the transfer smaller, yet if that don't work this is small to begin with

function Remove-Office {
	<# Start Powershell {
		do {
			Start-Sleep -s 5
		}

		until (Test-Path -Path .\HIT_NHCA_Downloads\3rd_Party_Scripts\Uninstall_O365.vbs -PathType Leaf)

		.\HIT_NHCA_Downloads\3rd_Party_Scripts\Uninstall_O365.vbs
	}
	.\HIT_NHCA_Downloads\3rd_Party_Scripts\Uninstall_O365.vbs ALL /Quiet /NoCancel /Force /OSE #>
	.\HIT_NHCA_Files\3rd_Party_Scripts\Uninstall_O365.vbs ALL /Quiet /NoCancel /Force /OSE

}

### 2.4. Install VPN ### # Can we figure out silent install? 
function Add-OpenVPN {
	Start Powershell {
		do {
			Start-Sleep -s 5
		}

		until (Test-Path -Path .\HIT_NHCA_Downloads\VPN\OpenVPN.msi -PathType Leaf)

		.\HIT_NHCA_Downloads\VPN\OpenVPN.msi
	}
}
	# .\HIT_NHCA_Files\VPN\OpenVPN-Connect_3.3.3.msi
	# .\HIT_NHCA_Files\VPN\Profile\mtsadmin.ovpn
	# Silent install? MsiExec.exe /i OpenVPN.msi /passive???

### 2.5. Adobe Reader DC ### # Can I make this always get latest version?

function Add-Adobe {
	Start Powershell {
		do {
			Start-Sleep -s 5
		}

		until (Test-Path -Path .\HIT_NHCA_Downloads\Adobe_Reader_DC.exe -PathType Leaf)

		.\HIT_NHCA_Downloads\Adobe_Reader_DC.exe /sAll

	}
}

### 2.6. Ninite Script (Chrome and 7-Zip) ### # "/Silent" - Doesn't work (PRO Only) and with BitsTransfer breaking this I'm tempted to leave this to the onboarding script, unless this is a full config being performed and Chrome is needed immediately or requested (Usually important for the sake of Bookmarks)

function Add-NiniteScript {
	Start Powershell {
		Invoke-WebRequest https://ninite.com/7zip-chrome/ninite.exe -OutFile .\HIT_NHCA_Downloads\Ninite.exe
		.\HIT_NHCA_Downloads\Ninite.exe

	}
}

### 2.7. Install Agent ###

function Add-Agent {
	$AgentURL = Read-Host "Please enter the URL for Site Agent"
	Invoke-WebRequest -uri $AgentURL -OutFile .\HIT_NHCA_Downloads\Agent\Agent.exe
	.\HIT_NHCA_Downloads\Agent\Agent.exe

}

### 3. New Users ###

function New-SysopAdmin {
	$UserExist = Get-LocalUser -Name hitadmin
	if ($UserExist) {
		$sysopPassword = Read-Host "What is the password for HITAdmin? " -AsSecureString # Improve code here by not requiring variable (Will go without variable but adds several extra lines of text) - Variable maybe helpful for setup of VPN
		Set-LocalUser -Name hitadmin -Password $sysopPassword
		# Makes sure user is setup properly
	}

	elseif (!$UserExist) {
		$sysopPassword = Read-Host "What will the password be for hitadmin? " -AsSecureString # Improve code here by not requiring variable (Will go without variable but adds several extra lines of text)
		New-LocalUser "hitadmin" -Password $sysopPassword -AccountNeverExpires -PasswordNeverExpires
		Add-LocalGroupMember -Group "Administrators" -Member "hitadmin"
	}
}

### 4. Connect OpenVPN ### #? https://strongvpn.com/autoconnect-windows-10-openvpn/ claims to have a solution

function New-VPNAutoconnect { # This likely needs to be broken up and things likely need to be changed to match what the different parts of this might be. 
	<# & "C:\Program Files\OpenVPN Connect\OpenVPNConnect.exe" --accept-gdpr --skip-startup-dialogs --import-profile=C:\Users\hitadmin\Desktop\HIT_NHCA-UNIV_CONFIG\HIT_NHCA_Files\VPN\Profile\mtsadmin.ovpn --name=mtsadmin --username=mtsadmin --password=<secured variable string> #>

}

### 5. Public Desktop Shortcuts ### # This maybe depreciated as Gavin takes care of this better with the onboading script, although I'd like to do better by having them in already, with the icons, and more important icons. Keeping for now to test how they work together in the case of a full config and user wants icons immediately

function Add-DesktopShortcuts {
	Copy-Item -Path .\HIT_NHCA_Files\Desktop_Shortcuts\Shortcut` Icons -Destination "C:\ProgramData\Shortcut` Icons" -Recurse
	Copy-Item -Path .\HIT_NHCA_Files\Desktop_Shortcuts\*.lnk -Destination "C:\Users\Public\Desktop\"

}

### 6.1. Site Name ### # Only for site abbreviation consistency



### 6.2. Device Type ### # Only for site abbreviation consistency



### 6.4. Computer Number ### # Number of computer for site and Type code



### 6.5. Rename Computer and Connect to Domain1.local

function Add-Domain {
	$ComputerName = Read-Host "What should be the name of this computer? " # Would like to have these semi standardized and maybe even just ask Laptop or Desktop so that we just enter a number
	Add-Computer -DomainName Domain1.local -NewName $ComputerName -Credential domain1\mtsadmin -Restart -Force

}

### 7. Create Task Scheduler ### # Needs to connect VPN if at all possible during system startup with saved creds and needs to run script with parameter to tell it to start with step 14 and beyond



### 8. Install Office ### # Download from server if using internet downloads (This maybe very unneccessary, but could be useful)

function Add-Office {
	Start Powershell {
		.\HIT_NHCA_Files\ODT\setup.exe /configure .\HIT_NHCA_Files\ODT\ConfigurationNHCA.xml
	}

}

### 9. Remove User ### # Repeat til complete? Can I just search for users and remove those and then run once to ask if any additional? Can I just get what defaults are and just be sure that and any others I expect will only ever be in there?

function Remove-AnyUser {
	Do {
		$RemoveUsername = Read-Host "What user would you like to remove? (leave blank if none)"
		Remove-LocalUser -Name $RemoveUsername
	}

	Until ($RemoveUsername -eq "")
}

### 10. System Updates ### # Better way to run then with "&"? Wait til feedback is given to continue with updates (want to be sure office is done installing) and maybe check if using wireless and warn user

function Update-System { # Need to set this up may take a little configuring (Reconnecting wifi) and also where systems aren't always dell need to handle errors
	# & 'C:\Program Files\Dell\CommandUpdate.\dcu-cli.exe' /configure -importSettings=.\HIT_NHCA_Files\Dell\Dell.xml
	& 'C:\Program Files\Dell\CommandUpdate.\dcu-cli.exe' /applyUpdates

}

### 11. Restore System Power Settings ### # Set Power Settings to a self decided setting based on the differences with Desktop and Laptops. This is a background task and may need some kind of confirmation this was successful.

function Change-SystemTimeoutEnd {
	Powercfg /Change monitor-timeout-dc 5
	Powercfg /Change monitor-timeout-ac 10
	Powercfg /Change standby-timeout-dc 15
	Powercfg /Change standby-timeout-ac 30

}

### Remove Persistent Variable ###

function Remove-StageKey {
    Remove-Item -Path "HKLM:\Software\HNUC" -Recurse -Force
}

### Restart computer ###

### 12.1. Default taskbar modifications ###

### 12.2 Default browsers and such ###

### 13. Force switching user to firstlogin and then upon login reboot ###

### 14. Initiate Removal of Script from Root of C ###

### Full Config Only stuff ###

### Add Printer ###

### Microsoft Account ###

### Bitlocker ###

### Write code in repair menu to update software that is kept locally for simplicity ###

### Pull bookmarks and such from other machine and user data ###
