#!/bin/bash
source set-env.sh
source functions.sh

echo -e "\n\nBuilding Hadoop ${HADOOP_VERSION}"
dist_file="$DOCKER_HOME/dist/hadoop-${HADOOP_DISTRO}.tar.gz"
src_file="$TMP_DIR/hadoop-${HADOOP_DISTRO}.src.tar.gz"


if [[ ! -d $DOCKER_HOME/dist ]]; then
    mkdir -p $DOCKER_HOME/dist
fi

# already done?
if [[ -e "$dist_file" ]]; then
    echo "   already built: `ls -l $dist_file`"
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
        cd $DOCKER_HOME
        exit 0
        ;;
    SOURCE)
        if [[ "$1" == "--reset" ]]; then
            rm -rf ~/.m2/repository/*
        fi
        download_distrib "${src_file}" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "SRC"
        untar "${src_file}" "$TMP_DIR/src/hadoop" "$1"
        apply_patches "$TMP_DIR/src/hadoop" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "$DOCKER_HOME/hadoop"
        path_build_env "$TMP_DIR/src/hadoop"
        compile_hadoop "$TMP_DIR/src/hadoop"
        cd $DOCKER_HOME
        exit 0
        ;;
    REPO)
        clone_repo_at "$TMP_DIR/git/hadoop" "${HADOOP_VERSIONS}" "branch-${HADOOP_VERSION}"
        if [[ "$1" == "--reset" ]]; then
            clean_repo "$TMP_DIR/git/hadoop"
            rm -rf ~/.m2/repository/*
        fi
        apply_patches "$TMP_DIR/git/hadoop" "${HADOOP_VERSIONS}" "${HADOOP_VERSION}" "$DOCKER_HOME/hadoop"
        path_build_env "$TMP_DIR/git/hadoop"
        compile_hadoop "$TMP_DIR/git/hadoop"
        cd $DOCKER_HOME
        exit 0
        ;;
esac


