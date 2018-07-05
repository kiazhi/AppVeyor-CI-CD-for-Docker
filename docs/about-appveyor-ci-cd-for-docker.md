---
title: About AppVeyor CI/CD for Docker
author: Kia Zhi Tang (Ryen Tang)
date: 04/07/2018
categories: [about, documentation]
tags: [about, documentation]
---

# About AppVeyor CI/CD for Docker

A page about AppVeyor CI/CD for Docker.

## What is AppVeyor CI/CD for Docker?

`kiazhi/AppVeyor-CI-CD-for-Docker` is a complementary open-source container
build, test and deploy framework for continuous integration (CI)
`build_script:`, `test_script:`, and continuous delivery (CD) `deploy_script:`
on AppVeyor YAML file to orchestrate the process flow with PowerShell scripts.

In short, it is an [AppVeyor](https://www.appveyor.com/) CI/CD automation
framework for building, testing and deploying of Docker container images from
`Dockerfile` during a git push/pull scenario.

## How did this project came about?

This `kiazhi/AppVeyor-CI-CD-for-Docker` project began its journey as a side
project of
[kiazhi/Windows-Containers](https://github.com/kiazhi/Windows-Containers)
project that plans to contain multiple Windows container image (`Dockerfile`)
configuration templates. Since the parent project started to grow with multiple
different variety of application container, there is a need to address the
amount of manual process to build, test and deploy to the public repository in
[Docker Hub](https://hub.docker.com/u/kiazhi/).
