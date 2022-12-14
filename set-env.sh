#!/bin/bash
PWD=`pwd`
USER=`id -u -n`
DOCKER_HOME=${DOCKER_HOME-$PWD}
DOCKER_OWNER=${DOCKER_OWNER-$USER}
BUILD_VERSION=${BUILD_VERSION-"1.0"}
TMP_DIR=${TMP_DIR-"$PWD/tmp"}

# HADOOP_MODE can be COMPILE or OFFICIAL
HADOOP_VERSION=${HADOOP_VERSION-"3.3.4"}
#HADOOP_MODE=${HADOOP_MODE-"OFFICIAL"}
HADOOP_MODE=${HADOOP_MODE-"SOURCE"}
#HADOOP_MODE=${HADOOP_MODE-"REPO"}


# HBASE_MODE can be COMPILE or OFFICIAL
HBASE_MODE=${HBASE_MODE-"SOURCE"}
# HBASE_MODE=${HABSE_MODE-"OFFICIAL"}
# HBASE_MODE=${HADOOP_MODE-"REPO"}

HBASE_VERSION=${HBASE_VERSION-"2.4.15"}
HBASE_HADOOP_PROFILE=${HBASE_HADOOP_PROFILE-"3.0"}

PWD=`pwd`
if [[ "${HADOOP_MODE}" = "REPO" ]]; then
    HADOOP_DISTRO="${HADOOP_VERSION}-hadoop-hbase-${BUILD_VERSION}"
else
    if [[ ! "${HADOOP_MODE}" = "OFFICIAL" ]] && [[ ! "${HADOOP_MODE}" = "SOURCE" ]]; then
        echo "unknown HADOOP_MODE=${HADOOP_MODE}, defaulting to OFFICIAL"
        HADOOP_MODE="OFFICIAL"
    fi
    HADOOP_DISTRO="${HADOOP_VERSION}"
fi
if [[ "${HBASE_MODE}" = "REPO" ]]; then
    HBASE_DISTRO="${HBASE_VERSION}-hadoop-hbase-${BUILD_VERSION}"
else
    if [[ "$HBASE_HADOOP_PROFILE" = "3.0" ]]; then
        if [[ ! "${HBASE_MODE}" = "OFFICIAL" ]] && [[ ! "${HBASE_MODE}" = "SOURCE" ]]; then
            echo "unknown HBASE_MODE=${HBASE_MODE} defaulting to SOURCE"
            HBASE_MODE="SOURCE"
        fi
        HBASE_DISTRO="${HBASE_VERSION}-hadoop-${HADOOP_VERSION}"
    else
        if [[ ! "${HBASE_MODE}" = "OFFICIAL" ]] && [[ ! "${HBASE_MODE}" = "SOURCE" ]]; then
            echo "unknown HBASE_MODE=${HBASE_MODE} defaulting to OFFICIAL"
            HBASE_MODE="OFFICIAL"
        fi
        HBASE_DISTRO="${HBASE_VERSION}"
    fi
fi