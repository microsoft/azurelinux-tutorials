#! /bin/bash

mkdir -p build/rpm_cache/cache
mkdir -p build/toolchain_rpms
mkdir -p out
mkdir -p ccache

create_build_container() {
    docker run \
        ${mount_pts} \
        --privileged \
        msft/mariner-toolchain:2.0 sources/scripts/build_mariner.sh
}

create_interactive_container() {
    docker run \
        ${mount_pts} \
        --privileged \
        -it msft/mariner-toolchain:2.0 /bin/bash
}

mount_pts="
    -v $(pwd):/sources:rw \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-1/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-1/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-1/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-1/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-1/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-1/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-1/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-2/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-2/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-2/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-2/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-2/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-2/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-2/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-3/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-3/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-3/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-3/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-3/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-3/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-3/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-4/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-4/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-4/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-4/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-4/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-4/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-4/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-5/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-5/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-5/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-5/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-5/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-5/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-5/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-6/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-6/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-6/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-6/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-6/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-6/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-6/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-7/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-7/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-7/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-7/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-7/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-7/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-7/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-8/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-8/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-8/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-8/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-8/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-8/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-8/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-9/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-9/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-9/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-9/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-9/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-9/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-9/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-10/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-10/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-10/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-10/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-10/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-10/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-10/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-11/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-11/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-11/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-11/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-11/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-11/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-11/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-12/upstream-cached-rpms:rw \
    -v $(pwd)/ccache:/temp/DockerStage/docker-chroot-12/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-12/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-12/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-12/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-12/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-12/run:ro \
    -v $(pwd)/build/rpm_cache/cache:/tmp/mariner/build/rpm_cache/cache:rw \
    -v $(pwd)/build/toolchain_rpms:/tmp/mariner/build/toolchain_rpms:rw \
    -v $(pwd)/out:/tmp/mariner/out:rw \
    "

local container_type=("$@")
if [ "$container_type" == "build" ]; then create_build_container; return; fi
if [ "$container_type" == "interactive" ]; then create_interactive_container; return; fi
