
# Introduction

The [CBL-Mariner](https://github.com/microsoft/CBL-Mariner) repository provides detailed instructions for building CBL-Mariner from end-to-end.  While it is possible to clone CBL-Mariner and build packages or images from that environment, for most users, it is _not the recommended approach_.  Usually it is best to work in a smaller, problem focused environment where you can quickly build just what you need, and rely on the fact that the curated CBL-Mariner packages are already available in the cloud. In this way, you can customize an image with your preferred disk layout or adding supplemental packages that CBL-Mariner may not provide.  If you are building a product based on CBL-Mariner, you may want your own repository with just the minimal set of packages for your business needs.  This repo, the CBL-MarinerTutorials repo, provides a basic template for getting started.  From here you can create a CBL-Mariner based product (aka a Derivative Image) or you may generate quick experimental or debug builds to try out new ideas.

When you build an ISO, VHD or VHDX image from this repository,  the resulting image will contain additional content unavailable in the CBL-Mariner repo.  The CBL-MarinerTutorials repository demonstrates how you can augment CBL-Mariner without forking the CBL-Mariner repository.  This repository contains the SPEC file and source for building a simple "Hello World" application.  This repository also includes a simple "os-subrelease" package that allows you to add identifying information about your derivative to an /etc/os-subrelease file.  

Follow this decision tree to ensure you are using the correct repository for your use case:

```mermaid
---
title: Repo decision tree
---
flowchart TD
    id1{{Do you want to experiment with Mariner or contribute to Mariner?}}

    id2A[Do you want to build locally with Mariner?]
    id2B[Do you want to add an unsupported package? \n either a package Mariner has never supported \nor an updated major/minor version of a package Mariner supports]
    id2C[Do you want to use Mariner for your project? \n ex. bare metal, IoT, embedded devices, etc.]
    id2D[Use the CBL-MarinerTutorials repo]
    id1 -->|experiment| id2A
    id2A -.-|or| id2B
    id2B -.-|or| id2C
    id2C -->|yes to any of the above| id2D
    

    id3[Do you want to fix an issue in Mariner?]
    id3B[Do you want to add a common package? \n either a package supported by another major distro \nor a package used widely across popular open-source projects]
    id3C[Do you want to modify a supported Mariner package?]
    id3D[Do you want to rebuild Mariner from end-to-end?]
    id3E[Use the CBL-Mariner repo]
    id1 --> |contribute|id3
    id3 -.-|or| id3B
    id3B -.-|or| id3C
    id3C -.-|or| id3D
    id3D-->|yes to any of the above|id3E

```

# Tutorial Table of Contents

- [Getting Started](docs/getting_started/prepare_environment.md)
    - Tutorial: Prepare your Environment
- [Working with Packages](docs/packages/working_with_packages.md)
    - Image Config File
    - Tutorial: Customize your Image with Pre-built Packages
    - Tutorial: Customize your Image with Unsupported Packages
- [Modify the Kernel](docs/kernel/modify_kernel.md)
    - Tutorial: Modify the Image Kernel
- [Building an Image](docs/building/building.md)
    - Tutorial: Build a Demo VHD or VHDX Image
    - Tutorial: Build a Demo ISO Image
    - [Automate VHD or VHDX Creation 'packer'](imaging-from-packer/Readme.md)