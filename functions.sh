#!/bin/bash

function check_command(){
    cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        export "${cmd^^}"="`command -v ${cmd}`"
    else
        echo >&2 "I require ${cmd} but it's not installed.  Aborting.";
        exit 1;
    fi
}


function json_load(){
    f1="$1/versions.json"
    f2="$1/$2/version.json"
    if [[ ! -e $f1 ]]; then
        echo >&2 "Missing config file $f1"
        exit 1
    fi
    if [[ ! -e $f2 ]]; then
        echo >&2 "Missing config file $f2"
        exit 1
    fi
    $JQ -s 'add' $f1 $f2
}

function json_extract(){
    echo "$1" | $JQ -r "$2"
}

function download_distrib(){
    DEST="$1"
    VERSION=`json_extract "$2" '."'$3'".'$4`
    DL=`json_extract "$2" ".COMMON.DL"`
    URL=`json_extract "$2" ".COMMON.URL"`
    KEYS=`json_extract "$2" ".COMMON.KEYS"`
    DL_FILE=`json_extract "$VERSION" .URL`
    SHA_FILE=`json_extract "$VERSION" .SHA`
    ASC_FILE=`json_extract "$VERSION" .ASC`
    FILE=`basename "${DL_FILE}"`

    mkdir -p ${TMP_DIR}/dl
    cd "${TMP_DIR}"/dl

    echo "   $CURL --silent -o ${FILE} ${DL}/${DL_FILE}" 
    $CURL --silent -o "${FILE}" "${DL}/${DL_FILE}"
    echo "   $CURL --silent -o ${FILE}.sha ${URL}/${SHA_FILE}" 
    $CURL --silent -o "${FILE}.sha" "${URL}/${SHA_FILE}"
    echo "   $CURL --silent -o ${FILE}.asc ${URL}/${ASC_FILE}" 
    $CURL --silent -o "${FILE}.asc" "${URL}/${ASC_FILE}"
    echo "   $CURL --silent -o ${FILE}.keys ${KEYS}" 
    $CURL --silent -o "${FILE}.keys" "${KEYS}"

    echo "   $GPG --import ${FILE}.keys"
    $GPG --import "${FILE}.keys" 2>/dev/null
    echo "   $SHASUM -c ${FILE}.sha"
    if $SHASUM -c "${FILE}.sha" >/dev/null; then
        echo "   $GPG --verify ${FILE}.asc ${FILE}"
        if $GPG --verify "${FILE}.asc" "${FILE}" 2>/dev/null; then
            echo "   File is ok"
            cp "${FILE}" "${DEST}"
            rm -f "${FILE}" "${FILE}.sha" "${FILE}.asc" "${FILE}.keys"
        else
            echo >&2 "   Failed: shasum ok but gpg signature failed"
        fi
    else
        echo "   $GPG --verify ${FILE}.asc ${FILE}"
        if $GPG --verify "${FILE}.asc" "${FILE}" 2>/dev/null; then
            echo >&2 "   Failed: shasum failed but gpg signature succeed"
        else
            echo >&2"   Failed: both shasum and gpg signature failed"
        fi
    fi
}

function untar(){
    SRC="$1"
    DEST="$2"
    DEST_DIR=`dirname "${DEST}"`
    DEST_NAME=`basename "${DEST}"`

    if [[ -L "${DEST}" ]]; then
        echo "   removing old link: ${DEST}"
        rm -rf "${DEST}"
    fi

    mkdir -p "${DEST_DIR}"
    cd "${DEST_DIR}"

    echo "   $TAR xvzf $SRC"
    DIRS=`$TAR xvzf "$SRC" | cut -d/ -f1 | sort -u`
    if [[ `echo "$DIRS"| wc -l` -ne 1 ]]; then
        echo 2>1& " Multiple path created by tar (xvzf): $DIRS"
        exit 1
    else
        echo "   ln -s $DIRS $DEST_NAME"
        ln -s $DIRS $DEST_NAME
    fi
}

function apply_patches(){
    DEST="$1"
    SRC="$4/$3"
    cd "$DEST"
    for p in `json_extract "$2" '."'$3'".SRC.PATCH | .[] '`; 
    do
        echo "   Applying: $p"
        $PATCH -p1 < ${SRC}/$p
    done
}

function clone_repo_at(){
    DEST="$1"
    DEST_DIR=`dirname $DEST`
    REPO=`json_extract "$2" ".COMMON.REPO"`

    mkdir -p ${DEST_DIR}
    if [[ -L $DEST ]]; then
        rm -f $DEST
    fi 

    if [[ ! -d ${DEST}.git ]]; then
        echo -e "   git clone $REPO"
        git clone "$REPO" ${DEST}.git
    fi
    ln -s ${DEST}.git ${DEST}
}

function clean_repo(){
    DEST="$1"
    cd $DEST
    echo "   cleaning repo $DEST"
    git reset --hard
    git clean -fd
}

# checking for commandss
check_command curl
check_command docker
check_command gpg
check_command jq
check_command patch
check_command shasum
check_command tar

