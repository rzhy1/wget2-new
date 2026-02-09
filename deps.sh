#!/bin/bash
# wget2 deps
# Author: rzhy1
# 2025/10/3
echo "显示版本"
which autopoint
type -a autopoint
ls -l $(which autopoint)
autopoint --print-archive
ls /usr/share/gettext/
ls /usr/share/aclocal/gettext.m4
echo "显示版本2"

# 设置环境变量
export PREFIX="x86_64-w64-mingw32"
export INSTALLDIR="$HOME/usr/local/$PREFIX"
export PKG_CONFIG_PATH="$INSTALLDIR/lib/pkgconfig:/usr/$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_LIBDIR="$INSTALLDIR/lib/pkgconfig"
export PKG_CONFIG="/usr/bin/${PREFIX}-pkg-config"
export CPPFLAGS="-I$INSTALLDIR/include"
export LDFLAGS="-L$INSTALLDIR/lib -static -s -flto=$(nproc)"
export CFLAGS="-march=tigerlake -mtune=tigerlake -Os -pipe -flto=$(nproc) -g0 -fvisibility=hidden"
export CXXFLAGS="$CFLAGS"
export WINEPATH="$INSTALLDIR/bin;$INSTALLDIR/lib;/usr/$PREFIX/bin;/usr/$PREFIX/lib"
export LD=x86_64-w64-mingw32-ld.lld
ln -s $(which lld-link) /usr/bin/x86_64-w64-mingw32-ld.lld
# 当前路径是：/__w/wget2-windows/wget2-windows
# INSTALLDIR是：/github/home/usr/local/x86_64-w64-mingw32

mkdir -p $INSTALLDIR
cd $INSTALLDIR

build_gmp() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gmp⭐⭐⭐⭐⭐⭐" 
  wget -nv -O- https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz | tar x --xz
  cd gmp-* || exit
  ./configure --host=$PREFIX --disable-shared --prefix="$INSTALLDIR"
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf gmp-*
}

build_libiconv() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libiconv⭐⭐⭐⭐⭐⭐" 
  wget -O- https://mirrors.kernel.org/gnu/libiconv/libiconv-1.18.tar.gz | tar xz || exit 1
  cd libiconv-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --disable-nls --disable-silent-rules --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libiconv-*
}

build_gpg_error() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gpg-error⭐⭐⭐⭐⭐⭐"
  (
     wget -q -O- https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.56.tar.gz | tar xz
     cd libgpg-error-* || exit
     ./configure --host=$PREFIX --disable-shared --prefix="$INSTALLDIR" --enable-static --disable-doc
     make -j$(nproc) && make install
  )
}

build_libassuan() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libassuan⭐⭐⭐⭐⭐⭐"
  (
      wget -q -O- https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2 | tar xj
      cd libassuan-* || exit
      ./configure --host=$PREFIX --disable-shared --prefix="$INSTALLDIR" --enable-static --disable-doc --with-libgpg-error-prefix="$INSTALLDIR"
      make -j$(nproc) && make install
  )
}

build_gpgme() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gpgme⭐⭐⭐⭐⭐⭐"
  (
      wget -q -O- https://gnupg.org/ftp/gcrypt/gpgme/gpgme-2.0.1.tar.bz2 | tar xj
      cd gpgme-* || exit
      env PYTHON=/usr/bin/python3.12 ./configure --host=$PREFIX --disable-shared --prefix="$INSTALLDIR" --enable-static --with-libgpg-error-prefix="$INSTALLDIR" --disable-gpg-test --disable-g13-test --disable-gpgsm-test --disable-gpgconf-test --disable-glibtest --with-libassuan-prefix="$INSTALLDIR"
      make -j$(nproc) && make install
  )
}

build_libunistring() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libunistring⭐⭐⭐⭐⭐⭐" 
  wget -O- https://mirrors.kernel.org/gnu/libunistring/libunistring-1.4.1.tar.gz | tar xz || exit 1
  cd libunistring-* || exit 1
  ac_cv_func_nanosleep=yes \
  ./configure CFLAGS="-Os" --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static --disable-silent-rules --enable-threads=window || exit 1
  make -C lib -j$(nproc) || exit 1
  make -C lib install || exit 1
  cd .. && rm -rf libunistring-*
}

build_libidn2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libidn2⭐⭐⭐⭐⭐⭐" 
  wget -O- https://mirrors.kernel.org/gnu/libidn/libidn2-2.3.8.tar.gz | tar xz || exit 1
  cd libidn2-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX  --disable-shared --enable-static --disable-doc --disable-gcc-warnings --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libidn2-*
}

build_libtasn1() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libtasn1⭐⭐⭐⭐⭐⭐"
  wget -O- https://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.21.0.tar.gz | tar xz || exit 1
  cd libtasn1-* || exit 1
  ./configure --host=$PREFIX --disable-shared --disable-doc --prefix="$INSTALLDIR" || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libtasn1-*
}


