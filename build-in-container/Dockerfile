FROM mcr.microsoft.com/onebranch/cbl-mariner/build:2.0

RUN mkdir -m 777 -p /sources && \
    ln -s /usr/src/linux /sources && \
    for i in $(seq 1 12); do \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/dev/pts; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/dev/null; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/proc; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/sys; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/run; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/localrpms/noarch; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/localrpms/aarch64; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/localrpms/x86_64; \
                mkdir -m 777 -p /temp/DockerStage/docker-chroot-$i/localrpms/upstream-cached-rpms; \
    done

 

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
 

RUN tdnf update -qy tdnf && \
        tdnf -y install \
                binutils \
                bison \
                cdrkit \
                curl \
                dnf \
                dnf-utils \
                dosfstools \
                gawk \
                gcc \
                git \
                glibc-devel \
                golang-1.17.13-1.cm2 \
                kernel-headers \
                make \
                parted \
                pigz \
                python3 \
                qemu-img \
                rpm \
                rpm-build \
                rsync \
                sudo \
                tar \
                wget
