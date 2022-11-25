#!/bin/bash
source set-env.sh
source functions.sh

echo -e "\n\nBuilding Hadoop ${HADOOP_VERSION}"
dist_file="$DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz"
src_file="$TMP_DIR/hadoop-${HADOOP_DISTRO}.src.tar.gz"

# already done?
if [[ -e "$dist_file" ]]; then
    echo "   already built: `ls -l $DOCKER_HOME/dist/hadoop-${distro}.tar.gz`"
    exit 0
fi

# hadoop versions data
HADOOP_VERSIONS=`json_load hadoop ${HADOOP_VERSION}`

# ensure our build env is ready
function path_build_env(){
    cd "$1"
    # check our modified version of start-build-env script
    if [[ ! -e modified-build-env.sh ]]; then
        if [[ -e start-build-env.sh ]]; then
            echo "   setting modified_build_env.sh"
            echo "   cp start-build-env.sh  modified-build-env.sh"
            cp start-build-env.sh  modified-build-env.sh

            # to make the patch file 
            # diff -Naur start-build-env.sh modified-build-env.sh 
            echo "   PATCH -p1 < ${DOCKER_HOME}/modified-build-env.patch"
            $PATCH -p1 < ${DOCKER_HOME}/modified-build-env.patch
        else
            echo >&2 "$1 is missing the start-build-env.sh script"
            exit 1
        fi
    fi
}

function compile_hadoop(){
    cd "$1"
    # start build environement 
    current_distro=`cat pom.xml| grep "<hadoop.version>" | grep -Eo '>[^<]+' | cut -b 2- `
    ./modified-build-env.sh <<EOF
    cd hadoop
    echo "Hadoop version: ${HADOOP_VERSION}"

    if [[ ! "$current_distro" = "$HADOOP_DISTRO" ]]; then
        echo "   changing hadoop version from ${current_distro} to ${HADOOP_DISTRO}"
        mvn versions:set -DgenerateBackupPoms=false -DnewVersion=${HADOOP_DISTRO}
        sed -i "s/<hadoop.version>${HADOOP_VERSION}<\/hadoop.version>/<hadoop.version>${HADOOP_DISTRO}<\/hadoop.version>/" pom.xml
        mvn clean
    fi
    
    echo "   building hadoop-${HADOOP_DISTRO}"
    mvn package install -Pdist -Dtar -DskipTests -Dmaven.javadoc.skip=true
    exit
EOF
    if [[ -e $1/hadoop-dist/target/hadoop-${HADOOP_DISTRO}.tar.gz ]]; then
        cp   $1/hadoop-dist/target/hadoop-${HADOOP_DISTRO}.tar.gz  "$dist_file"
        echo "  success $dist_file"
    fi
}

case "$HADOOP_MODE" in
    OFFICIAL)
        download_distrib "${dist_file}" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "BIN"
        ;;
    SOURCE)
        download_distrib "${src_file}" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "SRC"
        untar "${src_file}" "$TMP_DIR/src/hadoop"
        apply_patches "$TMP_DIR/src/hadoop" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "$DOCKER_HOME/hadoop"
        path_build_env "$TMP_DIR/src/hadoop"
        compile_hadoop "$TMP_DIR/src/hadoop"
        ;;
    REPO)
        clone_repo_at "$TMP_DIR/git/hadoop" "${HADOOP_VERSIONS}" "rel/release-${HADOOP_VERSION}"
        if [[ "$1" == "--reset" ]]; then
            clean_repo "$TMP_DIR/git/hadoop"
            exit 0
        fi
        ;;
esac

exit 0


