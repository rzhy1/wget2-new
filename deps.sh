#!/bin/bash
# wget2 deps
# Author: rzhy1
# 2025/10/3

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
  start_time=$(date +%s.%N)
  wget -nv -O- https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz | tar x --xz
  cd gmp-* || exit
  ./configure --host=$PREFIX --disable-shared --prefix="$INSTALLDIR"
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf gmp-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/gmp_duration.txt"
}

build_libiconv() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libiconv⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -O- https://mirrors.kernel.org/gnu/libiconv/libiconv-1.18.tar.gz | tar xz || exit 1
  cd libiconv-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --disable-nls --disable-silent-rules --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libiconv-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libiconv_duration.txt"
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
  local start_time=$(date +%s.%N)
  wget -O- https://mirrors.kernel.org/gnu/libunistring/libunistring-1.4.1.tar.gz | tar xz || exit 1
  cd libunistring-* || exit 1
  ./configure CFLAGS="-Os" --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static --disable-doc --disable-silent-rules || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libunistring-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libunistring_duration.txt"
}

build_libidn2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libidn2⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -O- https://mirrors.kernel.org/gnu/libidn/libidn2-2.3.8.tar.gz | tar xz || exit 1
  cd libidn2-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX  --disable-shared --enable-static --disable-doc --disable-gcc-warnings --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libidn2-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libidn2_duration.txt"
}

build_libtasn1() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libtasn1⭐⭐⭐⭐⭐⭐"
  local start_time=$(date +%s.%N)
  wget -O- https://mirrors.kernel.org/gnu/libtasn1/libtasn1-4.20.0.tar.gz | tar xz || exit 1
  cd libtasn1-* || exit 1
  ./configure --host=$PREFIX --disable-shared --disable-doc --prefix="$INSTALLDIR" || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libtasn1-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libtasn1_duration.txt"
}


build_nghttp2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build nghttp2⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -O- https://github.com/nghttp2/nghttp2/releases/download/v1.67.1/nghttp2-1.67.1.tar.gz | tar xz || exit 1
  cd nghttp2-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static --disable-examples --disable-app --disable-failmalloc --disable-hpack-tools || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf nghttp2-*
  local end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/nghttp2_duration.txt"
}

build_libmicrohttpd() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libmicrohttpd⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -O- https://mirrors.kernel.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz | tar xz || exit 1
  cd libmicrohttpd-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static \
            --disable-examples --disable-doc --disable-tools --disable-silent-rules || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libmicrohttpd-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libmicrohttpd_duration.txt"
}

build_libpsl() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libpsl⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -q -O- https://github.com/rockdaboot/libpsl/releases/download/0.21.5/libpsl-0.21.5.tar.gz | tar xz
  cd libpsl-* || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --enable-runtime=libidn2 --enable-builtin --prefix=$INSTALLDIR || exit 1      
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libpsl-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/libpsl_duration.txt"
}

build_libhsts() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libhsts⭐⭐⭐⭐⭐⭐" 
  git clone https://gitlab.com/rockdaboot/libhsts.git
  cd libhsts
  autoreconf -fi
  ./configure \
      --host=$PREFIX \
      --prefix=$INSTALLDIR \
      --enable-static \
      --disable-shared
  make -j$(nproc)
  make install
  cd .. && rm -rf libhsts
}

build_nettle() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build nettle⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  #git clone  https://github.com/sailfishos-mirror/nettle.git || exit 1
  wget -O- https://mirrors.kernel.org/gnu/nettle/nettle-3.10.2.tar.gz | tar xz || exit 1
  cd nettle-* || exit 1
  bash .bootstrap || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --disable-documentation --prefix=$INSTALLDIR --libdir=$INSTALLDIR/lib || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf nettle-*
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/nettle_duration.txt"
}

build_gnutls() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gnutls⭐⭐⭐⭐⭐⭐" 
  local start_time=$(date +%s.%N)
  wget -O- https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.10.tar.xz | tar x --xz || exit 1
  cd gnutls-* || exit 1
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
  local end_time=$(date +%s.%N)
  local duration=$(echo "$end_time - $start_time" | bc | xargs printf "%.1f")
  echo "$duration" > "$INSTALLDIR/gnutls_duration.txt"
}

build_gmp
build_gpg_error
build_libassuan
build_gpgme
wait
build_libunistring &
build_libtasn1 &
build_libpsl &
wait
build_libhsts  &
build_libiconv &
build_libidn2 &
wait
build_nghttp2 &
build_libmicrohttpd &
wait
build_nettle 
build_gnutls 

cd "$HOME/usr/local"

echo ">>> 开始打包依赖：wget2-deps.tar.zst"
tar -I zstd -cf wget2-deps.tar.zst -C "$PREFIX" include lib pkgconfig

# 复制到工作目录，供 GitHub Actions 上传
cp -fv wget2-deps.tar.zst "${GITHUB_WORKSPACE}/" || exit 1

echo ">>> 打包完成："
ls -lh wget2-deps.tar.zst "${GITHUB_WORKSPACE}/wget2-deps.tar.zst"
