param (
  [string]$Server,
  [string]$serviceName
)

# Get the username and password from environment variables (secure for on-premises)
$UserName = $env:USERNAME
$Password = $env:PASSWORD

# Create a PSCredential object (secure for on-premises)
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($UserName, $SecurePassword)

# Function to stop and start the service
function Manage-Service {
  param (
    [string]$Server,
    [string]$serviceName,
    [System.Management.Automation.PSCredential]$Credential
  )

  # Use Invoke-Command to run the service management commands on the remote server
  Invoke-Command -ComputerName $Server -Credential $Credential -ScriptBlock {
    param ($serviceName)

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    if ($null -eq $service) {
      Write-Output "Service $serviceName does not exist on this server."
      return
    }

    # Echo service status before any actions
    Write-Output "**Current Status:** $($service.Status)"

    if ($service.Status -ne 'Stopped') {
      # Stop the service
      Stop-Service -Name $serviceName -Force
      Write-Output "Service $serviceName has been stopped."
    }

    # Validate the service is stopped
    $service = Get-Service -Name $serviceName
    if ($service.Status -eq 'Stopped') {
      # Start the service
      Start-Service -Name $serviceName
      Write-Output "Service $serviceName has been started."
      
      # Validate the service has started
      $service = Get-Service -Name $serviceName
      if ($service.Status -eq 'Running') {
        Write-Output "Service $serviceName has started successfully."
        # Exit the loop after successful start
        exit
      } else {
        Write-Output "Failed to start service $serviceName."
        # Exit with error if start fails
        exit 1
      }
    } else {
      Write-Output "Failed to stop service $serviceName."
      # Exit with error if stop fails
      exit 1
    }
  } -ArgumentList $serviceName

  # Removed console loop - not applicable in Blue Ocean

  # Success message after successful start
  Write-Output "($serviceName) has started successfully !"
}

# Call the function to manage the service
Manage-Service -Server $Server -serviceName $serviceName -Credential $Credential
