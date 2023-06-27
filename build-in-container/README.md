The build-in-container tool provides the user with an easy-to-use, distribution and platform agnostic, container build for Mariner packages. The container is complete and independent, and eliminates the requirement for the user to interact with Mariner toolkit to build packages.

To use,
- step1: (one time setup)
Run 'create-build-container.sh' to create an image that the docker can use to launch the Mariner build container

- step2:
Run 'mariner-docker-run.sh' to start the docker container using the image produced in Step(1), setup the Mariner build system inside the container, and build Mariner packages.
Place specs under SPECS/
The output from build will be available under out/ (RPMS and SRPMS)

Details on what goes on inside the container:
- The container installs the necessary packages required for the build setup, and sets up the directory structure for build. This is achieved by setup.sh under scripts/

- The build starts with cloning the Mariner GitHub repository, and downloading the toolchain. Using the tools from Mariner toolkit, it reads the spec files under SPECS/, installs the build dependepdencies, builds the specs and packages them into an RPM. Each pacakge is built inside a chroot environment. This is achieved by the build.sh under scripts/
