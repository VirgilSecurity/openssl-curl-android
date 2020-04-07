#!/bin/bash

SCRIPT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"

function build_openssl() {
    export TARGET_HOST=${1}
    local CONF_TARGET=${2}
    local BUILD_DIR=${3}

    make clean

    ./Configure ${CONF_TARGET} shared \
    -D__ANDROID_API__=$MIN_SDK_VERSION \
    --prefix=$PWD/build/${BUILD_DIR}

    make -j4
    make install_sw
    mkdir -p ../build/openssl/${BUILD_DIR}
    cp $PWD/build/${BUILD_DIR}/lib/libcrypto.so.1.1 $PWD/build/${BUILD_DIR}/lib/libcrypto_1_1.so
    cp $PWD/build/${BUILD_DIR}/lib/libssl.so.1.1 $PWD/build/${BUILD_DIR}/lib/libssl_1_1.so
    cp -R $PWD/build/${BUILD_DIR} ../build/openssl/
}

OPENSSL_DIR="${SCRIPT_FOLDER}/build/openssl"
if [ -d ${OPENSSL_DIR} ]; then
    rm -rf OPENSSL_DIR
fi
mkdir -p ${OPENSSL_DIR}

export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
PATH=$TOOLCHAIN/bin:$PATH

pushd ${SCRIPT_FOLDER}/openssl

    # arm64
    build_openssl aarch64-linux-android android-arm64 arm64-v8a

    # arm
    build_openssl armv7a-linux-androideabi android-arm armeabi-v7a

    # x86
    build_openssl i686-linux-android android-x86 x86

    # x64
    build_openssl x86_64-linux-android android-x86_64 android-x86_64

popd