build_nghttp2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build nghttp2⭐⭐⭐⭐⭐⭐" 
  wget -O- https://github.com/nghttp2/nghttp2/releases/download/v1.68.0/nghttp2-1.68.0.tar.gz | tar xz || exit 1
  cd nghttp2-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static --disable-examples --disable-app --disable-failmalloc --disable-hpack-tools || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf nghttp2-*
}

build_libmicrohttpd() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libmicrohttpd⭐⭐⭐⭐⭐⭐" 
  wget -O- https://mirrors.kernel.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz | tar xz || exit 1
  cd libmicrohttpd-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static \
            --disable-examples --disable-doc --disable-tools --disable-silent-rules || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libmicrohttpd-*
}

build_libpsl() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libpsl⭐⭐⭐⭐⭐⭐" 
  wget -q -O- https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz | tar xz  || exit 1
  cd libpsl-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --enable-runtime=libidn2 --enable-builtin --prefix=$INSTALLDIR || exit 1      
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libpsl-*
}

build_libhsts() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libhsts⭐⭐⭐⭐⭐⭐" 
  wget -q -O- https://gitlab.com/-/project/5701385/uploads/4753f61b5a3c6253acf4934217816e3f/libhsts-0.1.0.tar.gz | tar xz  || exit 1
  ln -sf /usr/bin/python3 /usr/bin/python
  cd libhsts-*   || exit 1
  ./configure \
      --host=$PREFIX \
      --prefix=$INSTALLDIR \
      --disable-nls \
      --enable-static \
      --disable-shared
  make -j$(nproc)
  make install
  cd .. && rm -rf libhsts
}

build_nettle() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build nettle⭐⭐⭐⭐⭐⭐" 
  #git clone  https://github.com/sailfishos-mirror/nettle.git || exit 1
  wget -O- https://mirrors.kernel.org/gnu/nettle/nettle-3.10.2.tar.gz | tar xz || exit 1
  cd nettle-* || exit 1
  bash .bootstrap || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --disable-documentation --prefix=$INSTALLDIR --libdir=$INSTALLDIR/lib || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf nettle-*
}

build_gnutls() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gnutls⭐⭐⭐⭐⭐⭐" 
  wget -O- https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.11.tar.xz | tar x --xz || exit 1
  cd gnutls-* || exit 1
  export gl_cv_func_nanosleep=yes
  export gl_cv_func_clock_gettime=yes
  GMP_LIBS="-L$INSTALLDIR/lib -lgmp" \
  NETTLE_LIBS="-L$INSTALLDIR/lib -lnettle -lgmp" \
  HOGWEED_LIBS="-L$INSTALLDIR/lib -lhogweed -lnettle -lgmp" \
  LIBTASN1_LIBS="-L$INSTALLDIR/lib -ltasn1" \
  LIBIDN2_LIBS="-L$INSTALLDIR/lib -lidn2" \
  GMP_CFLAGS=$CFLAGS \
  LIBTASN1_CFLAGS=$CFLAGS \
  NETTLE_CFLAGS=$CFLAGS \
  HOGWEED_CFLAGS=$CFLAGS \
  LIBIDN2_CFLAGS=$CFLAGS \
  ./configure CFLAGS="$CFLAGS" --host=$PREFIX --prefix=$INSTALLDIR --disable-openssl-compatibility --disable-hardware-acceleration --disable-shared --enable-static --without-p11-kit --disable-doc --disable-tests --disable-full-test-suite --disable-tools --disable-cxx --disable-maintainer-mode --disable-libdane || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf gnutls-* 
}

echo "=== 第一阶段：基础库 ==="
build_libhsts
build_gmp
build_libiconv
build_libunistring
wait

echo "=== 第二阶段：加密基础 ==="
build_gpg_error
build_libtasn1
build_nettle
wait

echo "=== 第三阶段：网络库 ==="
build_libidn2
build_libhsts
build_nghttp2
build_libmicrohttpd
wait

echo "=== 第四阶段：GPG 组件 ==="
build_libassuan
wait
build_gpgme
wait

echo "=== 第五阶段：最终组件 ==="
build_libpsl    # 需要 libidn2
build_gnutls    # 需要 nettle, libtasn1, gmp
wait

cd "$HOME/usr/local"

echo ">>> 开始打包依赖：wget2-deps.tar.zst"
tar -I zstd -cf wget2-deps.tar.zst -C "$PREFIX" include lib pkgconfig

# 复制到工作目录，供 GitHub Actions 上传
cp -fv wget2-deps.tar.zst "${GITHUB_WORKSPACE}/" || exit 1

echo ">>> 打包完成："
ls -lh wget2-deps.tar.zst "${GITHUB_WORKSPACE}/wget2-deps.tar.zst"
