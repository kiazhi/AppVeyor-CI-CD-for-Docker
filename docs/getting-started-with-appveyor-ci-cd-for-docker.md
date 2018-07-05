---
title: Getting Started with AppVeyor CI/CD for Docker
author: Kia Zhi Tang (Ryen Tang)
date: 04/07/2018
categories: [getting-started, documentation]
tags: [getting-started, documentation]
---

# Getting Started with AppVeyor-CI-CD-for-Docker

## Introduction

An introduction of using `kiazhi/AppVeyor-CI-CD-for-Docker` framework.

## Implementation

You can implement this `kiazhi/AppVeyor-CI-CD-for-Docker` framework by:
- Downloading binary to your repository for use
    - Download [AppVeyor-CI-CD-for-Docker-v*.zip](https://github.com/kiazhi/AppVeyor-CI-CD-for-Docker/releases) from releases.
    - Uncompress the zip file into your Git repository
    - Configure the `DOCKER_USERNAME:` and `DOCKER_PASSWORD:` values under the
    `environment:` data serialization in `appveyor.yml` file
    - Create a `dockerfiles` parent folder to construct your container image
    name and tag.

- Fork from the repository for use
    > If you fork the repository, you need to do the following:
    > - Delete `README.md`, `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` files
    > - Delete `./.github`, `./docs` and `./assets` folders and their content
    > - Delete any folders and files within `./dockerfiles` folder (Those
    content exists in the repository for test purposes. Of course, you can
    definitely feel free to keep them as examples or demo.)
    > - Configure the `DOCKER_USERNAME:` and `DOCKER_PASSWORD:` values under
    the `environment:` data serialization in `appveyor.yml` file
    > - Delete "`  - pwsh: .\.appveyor\scripts\powershell\Deploy-DockerImage.ps1`" on Line 78 in `appveyor.yml` file
    > - Uncomment "`#  - pwsh: .\.appveyor\scripts\powershell\Deploy-DockerImage.ps1`" on Line 82 in `appveyor.yml` file
    > - Delete everything below Line 84 in `appveyor.yml` file


## Understanding basic AppVeyor work flow

In this section, we have a brief explanation of `appveyor.yml` included in this
framework because it is already properly documented by
[AppVeyor](https://www.appveyor.com/) and you can refer to their
[documentation](https://www.appveyor.com/docs/) regarding their YAML
configuration format. We will only explain the work flow in the `appveyor.yml`
in this framework.

### How the work flow is orchestrated?

1. After a Git commit with a push/pull to your repository, AppVeyor will run
the `-pwsh:` command lines under the `init:` initialization stage. The command
lines will output the basic AppVeyor host information.
2. After the `init:` initialization stage completed, AppVeyor will run the
`install:` install stage. The command lines will output the folders and files
that has cloned from your repository in the AppVeyor host.
3. After the `install:` install stage completed, AppVeyor will run the
`build_script:` build stage that execute the `Build-DockerImage.ps1` PowerShell
script to build the container image from the `Dockerfile` using DockerCLI on
AppVeyor host.
4. After the `build_script:` build stage completed, AppVeyor will run the
`test_script:` test stage that execute the `Test-DockerImage.ps1` PowerShell
script to validate if `Test-Container.ps1` file exist within the container
folder and check if the file contains any command per line to execute against
the container for testing. If an error occurred or no output has returned from
the container, the test is considered as fail and will abort the entire CI/CD
process until the issue has been rectified.
5. After `test_script:` test stage completed without issue, AppVeyor will run
the `deploy_script:` deploy stage that execute the `Deploy-DockerImage.ps1`
PowerShell script to login to container image repository, modify container
image tag to  repository container image tag and push the container image to
the container image repository.

## Container Naming and Tagging

In this section, we will discuss how the container image name and tag are
derived and helps you organise your repository neatly when you have
multiple dockerfiles.

### What are the available container naming format?

Using this framework, you will be able to automatically create container will
the following naming format:

- Using Example A
    - nanoserver.nodejs:latest
    - nanoserver.nodejs:10.3.0
    - nanoserver.nodejs:8.11.2
    - apline.nodejs:10.3.0
    - apline.nodejs:8.11.2
    - ubuntu.nodejs:10.3.0
    - ubuntu.nodejs:8.11.2


- Using Example B
    - nodejs:10.3.0
    - nodejs:8.11.2

- Using Example C
    - nodejs:latest
    - mariadb:latest
    - mysql:latest

### Example A - 3-Tier Folder Structure

In this example below, we are trying to create a container name with the
following tag such as `ContainerParentName.ContainerChildName:ContainerTag` so
that it is deployed to the container image repository such as
`Repository/ContainerParentName.ContainerChildName:ContainerTag`.

In order to achieve that naming convention, we will have to create a 3-Tier
folder structure where the `./dockerfiles` root folder contains a
`ContainerParentName` folder, containing a `ContainerChildName` folder,
containing a `ContainerTag` folder that contains the `Dockerfile`. The
`Dockerfile` will have the full path like this
"`./dockerfiles/ContainerParentName/ContainerChildName/ContainerTag/Dockerfile`".

The structure also provides the flexiblity to use product name, project name
and version like this "`hackit.blackbelt:1.0.0`" where "`hackit`" is the name
of your product, "`blackbelt`" is project code name and "`1.0.0`" is your first
version. Or "`hackit.rhel:1.0.0`", "`hackit.ubuntu:1.0.0`",
"`hackit.windows:1.0.0`" and etc for demonstrating your application on
different platform.

```text
+__ .appveyor
+__ dockerfiles
|   +__ ContainerParentName
|   |   +__ ContainerChildName
|   |   |   +__ ContainerTag
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
.   .   .   .   .
.   .   .   .   .
-__ appveyor.yml
-__ README.md
```

### Example B - 2-Tier Folder Structure

In this example below, we are trying to create a container name with the
following tag such as `ContainerParentName:ContainerTag` so that it is deployed
to the container image repository such as
`Repository/ContainerParentName:ContainerTag`.

In order to achieve that naming convention, we will have to create a 2-Tier
folder structure where the `./dockerfiles` root folder contains a
`ContainerParentName` folder, containing a `ContainerTag` folder that contains
the `Dockerfile`. The `Dockerfile` will have the full path like this
"`./dockerfiles/ContainerParentName/ContainerTag/Dockerfile`".

This is useful for application container where you do not need to provide
platform information such as CentOS, Debian, Fedora, Mint, openSUSE, Ubuntu,
and etc because they belongs to Linux family and will run under Linux
containers engine.

```text
+__ .appveyor
+__ dockerfiles
|   +__ ContainerParentName
|   |   +__ ContainerTag
|   |   |   +__ Dockerfile
|   |   |   +__ Test-Container.ps1
.   .   .   .
.   .   .   .
-__ appveyor.yml
-__ README.md
```

### Example C - 1-Tier Folder Structure

In this example below, we are trying to create a container name with the
following tag such as `ContainerParentName:latest` so that it is deployed to
the container image repository such as `Repository/ContainerParentName:latest`.

In order to achieve that naming convention, we will have to create a 1-Tier
folder structure where the `./dockerfiles` root folder contains a
`ContainerParentName` folder that contains the `Dockerfile`. The `Dockerfile`
will have the full path like this "`./dockerfiles/ContainerParentName/Dockerfile`".

In this structure, you will always keep the latest `Dockerfile` because it will
only build the Container image with `latest` tag. This is usually used for an
one-off scenario like image development because you cannot add any more tag
with this structure.

```text
+__ .appveyor
+__ dockerfiles
|   +__ ContainerParentName
|   |   +__ Dockerfile
|   |   +__ Test-Container.ps1
.   .   .
.   .   .
-__ appveyor.yml
-__ README.md
```

### Example of multiple docker files

In this example below, we demonstrates the multiple container images with tag
being constructed under this 3-Tier, 2-Tier and 1-Tier folder structure to
illustrate the container naming convention output.

Using the tree structure below, the following containers will be generated:

- 3-Tier Structure Output
    - nanoserver.mariadb:5.5.60
    - nanoserver.mysql:5.7.22
    - nanoserver.nodejs:latest
    - nanoserver.nodejs:10.3.0
    - nanoserver.nodejs:8.11.2
    - alpine.mysql:5.7.22

- 2-Tier Structure Output
    - ubuntu:latest
    - ubuntu:16.04

- 1-Tier Structure Output
    - mint:latest
    - fedora:latest

```text
+__ .appveyor
+__ dockerfiles
|   +__ nanoserver
|   |   +__ mariadb
|   |   |   +__ 5.5.60
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   |   +__ mysql
|   |   |   +__ 5.7.22
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   |   +__ nodejs
|   |   |   +__ latest
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   |   |   +__ 10.3.0
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   |   |   +__ 8.11.2
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   +__ alpine
|   |   +__ mysql
|   |   |   +__ 5.7.22
|   |   |   |   -__ Dockerfile
|   |   |   |   -__ Test-Container.ps1
|   +__ ubuntu
|   |   +__ latest
|   |   |   -__ Dockerfile
|   |   |   -__ Test-Container.ps1
|   |   +__ 16.04
|   |   |   -__ Dockerfile
|   |   |   -__ Test-Container.ps1
|   +__ mint
|   |   -__ Dockerfile
|   |   -__ Test-Container.ps1
|   +__ fedora
|   |   -__ Dockerfile
|   |   -__ Test-Container.ps1
|   |   |   |   |
.   .   .   .   .
.   .   .   .   .
-__ appveyor.yml
-__ README.md
```