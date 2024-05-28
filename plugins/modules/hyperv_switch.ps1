
#!powershell
# This file modelled on the template used by by the professionals at https://github.com/ansible-collections/ansible.windows/blob/main/plugins/modules/win_acl.ps1
# Copyright: (c) 2024, Geoff O'Callaghan <geoffocallaghan@gmail.com>
#Requires -Module Ansible.ModuleUtils.Legacy

Function Delete_VirtualSwitch {
    $currentSwitch = Get-VMSwitch -name $name -ErrorAction SilentlyContinue
    
    if ($currentSwitch -ne $null) {
      $cmd="Remove-VMSwitch -Name $name -Force"
      $result.cmd_used = $cmd
      $result.changed = $true
      
      $results = invoke-expression $cmd
    } else {
      $result.changed = $false
    }
}
Function Create_VirtualSwitch {
    #Check If the VirtualSwitch already exists
    $currentSwitch = Get-VMSwitch -name $name -ErrorAction SilentlyContinue
    
    if ($currentSwitch -eq $null) {
      # New switch, build up the command to execute
      $cmd = "New-VMSwitch -Name $name"
      
      if ($switchType) {
        $cmd += " -SwitchType $switchType"
      }
      
      if ($netAdapterName) {
        $cmd += " -NetAdapterName '$netAdapterName'"
      }

      if ($netAdapterNameDescription) {
        $cmd += " -NetAdapterNameDescription '$netAdapterNameDescription'"
      }
      
      if ($allowManagementOS) {
        $enabled = $true
        if ($allowManagementOS -eq "disabled") {
          $enabled = $false

        }
        $cmd += ' -AllowManagementOS $enabled '
      }
  
      $result.cmd_used = $cmd
      $result.changed = $true
      

      $results = invoke-expression -Command "$cmd"
  

    } 
    else {
        $result.changed = $false
    } 
    # Get-VMSwitch and return the data
    $result.json = Get-VMSwitch -Name "$name" | ConvertTo-Json -Compress

}

$ErrorActionPreference = "Stop"

$result = @{
    changed = $false
}


$params = Parse-Args $args -supports_check_mode $false
$result = @{
  changed = $false
  cmd_used = ""
}

$name = Get-AnsibleParam $params "name" -type "str" -FailIfEmpty $true 
$state = Get-AnsibleParam $params "state" -type "str" -FailIfEmpty $true 
$switchType = Get-AnsibleParam $params "switchType" -type "str" -Default $null
$netAdapterName = Get-AnsibleParam $params "netAdapterName" -type "str"  -Default $null
$netAdapterNameDescription = Get-AnsibleParam $params "netAdapterNameDescription" -type "str"  -Default $null
$allowManagementOS = Get-AnsibleParam $params "allowManagementOS" -type "string" -Default $null

Try {

    switch ($state) {
        "present" {Create_VirtualSwitch}
        "absent" {Delete_VirtualSwitch}
      }
}
Catch {
    Fail-Json -obj $result -message "an error occurred when attempting to Get-VMSwitch -name $name - $($_.Exception.Message)"
}
Finally {
    # Make sure we do any cleanup in here
}
Exit-Json -obj $result
