<#
.SYNOSIS

Perform tests on the container image from the commands in Test-Container.ps1 file.

.DESCRIPTION

Gets the file path from Git push/pull.
Analyses if it is a Dockerfile from the file path and skip if it is not. 
Uses Docker CLI to run the container image with the commands from Test-Container.ps1 file for testing purposes.

.INPUTS

None. You cannot pipe objects to Test-DockerImage.

.OUTPUTS

Commands outputs from the container image.

.NOTES

    Version       : 1.0.1
    Author        : Ryen Kia Zhi Tang
    Creation Date : 29/06/2018
    Purpose/Change: Intended as AppVeyor test_script for container image development
    ProjectUri    : https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker
    LicenseUri    : https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker/blob/master/LICENSE

.LINK

https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker

.LINK

https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker/.appveyor/scripts/Test-DockerImage.ps1

#>

#region - Define PowerShell preferences

$ErrorActionPreference = 'Stop'

$InformationPreference = 'Continue'

$VerbosePreference = 'SilentlyContinue'

#endregion

#region - Define variables

$SCRIPT:Files = Out-Null

$SCRIPT:DockerFilePathFilter = 'dockerfiles/*/Dockerfile'

$SCRIPT:TestContainerScriptFileName = 'Test-Container.ps1'

#endregion

#region - Begin getting file path from git commits

