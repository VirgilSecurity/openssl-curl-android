#!/bin/bash

SCRIPT_FOLDER="$( cd "$( dirname "$0" )" && pwd )"
export CA_FILE=/data/user/0/${APP_ID}/files/cert.pem

function build_curl() {
    export TARGET_HOST=${1}
    local BUILD_DIR=${2}

    if [ $TARGET_HOST == "armv7a-linux-androideabi" ]; then
        TOOLS_PREFIX=arm-linux-androideabi
    else
        TOOLS_PREFIX=$TARGET_HOST
    fi

    if [ $TARGET_HOST == "x86_64-linux-android" ]; then
        export SSL_DIR=$PWD/../openssl/build/android-x86_64
    else
        export SSL_DIR=$PWD/../openssl/build/${BUILD_DIR}
    fi

    export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG
    PATH=$TOOLCHAIN/bin:$PATH
    export AR=$TOOLCHAIN/bin/$TOOLS_PREFIX-ar
    export AS=$TOOLCHAIN/bin/$TOOLS_PREFIX-as
    export CC=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang
    export CXX=$TOOLCHAIN/bin/$TARGET_HOST$MIN_SDK_VERSION-clang++
    export LD=$TOOLCHAIN/bin/$TARGET_HOST-ld
    export RANLIB=$TOOLCHAIN/bin/$TOOLS_PREFIX-ranlib
    export STRIP=$TOOLCHAIN/bin/$TOOLS_PREFIX-strip

    make clean

    ./configure --host=$TARGET_HOST \
            --target=$TARGET_HOST \
            --prefix=$PWD/build/${BUILD_DIR} \
            --with-ssl=$SSL_DIR \
            --with-ca-bundle=$CA_FILE \
            --disable-shared \
            --disable-verbose \
            --disable-manual \
            --disable-crypto-auth \
            --disable-unix-sockets \
            --disable-ares \
            --disable-rtsp \
            --disable-ipv6 \
            --disable-proxy \
            --disable-versioned-symbols \
            --enable-hidden-symbols \
            --without-libidn \
            --without-librtmp \
            --without-zlib \
            --disable-dict \
            --disable-file \
            --disable-ftp \
            --disable-ftps \
            --disable-gopher \
            --disable-imap \
            --disable-imaps \
            --disable-pop3 \
            --disable-pop3s \
            --disable-smb \
            --disable-smbs \
            --disable-smtp \
            --disable-smtps \
            --disable-telnet \
            --disable-tftp

    make -j4
    make install
    mkdir -p ../build/curl/${BUILD_DIR}
    cp -R $PWD/build/${BUILD_DIR} ../build/curl/

}

OPENSSL_DIR="${SCRIPT_FOLDER}/build/curl"
if [ -d ${OPENSSL_DIR} ]; then
    rm -rf OPENSSL_DIR
fi
mkdir -p ${OPENSSL_DIR}


pushd ${SCRIPT_FOLDER}/curl
    ./buildconf

    # arm64
    build_curl aarch64-linux-android arm64-v8a

    # arm
    build_curl armv7a-linux-androideabi armeabi-v7a

    # x86
    build_curl i686-linux-android x86

    # x64
    build_curl x86_64-linux-android x86_64

popd
