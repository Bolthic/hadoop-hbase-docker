#!/bin/bash
source set-env.sh
source functions.sh

echo -e "\n\nBuilding HBase ${HBASE_VERSION}"
dist_file="$DOCKER_HOME/dist/hbase-${HBASE_DISTRO}-bin.tar.gz"
dist_client_file="$DOCKER_HOME/dist/hbase-${HBASE_DISTRO}-client-bin.tar.gz"
src_file="$TMP_DIR/hbase-${HBASE_DISTRO}.src.tar.gz"


if [[ ! -d $DOCKER_HOME/dist ]]; then
    mkdir -p $DOCKER_HOME/dist
fi

# already done?
if [[ -e "$dist_file" ]]; then
    echo "   already built: `ls -l $dist_file`"
    exit 0
fi

# hadoop versions data
HBASE_VERSIONS=`json_load hbase ${HBASE_VERSION}`

# ensure our build env is ready
function path_build_env(){
    cd "$1/../hadoop"
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

function compile_hbase(){
    cd "$1"
    # start build environement 
    current_distro=`cat pom.xml| grep "<hadoop.version>" | grep -Eo '>[^<]+' | cut -b 2- `

    ../hadoop/modified-build-env.sh <<EOF
    cd hbase
    echo "HBAse version: ${HBASE_VERSION}"

    if [[ ! "$current_distro" = "$HBASE_DISTRO" ]]; then
        echo "   changing hbase version from ${current_distro} to ${HBASE_DISTRO}"
        mvn versions:set -DgenerateBackupPoms=false -DnewVersion=${HBASE_DISTRO}
        mvn clean
    fi
    
    echo "   building hbase-${HBASE_DISTRO} - ${HADOOP_DISTRO}"
    mvn clean -DskipTests -Dhadoop.profile=${HBASE_HADOOP_PROFILE} -Dhadoop-three.version=${HADOOP_DISTRO} package assembly:single install
    exit
EOF
    if [[ -e $1/hbase-assembly/target/hbase-${HBASE_DISTRO}-bin.tar.gz ]]; then
        cp   $1/hbase-assembly/target/hbase-${HBASE_DISTRO}-bin.tar.gz "$dist_file"
        echo "  success $dist_file"
    fi
    if [[ -e $1/hbase-assembly/target/hbase-${HBASE_DISTRO}-client-bin.tar.gz ]]; then
        cp   $1/hbase-assembly/target/hbase-${HBASE_DISTRO}-client-bin.tar.gz "$dist_client_file"
        echo "  success $dist_client_file"
    fi

}

case "$HBASE_MODE" in
    OFFICIAL)
        download_distrib "${dist_file}" "${HBASE_VERSIONS}" "${HBASE_VERSION}" "BIN"
        cd $DOCKER_HOME
        exit 0
        ;;
    SOURCE)
        if [[ "$1" == "--reset" ]]; then
            rm -rf ~/.m2/repository/*
        fi
        download_distrib "${src_file}" "${HBASE_VERSIONS}" "${HBASE_VERSION}" "SRC"
        untar "${src_file}" "$TMP_DIR/src/hbase" "$1"
        apply_patches "$TMP_DIR/src/hbase" "${HBASE_VERSIONS}" "${HBASE_VERSION}" "$DOCKER_HOME/hbase"
        path_build_env "$TMP_DIR/src/hbase"
        compile_hbase "$TMP_DIR/src/hbase"
        cd $DOCKER_HOME
        exit 0
        ;;
    REPO)
        clone_repo_at "$TMP_DIR/git/hbase" "${HBASE_VERSIONS}" "branch-${HBASE_VERSION}"
        if [[ "$1" == "--reset" ]]; then
            clean_repo "$TMP_DIR/git/hbase"
            rm -rf ~/.m2/repository/*
        fi
        apply_patches "$TMP_DIR/git/hbase" "${HBASE_VERSIONS}" "${HBASE_VERSION}" "$DOCKER_HOME/hbase"
        path_build_env "$TMP_DIR/git/hbase" 
        compile_hadoop "$TMP_DIR/git/hbase" s
        cd $DOCKER_HOME
        exit 0
        ;;
esac


