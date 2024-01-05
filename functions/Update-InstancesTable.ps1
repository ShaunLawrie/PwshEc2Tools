function Update-InstancesTable {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$AwsProfiles,
        [Parameter(Mandatory=$true)]
        [string[]]$AwsRegions
    )

    Clear-Host
    Write-SpectreFigletText -Text "EC2" -Color Orange1 -FigletFontPath "$PSScriptRoot/../fonts/ANSI Shadow.flf"
    $cursorPosition = $Host.UI.RawUI.CursorPosition
    [Console]::SetCursorPosition($cursorPosition.X + 25, $cursorPosition.Y - 4)
    Write-Host -NoNewline "Extremely"
    [Console]::SetCursorPosition($cursorPosition.X + 25, $cursorPosition.Y - 3)
    Write-Host -NoNewline "Common"
    [Console]::SetCursorPosition($cursorPosition.X + 25, $cursorPosition.Y - 2)
    Write-Host -NoNewline "Commands"
    [Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)

    foreach($awsProfile in $AwsProfiles) {
        foreach($region in $AwsRegions) {
            $instanceData = & aws ec2 describe-instances --profile $awsProfile --region $region --output json | ConvertFrom-Json
            $instanceData.Reservations.Instances | Select-Object `
                @{
                    Name = "State"
                    Expression = {
                        $state = $_.State.Name
                        switch($state) {
                            "running" { "[green]:green_circle: Running[/]" }
                            "stopped" { "[red]:stop_sign: Stopped[/]" }
                            "terminated" { "[white]:skull: Terminated[/]" }
                            default { "[DodgerBlue1]:clockwise_vertical_arrows: $($state | Get-SpectreEscapedText)[/]" }
                        }
                    }
                },
                InstanceId,
                @{Name="Name";Expression={$_.Tags | Where-Object Key -eq "Name" | Select-Object -ExpandProperty Value}},
                InstanceType,
                PlatformDetails,
                LaunchTime,
                PublicIpAddress | Format-SpectreTable -AllowMarkup -Color Orange1
            $instances += $instanceData.Reservations.Instances | Select-Object `
                InstanceId,
                PublicIpAddress,
                @{
                    Name="Region"
                    Expression={$region}
                },
                @{
                    Name="Profile"
                    Expression={$awsProfile}
                },
                @{
                    Name="Name (InstanceId)"
                    Expression={($_.Tags | Where-Object Key -eq "Name" | Select-Object -ExpandProperty Value) + " ($($_.InstanceId))"}
                }
        }
    }
    Write-Host ""
    return $instances
}