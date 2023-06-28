# Build-in-container
The build-in-container tool provides the user with an easy-to-use, distribution and platform agnostic, container build for Mariner packages. The container is complete and independent, and eliminates the requirement for the user to interact with Mariner toolkit to build packages.

Please install docker on your system before using the tool.

## Usage
The run.sh script presents these options
-t      creates container image
-b      creates container and builds Mariner
-i      create interactive Mariner build container
-c      cleans up the current workspace
--help  shows help

## Details on what goes on inside the container:
- 'create-build-container.sh' creates an image that the docker can use to launch the Mariner build container. It downloads a Mariner2.0 container image, and makes suitable modifications to it. The image is tagged as 'msft/mariner-toolchain:2.0'

- 'mariner-docker-run.sh' starts a docker container using the image produced in Step(1), setup the Mariner build system inside the container, and build Mariner packages. 

**Place specs to build under SPECS/**

**The output from the build will be available under out/ (RPMS and SRPMS)**

- The container installs the necessary packages required for the build setup, and sets up the directory structure for build. This is achieved by 'setup.sh' under scripts/

- The build starts with cloning the Mariner GitHub repository, and downloading the toolchain. Using the tools from Mariner toolkit, it reads the spec files under SPECS/, installs the build dependepdencies, builds the specs and packages them into an RPM. Each pacakge is built inside a chroot environment. This is achieved by the 'build.sh' under scripts/

## Advantages:
- It is convenient and useful for developement environment
- It lets the user build Mariner without having to go into much details on the build system

## Disadvantages:
- The number of chroots is limited to 12
- It is using chroot jails inside containers, and containers are known to be slow
