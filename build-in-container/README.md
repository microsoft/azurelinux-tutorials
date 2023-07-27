# Build-in-container
The build-in-container tool provides a developer tool to quickly build Mariner packages. It is easy-to-use, and distribution and platform agnostic. It sets up a build environment in an expedient manner using a container.

Please install docker on your system before using the tool.

## Usage
The run.sh script presents these options <br />
-t                 creates container image <br />
-b [repo_dir]      creates container, builds Mariner and outputs to out/ <br />
-i [repo_dir]      create an interactive Mariner build container <br />
-c [repo_dir]      cleans up the current workspace <br />
--help             shows help on usage <br /> <br />

- Unless provided, repo_dir defaults to the directory containing build-in-container tool <br />
- Place specs to build under $repo_dir/SPECS/ <br />
- The output from the build will be available under $repo_dir/out/ (RPMS and SRPMS) <br />
- Logs are published under $repo_dir/logs/ <br />

``` bash
# Setup the container for 1st use
cd ./CBL-MarinerTutorials
./build-in-container/run.sh -t
# Build `./SPECS/**/*.spec` automatically using the latest stable toolkit
./build-in-container/run.sh -b ./
ls ./out/RPMS/x86_64/
# hello_world_demo-1.0.0-2.cm2.x86_64.rpm  hello_world_demo-debuginfo-1.0.0-2.cm2.x86_64.rpm
# Invoke the toolkit directly
./build-in-container/run.sh -i
> #  Run the tools manually
>  make build-packages SRPM_PACK_LIST="os-subrelease"
```

## Details on what goes on inside the container:
### Creating container image
'create-build-container.sh' creates an image that the docker can use to launch the Mariner build container. It downloads a Mariner2.0 container image, and makes suitable modifications to it. The output image is tagged as 'mcr.microsoft.com/mariner-container-build:2.0'

### Running container in the specified mode
'mariner-docker-run.sh' starts a docker container using the image produced in Step(1). 

In the _build_ mode, it sets up the Mariner build system inside the container, builds all the specs under $repo_dir/SPECS/ and outputs to $repo_dir/out/.

In the _interactive_ mode, it sets up the Mariner build system inside the container, and starts the container at /mariner/toolkit/. The user can invoke Mariner `make` commands to build packages, images and more. Please see the [section](https://github.com/microsoft/CBL-MarinerTutorials/tree/main/buildInContainer/build-in-container#sample-make-commands) for sample `make` commands, and visit [Mariner Docs](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/building.md) for the complete set of commands. 

### Helper scripts

- 'scripts/setup.sh' installs the required pacakges, downloads the Mariner toolkit from GitHub (if missing), downloads Mariner2.0 toolchain RPMs, and sets up the environment variables required for Mariner builds.

- 'scripts/build.sh' The build starts with cloning the Mariner GitHub repository, and downloading the toolchain. Using the tools from Mariner toolkit, it reads the spec files under SPECS/, installs the build dependepdencies, builds the specs and packages them into an RPM. Each pacakge is built inside a chroot environment.

## Advantages:
- It is convenient and fast for developement environment
- It gives the user an option to build Mariner without having to go into the details of the build system

## Disadvantages:
- The number of chroots is limited to 12
- It is using chroot jails inside containers, and containers are known to be slow

## Sample make commands:
`make build-packages -j$(nproc)` would build specs under SPECS/ and populate out/ with the built SRPMs and RPMs
