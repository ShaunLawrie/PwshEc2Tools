#Requires -Version 7 -Modules PwshSpectreConsole

. "$PSScriptRoot/functions/Update-InstancesTable.ps1"

$awsProfiles = @("default")
$awsRegions = @("ap-southeast-2", "us-west-2")
$color = "Orange1"

try {
    Write-Host "`e[?1049h" # alt screen buffer

    $avaliableActions = @("Refresh", "Stop", "Start", "Connect", "Terminate")
    while($true) {

        $instances = Update-InstancesTable -awsProfiles $awsProfiles -awsRegions $awsRegions

        Write-SpectreHost "Press [$color]Ctrl+C[/] to exit."

        $action = Read-SpectreSelection -Title "Choose an action: " -Choices $avaliableActions -Color $color
        Write-SpectreHost "Running [$color]$action[/]."

        if($action -eq "Refresh") {
            continue
        }

        $instance = Read-SpectreSelection -Title "Select the [$color]instance[/]: " -Choices $instances -Color $color -ChoiceLabelProperty "Name (InstanceId)"
        Write-SpectreHost "On [$color]$($instance.InstanceId)[/]."

        switch($action) {
            "Stop" {
                & aws ec2 stop-instances --instance-ids $instance.InstanceId --profile $instance.Profile --region $instance.Region
            }
            "Start" {
                & aws ec2 start-instances --instance-ids $instance.InstanceId --profile $instance.Profile --region $instance.Region
            }
            "Connect" {
                if($instance.PlatformDetails -eq "Windows") {
                    Write-SpectreHost "Connecting to [$color]$($instance.'Name (InstanceId)')[/] via [$color]mstsc /v:$($instance.PublicIpAddress)[/]."
                    & mstsc /v:$($instance.PublicIpAddress)
                    continue
                } else {
                    Write-SpectreHost "Connecting to [$color]$($instance.'Name (InstanceId)')[/] with [$color]ssh `"ec2-user@$($instance.PublicIpAddress)`"[/]."
                    & ssh "ec2-user@$($instance.PublicIpAddress)"
                }
            }
            "Terminate" {
                $response = Read-SpectreConfirm -Prompt "Are you sure you want to terminate [$color]$($instance.'Name (InstanceId)')[/]?" -Color $color
                if($response -eq "y") {
                    Write-SpectreHost "Terminating [$color]$($instance.'Name (InstanceId)')[/]."
                    & aws ec2 terminate-instances --instance-ids $instance.InstanceId --profile $instance.Profile --region $instance.Region
                } else {
                    Write-SpectreHost "Not terminating [$color]$($instance.'Name (InstanceId)')[/]."
                }
            }
        }
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`e[?1049l" # back to standard buffer
}