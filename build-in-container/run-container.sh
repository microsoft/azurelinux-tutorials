#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# The toolkit may not have created these yet, create them now so we can mount them
mkdir -p ${mariner_dir}/build/rpm_cache/cache
mkdir -p ${mariner_dir}/build/toolchain_rpms
mkdir -p ${mariner_dir}/ccache
mkdir -p ${mariner_dir}/logs
mkdir -p ${mariner_dir}/out
mkdir -p ${mariner_dir}/SPECS
mkdir -p ${mariner_dir}/toolkit

run_build_container() {
    docker run --rm \
        ${mount_pts} \
        --privileged \
        --cap-add SYS_ADMIN \
        mcr.microsoft.com/mariner-container-build:2.0 /mariner/scripts/build-mariner.sh $container_args
}

run_interactive_container() {
    docker run \
        ${mount_pts} \
        --privileged \
        --cap-add SYS_ADMIN \
        -it mcr.microsoft.com/mariner-container-build:2.0 /mariner/scripts/build-mariner.sh $container_args
}

mount_pts="
    -v $mariner_dir/SPECS:/mariner/SPECS:rw \
    -v $mariner_dir/toolkit:/mariner/toolkit:rw \
    -v $tool_dir/scripts:/mariner/scripts:rw \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-1/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-1/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-1/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-1/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-1/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-1/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-1/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-2/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-2/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-2/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-2/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-2/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-2/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-2/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-3/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-3/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-3/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-3/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-3/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-3/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-3/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-4/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-4/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-4/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-4/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-4/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-4/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-4/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-5/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-5/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-5/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-5/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-5/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-5/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-5/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-6/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-6/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-6/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-6/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-6/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-6/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-6/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-7/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-7/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-7/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-7/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-7/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-7/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-7/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-8/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-8/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-8/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-8/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-8/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-8/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-8/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-9/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-9/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-9/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-9/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-9/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-9/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-9/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-10/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-10/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-10/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-10/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-10/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-10/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-10/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-11/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-11/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-11/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-11/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-11/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-11/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-11/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/temp/DockerStage/docker-chroot-12/upstream-cached-rpms:rw \
    -v $mariner_dir/ccache:/temp/DockerStage/docker-chroot-12/ccache-dir:rw \
    -v /dev:/temp/DockerStage/docker-chroot-12/dev:ro \
    -v /proc:/temp/DockerStage/docker-chroot-12/proc:ro \
    -v devpts:/temp/DockerStage/docker-chroot-12/dev/pts:ro \
    -v sysfs:/temp/DockerStage/docker-chroot-12/sys:ro \
    -v tmpfs:/temp/DockerStage/docker-chroot-12/run:ro \
    -v $mariner_dir/build/rpm_cache/cache:/mariner/build/rpm_cache/cache:rw \
    -v $mariner_dir/build/toolchain_rpms:/mariner/build/toolchain_rpms:rw \
    -v $mariner_dir/out:/mariner/out:rw \
    -v $mariner_dir/logs:/mariner/logs:rw \
    -v /dev:/dev:ro \
    -v /sys:/sys:ro
    "

container_args="--disable_mariner_repo $disable_mariner_repo --enable_custom_repofile $enable_custom_repofile  --enable_custom_repo_storage $enable_custom_repo_storage --container_type $container_type"
if [[ "${enable_custom_repofile}" == "true" ]]; then container_args+=" --RPM_repo_file /mariner/scripts/custom-repo.repo"; fi
if [[ "${enable_custom_repo_storage}" == "true" ]]; then container_args+=" --RPM_storage $RPM_storage"; fi

if [ "$container_type" == "build" ]; then run_build_container; return; fi
if [ "$container_type" == "interactive" ]; then run_interactive_container; return; fi