if [[ "$1" = "--reset" ]]; then
    if [[ -d $DOCKER_HOME/hadoop ]]; then
        cd $DOCKER_HOME/hadoop
        current_release=`git log -n 1 --pretty=%d HEAD | grep -Eo "rel/release-[0-9]+\.[0-9]+\.[0-9]+"`
        echo "Cleaning hadoop ${current_release}"
        git reset --hard
        git clean -fd
        rm -rf ~/.m2/repository/*
        cd $DOCKER_HOME
    else
        echo "Cleaning hadoop: nothing to do "
    fi
    exit 0
fi

if [[ ! -d $DOCKER_HOME/dist ]]; then
    mkdir -p $DOCKER_HOME/dist
fi

if [[ -e $DOCKER_HOME/dist/hadoop-${distro}.tar.gz ]]; then
    echo "   already built: `ls -l $DOCKER_HOME/dist/hadoop-${distro}.tar.gz`"

elif [[ "$HADOOP_MODE" = "OFFICIAL" ]]; then
    URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${distro}.tar.gz"
    SHA="https://downloads.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz.sha512"
    ASC="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${distro}.tar.gz.asc"
    KEY="https://downloads.apache.org/hadoop/common/KEYS"
    FILE="hadoop-${distro}.tar.gz"
    DEST="$DOCKER_HOME/dist/hadoop-${distro}.tar.gz"

    download_distrib "$FILE" "$URL" "$SHA" "$ASC" "$KEY" "$DEST"

    
elif [[ "$HADOOP_MODE" = "COMPILE" ]]; then
    # we are goind to compile it
    if [[ ! -d $DOCKER_HOME/hadoop ]]; then
        echo -e "git clone https://github.com/apache/hadoop.git"
        git clone "https://github.com/apache/hadoop.git"
    fi

    cd $DOCKER_HOME/hadoop
    # check release version
    current_release=`git log -n 1 --pretty=%d HEAD | grep -Eo "rel/release-[0-9]+\.[0-9]+\.[0-9]+"`
    if [[ ! "$current_release" = "${release}" ]]; then
        echo "   cleaning and changing from ${current_release} to ${release}"
        git reset --hard
        git clean -fd
        git checkout "${release}"
    fi

    # current distribution version (did we chaned pom)
    current_distro=`cat pom.xml| grep "<hadoop.version>" | grep -Eo '>[^<]+' | cut -b 2- `
    if [[ ! "$current_distro" = "$distro" ]]; then
        echo "   cleaning from ${current_distro} to ${distro}"
        git reset --hard
        current_distro=`cat pom.xml| grep "<hadoop.version>" | grep -Eo '>[^<]+' | cut -b 2- `
    fi

    # check our modified version of start-build-env script
    if [[ ! -e modified-build-env.sh ]]; then
        echo "   setting modified_build_env.sh"
        cp start-build-env.sh modified-build-env.sh
        git apply ${DOCKER_HOME}/modified-build-env.patch
    fi

    # start build environement 
    ./modified-build-env.sh <<EOF
    cd hadoop
    echo "Hadoop version: ${HADOOP_VERSION}"

    if [[ ! "$current_distro" = "$distro" ]]; then
        echo "   changing hadoop version from ${current_distro} to ${distro}"
        mvn versions:set -DgenerateBackupPoms=false -DnewVersion=${distro}
        sed -i "s/<hadoop.version>${HADOOP_VERSION}<\/hadoop.version>/<hadoop.version>${distro}<\/hadoop.version>/" pom.xml
        mvn clean
    fi
    
    echo "   building hadoop-${distro}"
    mvn package install -Pdist -Dtar -DskipTests -Dmaven.javadoc.skip=true
    exit
EOF
    if [[ -e $DOCKER_HOME/hadoop/hadoop-dist/target/hadoop-${distro}.tar.gz ]]; then
        cp $DOCKER_HOME/hadoop/hadoop-dist/targethadoop-${distro}.tar.gz  $DOCKER_HOME/dist/
        echo "  success ./dist/hadoop-${distro}.tar.gz"
    fi
else
    echo "Invalide HADOOP_MODE=${HADOOP_MODE}"
fi
cd $DOCKER_HOME


