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
    if [ ! -d "$1" ]; then
        echo >&2 "Missing project directory: $1"
        exit 1
    fi
    if [ ! -d "$1/$2" ]; then
        echo >&2 "Missing version directory: $1/$2"
        exit 1
    fi

    f1="$1/versions.json"
    f2="$1/$2/version.json"
    if [[ ! -e $f1 ]]; then
        echo >&2 "Missing common config file $f1"
        exit 1
    fi
    if [[ ! -e $f2 ]]; then
        echo >&2 "Missing version config file $f2"
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
    sed -i 's/hadoop-3.3.6.*.tar.gz/hadoop-3.3.6.tar.gz/' "${FILE}.sha"
    
    if $SHASUM -c "${FILE}.sha" >/dev/null; then
        echo "   $GPG --verify ${FILE}.asc ${FILE}"
        if $GPG --verify "${FILE}.asc" "${FILE}" 2>/dev/null; then
            echo "   File is ok"
            cp "${FILE}" "${DEST}"
            rm -f "${FILE}" "${FILE}.sha" "${FILE}.asc" "${FILE}.keys"
        else
            echo >&2 "   Failed: shasum ok but gpg signature failed"
            exit 1
        fi
    elif [[ "`cat ${FILE}.sha`" = "`$GPG --print-md SHA512 ${FILE}`" ]]; then
        echo "   $GPG --verify ${FILE}.asc ${FILE}"
        if $GPG --verify "${FILE}.asc" "${FILE}" 2>/dev/null; then
            echo "   File is ok"
            cp "${FILE}" "${DEST}"
            rm -f "${FILE}" "${FILE}.sha" "${FILE}.asc" "${FILE}.keys"
        else
            echo >&2 "   Failed: shasum ok but gpg signature failed"
            exit 1
        fi
    else
        echo "   $GPG --verify ${FILE}.asc ${FILE}"
        if $GPG --verify "${FILE}.asc" "${FILE}" 2>/dev/null; then

            shamod=`grep -Eo 'SHA[0-9]+' "${FILE}.sha" | grep -Eo '[0-9]+'`
            shakey=`grep -Eo '[0-9a-z]{60,800}' "${FILE}.sha"`
            shaval=`shasum -a $shamod ${FILE} | grep -Eo '[0-9a-z]{60,800}'`
            echo trying "$shamod" 
            echo "   shakey= $shakey"
            echo "   shaval= $shaval"
            if [[ "$shakey" = "$shaval" ]]; then
                echo "   File is ok"
                cp "${FILE}" "${DEST}"
                rm -f "${FILE}" "${FILE}.sha" "${FILE}.asc" "${FILE}.keys"            
            else
                echo >&2 "   Failed: shasum failed but gpg signature succeed"
                exit 1
            fi
        else
            echo >&2"   Failed: both shasum and gpg signature failed"
            exit 1
        fi
    fi
}

function untar(){
    SRC="$1"
    DEST="$2"
    DEST_DIR=`dirname "${DEST}"`
    DEST_NAME=`basename "${DEST}"`
    RESET="$3"

    if [[ -L "$DEST" ]] && [[ "$RESET" = "--reset" ]]; then
        OLD_DIR=`$READLINK -f ${DEST}`
        if [[ -d "$OLD_DIR" ]]; then
            rm -rf "$OLD_DIR"
        fi
    fi

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
    RELEASE=$3

    mkdir -p ${DEST_DIR}
    if [[ -L $DEST ]]; then
        rm -f $DEST
    fi 

    if [[ ! -d ${DEST}.git ]]; then
        echo -e "   git clone $REPO"
        $GIT clone "$REPO" ${DEST}.git
    fi
    
    ln -s ${DEST}.git ${DEST}

    cd $DEST
    current_release=`git symbolic-ref --short HEAD`
    if [[ ! "$current_release" = "$RELEASE" ]]; then
        echo -e "   switching from $current_release to $RELEASE"
        echo -e "   cleaning repo $DEST"
        $GIT reset --hard
        $GIT clean -fd
        $GIT checkout $RELEASE
    fi

}

function clean_repo(){
    DEST="$1"
    cd $DEST
    echo "   cleaning repo $DEST"
    $GIT reset --hard
    $GIT clean -fd
}



# checking for commandss
check_command curl
check_command docker
check_command git
check_command gpg
check_command jq
check_command patch
check_command readlink
check_command shasum
check_command tar


