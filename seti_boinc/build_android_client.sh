#!/bin/sh

#
# See: http://boinc.berkeley.edu/trac/wiki/AndroidBuildApp#
#

# Script to compile various BOINC libraries for Android to be used
# by science applications

#for targetarch in armv6-soft armv6-vfp armv6-neon armv7-neon armv7-vfpv3 armv7-vfpv4 armv7-vfpv3d16 thumb-vfpv3d16
for targetarch in armv6-vfp armv6-neon
do
fpabi="-mfloat-abi=softfp"
configargs=""
cpuarch=armv7-a
tune=cortex-a9
case $targetarch in
        armv6-soft) 
          fpabi="-mfloat-abi=soft"
          cpuarch=armv6
          fpu=
          tune=cortex-m1
          ;;
        armv6-vfp)
          cpuarch=armv6
          configargs="--disable-neon"
          fpu="-mfpu=vfp"
          tune=cortex-m1
          ;;
        armv6-neon)
          cpuarch=armv6
          tune=cortex-m1
          fpu="-mfpu=neon -ftree-vectorize"
          ;;
        thumb-vfpv3d16)
          cpuarch="armv7-a -mthumb"
          fpu="-mfpu=vfpv3-d16"
          ;;
        *-neon)
          fpu="-mfpu=neon -ftree-vectorize"
          ;;
        *-vfpv3)
          fpu="-mfpu=vfpv3"
          ;;
        *-vfpv3d16)
          fpu="-mfpu=vfpv3-d16"
          ;;
        *-vfpv4)
          fpu="-mfpu=vfpv4"
          ;;
        *)
          ;;
esac




COMPILEBOINC="yes"
CONFIGURE="yes"
MAKECLEAN="yes"

export BOINC="../boinc" #BOINC source code
export PKG_CONFIG_DEBUG_SPEW=1

export ANDROIDTC="/usr/arm-linux-androideabi"
export TCBINARIES="$ANDROIDTC/bin"
export TCINCLUDES="$ANDROIDTC/arm-linux-androideabi"
export TCSYSROOT="$ANDROIDTC/sysroot"
export STDCPPTC="$TCINCLUDES/lib/libstdc++.a"

export CROSS_PREFIX=arm-linux-androideabi
export ac_cv_host=${CROSS_PREFIX}

export PATH="$PATH:$TCBINARIES:$TCINCLUDES/bin"
export CC=${CROSS_PREFIX}-gcc
export CCAS=${CROSS_PREFIX}-gcc
export CXX=${CROSS_PREFIX}-g++
export LD=${CROSS_PREFIX}-ld
export NM=${CROSS_PREFIX}-nm
export AR=${CROSS_PREFIX}-ar
export STRIP=${CROSS_PREFIX}-strip
export RANLIB=${CROSS_PREFIX}-ranlib

export CFLAGS="--sysroot=$TCSYSROOT -DANDROID -DDECLARE_TIMEZONE -Wall -O3 -fomit-frame-pointer -march=${cpuarch} -I$TCSYSROOT/usr/include ${fpu} ${fpabi}"
export CXXFLAGS="--sysroot=$TCSYSROOT -DANDROID -Wall -funroll-loops -fexceptions -O3 -fomit-frame-pointer -march=${cpuarch} -I$TCSYSROOT/usr/include ${fpu} ${fpabi}"
export CCASFLAGS="${CFLAGS}"
export LDFLAGS="-static-libstdc++ -static-libgcc -L$TCINCLUDES/lib/${targetarch} -L$TCSYSROOT/usr/lib -L$TCINCLUDES/lib -llog -lstdc++"
export LIBS="/usr/arm-linux-androideabi/arm-linux-androideabi/lib/libstdc++.a"
export PKG_CONFIG_SYSROOT_DIR=$TCSYSROOT
export PKG_CONFIG_PATH=$CURL_DIR/lib/pkgconfig:$OPENSSL_DIR/lib/pkgconfig

if [ -n "$COMPILEBOINC" ]; then
echo "==================building Libraries from $BOINC=========================="
if [ -n "$MAKECLEAN" ]; then
cd client
make clean
cd ..
fi
if [ -n "$CONFIGURE" ]; then
./_autosetup 
/bin/rm config.cache
if ! ./configure -C --host=${ac_cv_host} --prefix="${ANDROIDTC}/arm-linux-androideabi" --exec-prefix="${ANDROIDTC}/arm-linux-androideabi" --with-boinc-platform="arm-android-linux-gnu" --with-ssl=$TCINCLUDES --disable-graphics --disable-server $configargs
then
  break
fi
fi
cd client
if ! make ; then
  break
fi
pwd
source ./working_collect2_line_for_android_$targetarch
cp seti_boinc setiathome_7.28_arm-android-linux-gnu__$targetarch
cd ..
echo "=============================BOINC done============================="
fi
done
