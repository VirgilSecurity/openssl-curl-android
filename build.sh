#!/bin/bash

#
#   Global variables
#
SCRIPT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"

#
#   Includes
#
source ${SCRIPT_FOLDER}/ish/error.ish

# export CA_FILE=/data/user/0/com.virgilsecurity.qtmessenger/files/cert.pem

#***************************************************************************************
function usage_example() {
    echo "Example: ${0} $HOME/Library/Android/sdk/ndk/20.1.5948944 darwin-x86_64 com.virgilsecurity.qtmessenger"
}

#***************************************************************************************
#
#   Check input parameters
#
export ANDROID_NDK_HOME="${1}"
export HOST_TAG="${2}"
export APP_ID="${3}"


if [ ! -d ${ANDROID_NDK_HOME} ]; then
    echo "Wrong NDK path: ${ANDROID_NDK_HOME}"
    usage_example
    exit 1
fi

if [ -z "$HOST_TAG" ]; then
    echo "Host tag is not set: ${HOST_TAG}"
    usage_example
    exit 1
fi

if [ -z "$APP_ID" ]; then
    echo "App ID is not set: ${APP_ID}"
    usage_example
    exit 1
fi

#***************************************************************************************
export MIN_SDK_VERSION=21

export CFLAGS="-Os -ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables"
export LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"

chmod +x ./build-openssl.sh
chmod +x ./build-curl.sh

#
#   Build OpenSSL library
#
${SCRIPT_FOLDER}/build-openssl.sh
check_error

#
#   Build CURL library
#
${SCRIPT_FOLDER}/build-curl.sh
check_error

#***************************************************************************************
