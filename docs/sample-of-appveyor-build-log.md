---
title: Sample of AppVeyor build log
author: Kia Zhi Tang (Ryen Tang)
date: 05/07/2018
categories: [log, documentation]
tags: [log, documentation]
---

# Sample of AppVeyor build log

In this section, we discuss how we trigger the build using the files in this
repository and provide the AppVeyor raw log output as a sample.

## Triggering the build process

We generated a raw AppVeyor build log that was triggered after we used
`git add` on the following new files to this repository:

- .\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container
    - `.\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\Dockerfile`
    - `.\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\Test-Container.ps1`
    - .\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\10.3.0
        - `.\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\10.3.0\Dockerfile`
    - .\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\8.11.2
        - .\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\8.11.2\latest
            - `.\dockerfiles\appveyor-ci-cd-for-docker-test-nodejs-nanoserver-container\8.11.2\latest\Dockerfile`
- .\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container
    - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\Dockerfile`
    - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\Test-Container.ps1`
    - .\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.5.4
        - .\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.5.4\latest
            - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.5.4\latest\Dockerfile`
            - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.5.4\latest\Test-Container.ps1`
    - .\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.6.5
        - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.6.5\Dockerfile`
        - `.\dockerfiles\appveyor-ci-cd-for-docker-test-python-nanoserver-container\3.6.5\Test-Container.ps1`

After staging the files, we perform a `git commit` with a message that we are
committing Dockerfiles and test scripts for build, test and deployment testing.

Finally, pushing the committed new files to the repository using `git push`
that triggers the AppVeyor CI/CD process.

## AppVeyor Build Log

To view our raw AppVeyor log generated from the process above, we have uploaded
the log as a reference in this repository
[here](https://raw.githubusercontent.com/kiazhi/AppVeyor-CI-CD-for-Docker/master/docs/appendix/appveyor-raw-build-log.txt).