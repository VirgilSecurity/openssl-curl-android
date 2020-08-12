#!/bin/bash

#
#   Global variables
#
SCRIPT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
PATH=$TOOLCHAIN/bin:$PATH
BUILD_TYPE="${1:-release}"    
#
#   Includes
#
source ${SCRIPT_FOLDER}/ish/error.ish

#***************************************************************************************
function build_openssl() {
    export TARGET_HOST=${1}
    local CONF_TARGET=${2}
    local BUILD_DIR=${3}

    local DEBUG_PARAM=" "
    [ "${BUILD_TYPE}" == "dubug" ] && DEBUG_PARAM="--debug"

    local PRFIX_DIR=${INSTALL_DIR_BASE}/android.${BUILD_DIR}/${BUILD_TYPE}/installed/usr/local
    
    make clean
    
    ./Configure ${CONF_TARGET} shared \
    -D__ANDROID_API__=$MIN_SDK_VERSION \
    --prefix=${PRFIX_DIR} \
    ${DEBUG_PARAM}
    check_error
    
    make -j10
    check_error
    
    make install_sw
    check_error
    
    pushd ${PRFIX_DIR}/lib
    cp libcrypto.so.1.1 libcrypto_1_1.so
    check_error
    
    cp libssl.so.1.1 libssl_1_1.so
    check_error
    popd
}

#***************************************************************************************
#
#   Prepare artifacts folder
#
OPENSSL_DIR="${SCRIPT_FOLDER}/build/openssl"
if [ -d ${OPENSSL_DIR} ]; then
    rm -rf OPENSSL_DIR
fi
mkdir -p ${OPENSSL_DIR}
check_error

#
#   Buils for all architectures
#
pushd ${SCRIPT_FOLDER}/openssl

# # arm64
# build_openssl aarch64-linux-android android-arm64 arm64-v8a
# check_error

# # arm
# build_openssl armv7a-linux-androideabi android-arm armeabi-v7a
# check_error

# # x86
# build_openssl i686-linux-android android-x86 x86
# check_error

# x64
build_openssl x86_64-linux-android android-x86_64 x86_64
check_error

popd
