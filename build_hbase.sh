#!/bin/bash
source set-env.sh

echo -e "\n\nBuilding HBase ${HBASE_VERSION}"
distro="$HBASE_DISTRO"
hadoop_distro="${HADOOP_VERSION}-hadoop-hbase-${BUILD_VERSION}"
release="rel/${HBASE_VERSION}"
if [[ ! -d $DOCKER_HOME/hbase ]]; then
    echo -e "git clone https://github.com/apache/hbase.git"
    git clone "https://github.com/apache/hbase.git"
fi
cd $DOCKER_HOME/hbase

if [[ -e $DOCKER_HOME/dist/hbase-$distro-bin.tar.gz ]]; then
    echo "   already built: `ls -l hadoop-dist/target/hadoop-${distro}.tar.gz`"
else
    # check release version
    current_release=`git log -n 1 --pretty=%d HEAD | grep -Eo "rel/[0-9]+\.[0-9]+\.[0-9]+"`
    if [[ ! "$current_release" = "${release}" ]]; then
        echo "   cleaning and changing from ${current_release} to ${release}"
        git reset --hard
        git clean -fd
        git checkout "${release}"
    fi

    # current distribution version (did we chaned pom)
    current_distro=`cat pom.xml| | grep -A1 "<artifactId>hbase</artifactId>" | grep version | grep -Eo '>[^<]+' | cut -b 2- `
    if [[ ! "$current_distro" = "$distro" ]]; then
        echo "   cleaning from ${current_distro} to ${distro}"
        git reset --hard
        current_distro=`cat pom.xml| grep -A1 "<artifactId>hbase</artifactId>" | grep version | grep -Eo '>[^<]+' | cut -b 2- `
    fi

    if [[ ! -d $DOCKER_HOME/hadoop ]]; then
        echo "   Aborting missing hadoop repo: $DOCKER_HOME/hadoop"
    else
        # going in hadoop repo for buil environnement
        cd $DOCKER_HOME/hadoop
        if [[ ! -e modified_build_env.sh ]]; then
            echo "   setting modified_build_env.sh"
            cp start-build-env.sh modified_build_env.sh
            git apply ${DOCKER_HOME}/modified-build-env.patch
        fi

        # start build environement 
        ./modified_build_env.sh <<EOF
        cd hbase
        echo "HBase version: ${HBase_VERSION}"

        if [[ ! "$current_distro" = "$distro" ]]; then
            echo "   changing hbase version from ${current_distro} to ${distro}"
            mvn versions:set -DgenerateBackupPoms=false -DnewVersion=${distro}
            mvn clean
        fi
        
        echo "   building hbase-${distro}"
        mvn clean -DskipTests -Dhadoop.profile=3.0 -Dhadoop-three.version=${hadoop_distro} \
            package assembly:single install
        exit
EOF
        if [[ -e $DOCKER_HOME/hbase/hbase-assembly/target/hbase-$distro-bin.tar.gz ]]; then
            cp $DOCKER_HOME/hbase/hbase-assembly/target/hbase-$distro-bin.tar.gz  $DOCKER_HOME/dist/
            echo "  success ./dist/hbase-$distro-bin.tar.gz"
        fi
    fi
fi
cd $DOCKER_HOME
