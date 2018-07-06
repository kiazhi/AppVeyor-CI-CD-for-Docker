<#
.SYNOSIS

Changes local container image tag to repository container image tag and push the container image to the docker hub repository with AppVeyor.

.DESCRIPTION

Gets the file path from Git push/pull.
Analyses if it is a Dockerfile from the file path and skip if it is not. 
Uses Docker CLI to change the local container image tag to a repository container image tag.
Login to Docker Hub repository using Docker CLI.
Pushes the repository container image tag to Docker Hub using Docker CLI.

.INPUTS

None. You cannot pipe objects to Deploy-DockerImage.

.OUTPUTS

Repository/Container image pushed to Docker Repository.

.NOTES

    Version       : 1.0.0
    Author        : Ryen Kia Zhi Tang
    Creation Date : 29/06/2018
    Purpose/Change: Intended as AppVeyor deploy_script for container image development
    ProjectUri    : https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker
    LicenseUri    : https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker/blob/master/LICENSE

.LINK

https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker

.LINK

https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker/.appveyor/scripts/powershell/Deploy-DockerImage.ps1

#>

#region - Define PowerShell preferences

$ErrorActionPreference = 'Stop'

$InformationPreference = 'Continue'

$VerbosePreference = 'SilentlyContinue'

#endregion

#region - Define variables

$SCRIPT:Files = Out-Null

$SCRIPT:DockerFilePathFilter = 'dockerfiles/*/Dockerfile'

$SCRIPT:DockerHubRepository = 'kiazhi'

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
    
    $SCRIPT:Files = $(git --no-pager diff --name-only FETCH_HEAD $(git merge-base FETCH_HEAD master))
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
    
    $SCRIPT:Files = $(git diff --name-only --diff-filter=d HEAD~1)    
}

#endregion

#region - Process container image deployment to hub.docker.com

if ($SCRIPT:Files -ne (Out-Null))
{
    $SCRIPT:Files | ForEach-Object `
    { 
        if($_ -like $SCRIPT:DockerFilePathFilter)
        {
            # Get Dockerfile directory path
            $SCRIPT:DirectoryPath = (($_ -replace "\/[^\/]+$", "") -replace "/", "\")

            # Login to Docker Hub
            docker login -u="$ENV:DOCKER_USERNAME" -p="$ENV:DOCKER_PASSWORD"

            # List the Docker Images on AppVeyor Host
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

            # Tag the Container Image to Docker Hub Repository Container Image Tag
            docker tag $SCRIPT:ContainerImageNameTag "$SCRIPT:DockerHubRepository/$SCRIPT:ContainerImageNameTag"
            
            # Push the Docker Hub Repository Container Image to Docker Hub
            docker push "$SCRIPT:DockerHubRepository/$SCRIPT:ContainerImageNameTag"
        }
        else
        {
            Write-Warning `
                -Message $([String]::Format('[{0}.{1} {2}] {3}. {4} ({5}) {6}.',
                    (Get-Date -UFormat "%Y-%m-%d_%H:%M:%S"),
                    (Get-Date).Millisecond,
                    (Get-TimeZone).DisplayName,
                    'Skip deploy stage',
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
            'Skip deploy stage for deleted file'))

    git diff --name-status HEAD~1
}

#endregion