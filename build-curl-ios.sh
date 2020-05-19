#!/bin/bash

#********************************************************************************************
realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

#********************************************************************************************
# Enviroment  INSTALL_DIR_BASE for installing include and lib

REL_SCRIPT_PATH="$(dirname $0)"
SCRIPTPATH=$(realpath "$REL_SCRIPT_PATH")
CURLPATH="$SCRIPTPATH/curl"
source ${REL_SCRIPT_PATH}/ish/error.ish
export IPHONEOS_DEPLOYMENT_TARGET="10"
CUL_WITHOUT="--disable-verbose --disable-manual --disable-crypto-auth --disable-unix-sockets --disable-ares --disable-rtsp  --disable-ipv6 \
             --disable-proxy --disable-versioned-symbols --enable-hidden-symbols --without-libidn --without-librtmp --without-zlib \
             --disable-dict --disable-file --disable-ftp --disable-ftps --disable-gopher --disable-imap --disable-imaps --disable-pop3 \
             --disable-pop3s --disable-smb --disable-smbs --disable-smtp --disable-smtps --disable-telnet --disable-tftp"
DESTDIR="${SCRIPTPATH}/build"

if [ "${1}" == "sim" ]; then
  echo "=== Build for iOS simulator"
  IS_SIMULATOR=TRUE
else
  echo "=== Build for iOS devices"
  IS_SIMULATOR=FALSE
fi

#********************************************************************************************
check_xcode() {
  XCODE=$(xcode-select -p)
  if [ ! -d "$XCODE" ]; then
    echo "You have to install Xcode and the command line tools first"
    exit 1
  fi
  # export CC="$XCODE/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
}

#********************************************************************************************
create_build_dir() {
  [ "${DESTDIR}" != "/" ] && rm -rf ${DESTDIR}
  mkdir -p ${DESTDIR}
}

#********************************************************************************************
curl_create_config() {
  pushd ${CURLPATH}
  if [ ! -x "configure" ]; then
    echo "=== Ececuting buildconf"
    ./buildconf
    check_error
  fi
}

#********************************************************************************************
curl_build_ios() {
  local CURL_ARCH="${1}"
  local CURL_HOST="${2}"
  local CURL_PLATFORM="${3}"
  local CURL_SDK="${4}"
  local CURL_SHARED="${5}"

  echo "#====  Buildung Curl  ====="
  echo "# ARCH     = [$CURL_ARCH]"
  echo "# HOST     = [$CURL_HOST]"
  echo "# PLATFORM = [$CURL_PLATFORM]"
  echo "# SDK      = [$CURL_SDK]"
  echo "# SHARED   = [$CURL_SHARED]"
  echo "#=========================="

  export CFLAGS="-arch $CURL_ARCH -pipe -Os -gdwarf-2 -isysroot $XCODE/Platforms/${CURL_PLATFORM}.platform/Developer/SDKs/${CURL_SDK}.sdk -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode -Werror=partial-availability"
  export LDFLAGS="-arch $CURL_ARCH -isysroot $XCODE/Platforms/${CURL_PLATFORM}.platform/Developer/SDKs/${CURL_SDK}.sdk"
  [ "${CURL_PLATFORM}" = "iPhoneSimulator" ] && export CPPFLAGS="-D__IPHONE_OS_VERSION_MIN_REQUIRED=${IPHONEOS_DEPLOYMENT_TARGET%%.*}0000"
  pushd "${CURLPATH}"
  if [ -z "${CURL_SHARED}" ]; then
    CURL_LIB_TYPE="--enable-static --disable-shared"
    CURL_LIB_EXT="a"
  else
    CURL_LIB_TYPE="--disable-static --enable-shared"
    CURL_LIB_EXT="dylib"
  fi
  echo "=== Run configuring tool"
  ./configure --host="${CURL_HOST}-apple-darwin" --with-darwinssl ${CURL_LIB_TYPE} --enable-threaded-resolver --disable-verbose --enable-ipv6 ${CUL_WITHOUT}
  check_error

  echo "=== Run make"
  make -j $(sysctl -n hw.logicalcpu_max)
  check_error

  cp "$CURLPATH/lib/.libs/libcurl.${CURL_LIB_EXT}" "$DESTDIR/libcurl-${CURL_ARCH}.${CURL_LIB_EXT}"
  make clean
  popd
}

#********************************************************************************************
aggregate_lib() {
  pushd ${DESTDIR}
  echo "=== Packing multiarch library"
  lipo -create -output libcurl.${CURL_LIB_EXT} libcurl-*.${CURL_LIB_EXT}
  rm libcurl-*.${CURL_LIB_EXT}
  popd
}
#********************************************************************************************
copy_headers() {
  #Copying cURL headers
  echo "=== Copy headers"
  if [ -d "$DESTDIR/include" ]; then
    rm -rf "$DESTDIR/include"
  fi
  cp -R "$CURLPATH/include" "$DESTDIR/"
  rm "$DESTDIR/include/curl/.gitignore"
  [ "${DESTDIR}" != "/" ] && find ${DESTDIR} -type f -name "Makefile*" -delete
  [ "${DESTDIR}" != "/" ] && find ${DESTDIR} -type f -name "README" -delete
}

#********************************************************************************************
install_to_dest() {
  if [ ! -z "$INSTALL_DIR_BASE" ]; then
    if [ "$IS_SIMULATOR" == "FALSE" ]; then
      DST_BASE_DIR="${INSTALL_DIR_BASE}/ios/release/installed/usr/local"
    else
      DST_BASE_DIR="${INSTALL_DIR_BASE}/ios-sim/release/installed/usr/local"
    fi
    echo "=== Installing iOS to [${DST_BASE_DIR}]"
    mkdir -p ${DST_BASE_DIR}/lib
    mkdir -p ${DST_BASE_DIR}/include
    cp -fr ${DESTDIR}/include/* ${DST_BASE_DIR}/include/
    cp -r ${DESTDIR}/libcurl.* ${DST_BASE_DIR}/lib/
  fi
}

#********************************************************************************************
check_xcode
create_build_dir
curl_create_config

# Build static libraryes
if [ "$IS_SIMULATOR" == "FALSE" ]; then
  curl_build_ios armv7 armv7 iPhoneOS iPhoneOS
  curl_build_ios armv7s armv7s iPhoneOS iPhoneOS
  curl_build_ios arm64 arm iPhoneOS iPhoneOS
  aggregate_lib
else
  curl_build_ios x86_64 x86_64 iPhoneSimulator iPhoneSimulator
fi

# Build dynamic libraryes
# if [ "$IS_SIMULATOR" == "FALSE" ]; then
#   curl_build_ios armv7 armv7 iPhoneOS iPhoneOS 1
#   curl_build_ios armv7s armv7s iPhoneOS iPhoneOS 1
#   curl_build_ios arm64 arm iPhoneOS iPhoneOS 1
#   aggregate_lib
# else
#   curl_build_ios x86_64 x86_64 iPhoneSimulator iPhoneSimulator 1
# fi

copy_headers
install_to_dest
#********************************************************************************************
