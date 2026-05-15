param(
	[int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Find-GodotWindows {
	$root = [System.Windows.Automation.AutomationElement]::RootElement
	$condition = New-Object System.Windows.Automation.PropertyCondition(
		[System.Windows.Automation.AutomationElement]::ControlTypeProperty,
		[System.Windows.Automation.ControlType]::Window
	)
	$root.FindAll([System.Windows.Automation.TreeScope]::Children, $condition) |
		Where-Object { $_.Current.Name -match "Godot|Racer|Load Errors|Files have been modified" }
}

function Invoke-ButtonByName($window, [string]$buttonName) {
	$buttonCondition = New-Object System.Windows.Automation.AndCondition(
		(New-Object System.Windows.Automation.PropertyCondition(
			[System.Windows.Automation.AutomationElement]::ControlTypeProperty,
			[System.Windows.Automation.ControlType]::Button
		)),
		(New-Object System.Windows.Automation.PropertyCondition(
			[System.Windows.Automation.AutomationElement]::NameProperty,
			$buttonName
		))
	)
	$button = $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)
	if ($null -eq $button) {
		return $false
	}
	$pattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
	$pattern.Invoke()
	Write-Host "Clicked '$buttonName' in '$($window.Current.Name)'."
	return $true
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = 0

while ((Get-Date) -lt $deadline) {
	foreach ($window in Find-GodotWindows) {
		$title = $window.Current.Name
		if ($title -match "Files have been modified") {
			if (Invoke-ButtonByName $window "Reload from disk") {
				$clicked += 1
				Start-Sleep -Milliseconds 250
				continue
			}
		}
		if ($title -match "Load Errors") {
			if (Invoke-ButtonByName $window "OK") {
				$clicked += 1
				Start-Sleep -Milliseconds 250
				continue
			}
		}
	}
	if ($clicked -gt 0) {
		break
	}
	Start-Sleep -Milliseconds 500
}

if ($clicked -eq 0) {
	Write-Host "No safe Godot editor dialog action was available."
}
