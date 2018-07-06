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
# SIG # Begin signature block
# MIIQ/wYJKoZIhvcNAQcCoIIQ8DCCEOwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhVNvqAHJYjFMQVW+udsp+I2Z
# gT6gggyRMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggP0MIIC3KADAgECAhB/a5fIdzrerUEQmV6aj/9NMA0GCSqGSIb3
# DQEBCwUAMBwxGjAYBgNVBAMMEVJ5ZW4uS2lhLlpoaS5UYW5nMB4XDTE3MTIyNjA5
# NTE1NVoXDTE4MTIyNjEwMTE1NVowHDEaMBgGA1UEAwwRUnllbi5LaWEuWmhpLlRh
# bmcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDsBt37XrwrkReIAsf4
# Z6Ij9Du29Q/YLq1djViZvCfbWBwWSU+mYQs65IX58qg6D/kzX+QAdN7BrYkutk49
# Heqat7+9c1bDn8C1MtJs4D7xbPX2TrhvZJ4aFpSE05BXd9xI1NqYYGON32lVDilI
# +6yiD9/GfZhej0ysUPNHBsr0hq1TxHfILjmf8K2draYack0tr3gfOgPRrrgF+khZ
# Um1pS1S9e07OkWCH3L+O9y4x/1rapp9+d1kx5iF6zD3NHvitnIuNSV70livhr0B8
# V9GZsZ5Ln8QfhpZ68oEAK5ud/kTnK6sWkea2kV5eQNT/KNSm7+zfJ0bmIUvIDDtm
# 4q+tAgMBAAGjggEwMIIBLDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwgeUGA1UdEQSB3TCB2oY1aHR0cHM6Ly9tdnAubWljcm9zb2Z0LmNvbS9l
# bi11cy9QdWJsaWNQcm9maWxlLzUwMDE3MTCGRWh0dHBzOi8vc29jaWFsLnRlY2hu
# ZXQubWljcm9zb2Z0LmNvbS9wcm9maWxlL3J5ZW4lMjBraWElMjB6aGklMjB0YW5n
# L4YjaHR0cHM6Ly9uei5saW5rZWRpbi5jb20vaW4vcnllbnRhbmeGGmh0dHBzOi8v
# dHdpdHRlci5jb20va2lhemhphhlodHRwczovL2dpdGh1Yi5jb20va2lhemhpMB0G
# A1UdDgQWBBSGIqBWna8/GZNMsH+T5JM8jmkeNjANBgkqhkiG9w0BAQsFAAOCAQEA
# b/lIFMuGkQYH1mMdAXYBfgHZKq85vayddmoXJcXIzlwFygBTus9oytgln1nG1y20
# S7Wvb5a2Mmo6hyzIX1W8xB0mznW9EKI35dSfCzY4AJnpZFyguRn+JwumQJWN++Ej
# 4qp3tRQeJ2v0/Nsm8Q1Amp03S4oWZ1Ro5NRbpOILbk/IMRuZN4kecxltpyb7XKPG
# +GESKe4sGqJny3NRjGNdVE2CH/cJhsCzJdwgQwED8FVS/h/k4gkURdOJTQR8fOxI
# fMVtR69W3PZ3FEnFaN0frfevpImNRD5ucJd3Bp+NiJfK9DxKvgudiIth92okpP5w
# 7TYgNQKPDV59EFC5WUs6hjCCBKMwggOLoAMCAQICEA7P9DjI/r81bgTYapgbGlAw
# DQYJKoZIhvcNAQEFBQAwXjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVj
# IENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNl
# cnZpY2VzIENBIC0gRzIwHhcNMTIxMDE4MDAwMDAwWhcNMjAxMjI5MjM1OTU5WjBi
# MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xNDAy
# BgNVBAMTK1N5bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgU2lnbmVyIC0g
# RzQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCiYws5RLi7I6dESbsO
# /6HwYQpTk7CY260sD0rFbv+GPFNVDxXOBD8r/amWltm+YXkLW8lMhnbl4ENLIpXu
# witDwZ/YaLSOQE/uhTi5EcUj8mRY8BUyb05Xoa6IpALXKh7NS+HdY9UXiTJbsF6Z
# WqidKFAOF+6W22E7RVEdzxJWC5JH/Kuu9mY9R6xwcueS51/NELnEg2SUGb0lgOHo
# 0iKl0LoCeqF3k1tlw+4XdLxBhircCEyMkoyRLZ53RB9o1qh0d9sOWzKLVoszvdlj
# yEmdOsXF6jML0vGjG/SLvtmzV4s73gSneiKyJK4ux3DFvk6DJgj7C72pT5kI4RAo
# cqrNAgMBAAGjggFXMIIBUzAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMA4GA1UdDwEB/wQEAwIHgDBzBggrBgEFBQcBAQRnMGUwKgYIKwYBBQUH
# MAGGHmh0dHA6Ly90cy1vY3NwLndzLnN5bWFudGVjLmNvbTA3BggrBgEFBQcwAoYr
# aHR0cDovL3RzLWFpYS53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNlcjA8BgNV
# HR8ENTAzMDGgL6AthitodHRwOi8vdHMtY3JsLndzLnN5bWFudGVjLmNvbS90c3Mt
# Y2EtZzIuY3JsMCgGA1UdEQQhMB+kHTAbMRkwFwYDVQQDExBUaW1lU3RhbXAtMjA0
# OC0yMB0GA1UdDgQWBBRGxmmjDkoUHtVM2lJjFz9eNrwN5jAfBgNVHSMEGDAWgBRf
# mvVuXMzMdJrU3X3vP9vsTIAu3TANBgkqhkiG9w0BAQUFAAOCAQEAeDu0kSoATPCP
# YjA3eKOEJwdvGLLeJdyg1JQDqoZOJZ+aQAMc3c7jecshaAbatjK0bb/0LCZjM+RJ
# ZG0N5sNnDvcFpDVsfIkWxumy37Lp3SDGcQ/NlXTctlzevTcfQ3jmeLXNKAQgo6rx
# S8SIKZEOgNER/N1cdm5PXg5FRkFuDbDqOJqxOtoJcRD8HHm0gHusafT9nLYMFivx
# f1sJPZtb4hbKE4FtAC44DagpjyzhsvRaqQGvFZwsL0kb2yK7w/54lFHDhrGCiF3w
# PbRRoXkzKy57udwgCRNx62oZW8/opTBXLIlJP7nPf8m/PiJoY1OavWl0rMUdPH+S
# 4MO8HNgEdTGCA9gwggPUAgEBMDAwHDEaMBgGA1UEAwwRUnllbi5LaWEuWmhpLlRh
# bmcCEH9rl8h3Ot6tQRCZXpqP/00wCQYFKw4DAhoFAKBwMBAGCisGAQQBgjcCAQwx
# AjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSViCBiEYA4YpMZ+C+xM/YDqiTd
# kDANBgkqhkiG9w0BAQEFAASCAQA1LVgM2lzxGGprZcPWB3Is2bJqBuzffDOpJOpi
# eAmxEhgrsvgP2lpLvOzvy31iXYDXdWSeMH7mwgTq+6pTguq8ElNY0v9gmOZ7NflI
# ViTpFdRrUDH5NK3vpMxA/KBYNGbfEo3K/e/DoGvtbK9NiglCBl3yVTnxyY9FBQzB
# EbGvA1CYdO2FYvfRIbbpxfQ2EPCmSoxoyEHoK5nec6nNNbP9rkq73uCUjjZe6nrH
# bVIEWFbAZq9Rda32WTVfnPsCJ/Q4Mk45WqAmMo7k7qyDeoCSa5JTrpo1xReuxEgY
# fgDzMqWNOTy8DkDAJaa4Yud2DQLuqGsKRfp4KQ5ZBZSvOQyYoYICCzCCAgcGCSqG
# SIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkGA1UEBhMCVVMxHTAbBgNVBAoTFFN5
# bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQDEydTeW1hbnRlYyBUaW1lIFN0YW1w
# aW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI/r81bgTYapgbGlAwCQYFKw4DAhoF
# AKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4
# MDcwNjAzMjM0MVowIwYJKoZIhvcNAQkEMRYEFCCR9N8RrzQJ6pBXoD1QSx+4Lz9A
# MA0GCSqGSIb3DQEBAQUABIIBAAGGasTWCdaUKmeAfcNJ0KwdyiPCZorH2PtBWIHe
# rThJHND7oecjrdce1S4Gs06jA8Yy/Dkr8/AsS/gR+SixWjr3hLBXa7vJ0p4ziMKn
# U1X9nbORZpOdMrbz3G676+ympzQhdXZ1rJPvufxJiJSsw+27m1y8NINx3k73KuS3
# gNkUuvA6jZtjv/U8AKTr0fpbV0h8D5uDgOcs0xQytX4jckEv4CqQN3AtcEwTEQqJ
# zyAqG4JkO3S9Q/Xsck2ykZsX+KCuBbeKB/B7OZ3yXC0uT2thl8byhfAbTtU9AmOD
# 21fiOgOJZ1GcyIUpRksj/fjyFLN/9oLuRQNjie1PLLZPEnU=
# SIG # End signature block