if($ENV:APPVEYOR_PULL_REQUEST_NUMBER)
{
    Write-Information `
        -MessageData $([String]::Format('{0}: [{1}.{2} {3}] {4}: {5} (#{6})',
            'INFO',
            (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
            (Get-Date).Millisecond,
            (Get-TimeZone).DisplayName,
            'Triggered by changes initiated from Pull Request',
            $ENV:APPVEYOR_PULL_REQUEST_TITLE,
            $ENV:APPVEYOR_PULL_REQUEST_NUMBER))
    
    $Files = $(git --no-pager diff --name-only FETCH_HEAD $(git merge-base FETCH_HEAD master))
}
else
{
    Write-Information `
        -MessageData $([String]::Format('{0}: [{1}.{2} {3}] {4}: {5} {6}',
            'INFO',
            (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
            (Get-Date).Millisecond,
            (Get-TimeZone).DisplayName,
            'Triggered by changes initiated from',
            $ENV:APPVEYOR_REPO_BRANCH,
            'Branch'))
    
    $Files = $(git diff --name-only --diff-filter=d HEAD~1)    
}

#endregion

#region - Process container image test

if ($SCRIPT:Files -ne (Out-Null))
{
    $SCRIPT:Files | ForEach-Object `
    { 
        if($_ -like $SCRIPT:DockerFilePathFilter)
        {
            # Get Dockerfile directory path
            $SCRIPT:DirectoryPath = (($_ -replace "\/[^\/]+$", "") -replace "/", "\")
    
            # List the docker images on appveyor host
            docker images

            # Construct the Container Image Name using the Folder Path
            switch($SCRIPT:DirectoryPath.Split('\').Count)
            {
                2
                {
                    # Example:
                    # The file path '/dockerfiles/nanoserver/Dockerfile' will translates as 
                    # container image name 'nanoserver' with a image tag 'latest' like this below:
                    # 'nanoserver:latest'
                    $SCRIPT:ContainerImageNameTag = [String]::Format('{0}:latest',
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -1)])
                }

                3 
                {
                    # Example:
                    # The file path '/dockerfiles/nanoserver/3.6.5/Dockerfile' will translates as 
                    # container image name 'nanoserver' with a image tag '3.6.5' like this below:
                    # 'nanoserver:3.6.5'
                    $SCRIPT:ContainerImageNameTag = [String]::Format('{0}:{1}',
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -2)],
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -1)])
                }
            
                4 
                {
                    # Example:
                    # The file path '/dockerfiles/nanoserver/python/3.6.5/Dockerfile' will translates as 
                    # container image name 'nanoserver.python' with a image tag '3.6.5' like this below:
                    # 'nanoserver.python:3.6.5'
                    $SCRIPT:ContainerImageNameTag = [String]::Format('{0}.{1}:{2}',
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -3)],
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -2)],
                        ($SCRIPT:DirectoryPath).Split('\')[$(($SCRIPT:DirectoryPath).Split('\').Count -1)])
                }
            }

            # Validate Dockerfile parent folder path contains a test script for
            # testing the container image
            if(Test-Path -Path "$(Split-Path -Path $SCRIPT:DirectoryPath -Parent)\$SCRIPT:TestContainerScriptFileName")
            {
                # Validate test script is not empty
                if((Get-Content `
                    -Path "$(Split-Path -Path $SCRIPT:DirectoryPath -Parent)\$SCRIPT:TestContainerScriptFileName" | `
                    Where-Object `
                    { 
                        ($_ -match '\S') -and
                        ($_.ToString().StartsWith('#') -ne $True) -and
                        ($_.ToString().Replace(' ','').StartsWith('#') -ne $True)
                    }).Count -ne 0)
                {
                    # Get each line of command from test script
                    Get-Content `
                        -Path "$(Split-Path -Path $SCRIPT:DirectoryPath -Parent)\$SCRIPT:TestContainerScriptFileName" | `
                        Where-Object `
                        { 
                            ($_ -match '\S') -and
                            ($_.ToString().StartsWith('#') -ne $True) -and
                            ($_.ToString().Replace(' ','').StartsWith('#') -ne $True)
                        } | `
                        ForEach-Object `
                        {
                            # Print test command execution
                            Write-Information `
                                -MessageData $([String]::Format("{0}: [{1}.{2} {3}] {4} ({5}\{6}) {7} {8} {9}:`n{10}",
                                    'INFO',
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Begin testing',
                                    $(Split-Path -Path $SCRIPT:DirectoryPath -Parent),
                                    $SCRIPT:TestContainerScriptFileName,
                                    'command on line',
                                    $_.ReadCount,
                                    'below',
                                    $_))
                            
                            # Test the container image
                            $SCRIPT:Output = & docker run $SCRIPT:ContainerImageNameTag $_.Split(' ') 2>&1
                            
                            if($($SCRIPT:Output | `
                                Where-Object `
                                { $_ -isnot [System.Management.Automation.ErrorRecord] }) -ne $(Out-Null))
                            {

                                # Print test command execution output
                                Write-Information `
                                    -MessageData $([String]::Format('{0}: [{1}.{2} {3}] {4}:',
                                        'INFO',
                                        (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                        (Get-Date).Millisecond,
                                        (Get-TimeZone).DisplayName,
                                        'Command returns the following output below'))

                                # No Error
                                #Write-Host -Object $SCRIPT:Output
                                Write-Output -InputObject $SCRIPT:Output
                            }

                            $ErrorActionPreference = 'Stop'

                            # Construct exception message so that Write-Error do not 
                            # throw the entire spaghetti if statement code  
                            if($LASTEXITCODE)
                            {
                                $SCRIPT:Exception = $([String]::Format("[{0}.{1} {2}] {3}:{4}`n{5}:`n{6}`n{7}:`n{8}",
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Command exited with Error Code',
                                    $LASTEXITCODE,
                                    'Command syntax',
                                    $_,
                                    'Error Output below',
                                    $SCRIPT:Output))
                            }
                            elseif($SCRIPT:Output -eq $(Out-Null))
                            {
                                $SCRIPT:Exception = $([String]::Format("[{0}.{1} {2}] {3}`n{4}:`n{5}`n{6}:`n{7}",
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Command exited with no Error Code except for null output.',
                                    'Command syntax',
                                    $_,
                                    'Output below',
                                    $SCRIPT:Output))
                            }

                            # Throw error message and fail the test stage
                            if($LASTEXITCODE)
                            {
                                Write-Error -Message $SCRIPT:Exception
                            }
                            elseif($SCRIPT:Output -eq $(Out-Null))
                            {
                                Write-Error -Message $SCRIPT:Exception
                            }
                        }
                }
                else
                {
                    Write-Warning `
                        -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}\{6}) {7}.',
                            (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                            (Get-Date).Millisecond,
                            (Get-TimeZone).DisplayName,
                            'Skip test stage',
                            'The test script',
                            $(Split-Path -Path $SCRIPT:DirectoryPath -Parent),
                            $SCRIPT:TestContainerScriptFileName,
                            'is empty'))
                }
            }
            else
            {
                Write-Warning `
                    -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}\{6}) {7}.',
                        (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                        (Get-Date).Millisecond,
                        (Get-TimeZone).DisplayName,
                        'Skip test stage',
                        'The test script',
                        $(Split-Path -Path $SCRIPT:DirectoryPath -Parent),
                        $SCRIPT:TestContainerScriptFileName,
                        'does not exist'))
            }
            

            # Validate Dockerfile folder path contains a test script for
            # testing the container image
            if(Test-Path -Path "$SCRIPT:DirectoryPath\$SCRIPT:TestContainerScriptFileName")
            {
                $ErrorActionPreference = 'SilentlyContinue'

                # Validate test script is not empty
                if((Get-Content `
                    -Path "$SCRIPT:DirectoryPath\$SCRIPT:TestContainerScriptFileName" | `
                    Where-Object `
                    { 
                        ($_ -match '\S') -and 
                        ($_.ToString().StartsWith('#') -ne $True) -and
                        ($_.ToString().Replace(' ','').StartsWith('#') -ne $True)
                    }).Count -ne 0)
                {
                    # Get each line of command from test script
                    Get-Content `
                        -Path "$SCRIPT:DirectoryPath\$SCRIPT:TestContainerScriptFileName" | `
                        Where-Object `
                        { 
                            ($_ -match '\S') -and
                            ($_.ToString().StartsWith('#') -ne $True) -and
                            ($_.ToString().Replace(' ','').StartsWith('#') -ne $True)
                        } | `
                        ForEach-Object `
                        {
                            # Print test command execution
                            Write-Information `
                                -MessageData $([String]::Format("{0}: [{1}.{2} {3}] {4} ({5}\{6}) {7} {8} {9}:`n{10}",
                                    'INFO',
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Begin testing',
                                    $SCRIPT:DirectoryPath,
                                    $SCRIPT:TestContainerScriptFileName,
                                    'command on line',
                                    $_.ReadCount,
                                    'below',
                                    $_))
                            
                            # Test the container image
                            $SCRIPT:Output = & docker run $SCRIPT:ContainerImageNameTag $_.Split(' ') 2>&1
                            
                            if($($SCRIPT:Output | `
                                Where-Object `
                                { $_ -isnot [System.Management.Automation.ErrorRecord] }) -ne $(Out-Null))
                            {

                                # Print test command execution output
                                Write-Information `
                                    -MessageData $([String]::Format('{0}: [{1}.{2} {3}] {4}:',
                                        'INFO',
                                        (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                        (Get-Date).Millisecond,
                                        (Get-TimeZone).DisplayName,
                                        'Command returns the following output below'))

                                # No Error
                                #Write-Host -Object $SCRIPT:Output
                                Write-Output -InputObject $SCRIPT:Output
                            }

                            $ErrorActionPreference = 'Stop'

                            # Construct exception message so that Write-Error do not 
                            # throw the entire spaghetti if statement code  
                            if($LASTEXITCODE)
                            {
                                $SCRIPT:Exception = $([String]::Format("[{0}.{1} {2}] {3}:{4}`n{5}:`n{6}`n{7}:`n{8}",
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Command exited with Error Code',
                                    $LASTEXITCODE,
                                    'Command syntax',
                                    $_,
                                    'Error Output below',
                                    $SCRIPT:Output))
                            }
                            elseif($SCRIPT:Output -eq $(Out-Null))
                            {
                                $SCRIPT:Exception = $([String]::Format("[{0}.{1} {2}] {3}`n{4}:`n{5}`n{6}:`n{7}",
                                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                                    (Get-Date).Millisecond,
                                    (Get-TimeZone).DisplayName,
                                    'Command exited with no Error Code except for null output.',
                                    'Command syntax',
                                    $_,
                                    'Output below',
                                    $SCRIPT:Output))
                            }

                            # Throw error message and fail the test stage
                            if($LASTEXITCODE)
                            {
                                Write-Error -Message $SCRIPT:Exception
                            }
                            elseif($SCRIPT:Output -eq $(Out-Null))
                            {
                                Write-Error -Message $SCRIPT:Exception
                            }
                        }
                }
                else
                {
                    Write-Warning `
                        -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}\{6}) {7}.',
                            (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                            (Get-Date).Millisecond,
                            (Get-TimeZone).DisplayName,
                            'Skip test stage',
                            'The test script',
                            $(Split-Path -Path $SCRIPT:DirectoryPath -Parent),
                            $SCRIPT:TestContainerScriptFileName,
                            'is empty'))
                }
            }
            else
            {
                Write-Warning `
                    -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}\{6}) {7}.',
                        (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                        (Get-Date).Millisecond,
                        (Get-TimeZone).DisplayName,
                        'Skip test stage',
                        'The test script',
                        $SCRIPT:DirectoryPath,
                        $SCRIPT:TestContainerScriptFileName,
                        'does not exist'))
            }
        }
        else
        {
            Write-Warning `
                -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}) {6}.',
                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                    (Get-Date).Millisecond,
                    (Get-TimeZone).DisplayName,
                    'Skip test stage',
                    'The file',
                    $_,
                    'is not a Dockerfile'))
        }
    }
}
else
{
    Write-Warning `
        -Message $([String]::Format('[{0}.{1} {2}] {3}.',
            (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
            (Get-Date).Millisecond,
            (Get-TimeZone).DisplayName,
            'Skip test stage for deleted file'))

    git diff --name-status HEAD~1
}

#endregion