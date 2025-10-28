#!/bin/bash
# wget2 build script for Windows environment
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
sudo ln -s $(which lld-link) /usr/bin/x86_64-w64-mingw32-ld.lld
# 当前路径是：/__w/wget2-windows/wget2-windows
# INSTALLDIR是：/github/home/usr/local/x86_64-w64-mingw32

download_deps() { 
  echo ">>> 下载 wget2-deps.tar.zst"
  mkdir -p "$HOME/deps"
  cd "$HOME/deps"

  rm -f wget2-deps.tar.zst
  curl -L -o wget2-deps.tar.zst \
    https://github.com/rzhy1/wget2-new/releases/download/wget2-deps/wget2-deps.tar.zst

  # ================== 解压依赖 ==================
  echo ">>> 解压 wget2-deps.tar.zst 到 $HOME/usr/local/$PREFIX"
  mkdir -p "$HOME/usr/local/$PREFIX"  
  
  if command -v zstd >/dev/null 2>&1; then
    tar -I zstd -xf wget2-deps.tar.zst -C "$HOME/usr/local/$PREFIX"

  else
    unzstd -c wget2-deps.tar.zst | tar -xf - -C "$HOME/usr/local/$PREFIX"
  fi

  echo ">>> 依赖解压完成，校验目录："
  ls -lh "$INSTALLDIR/lib" | head -n 30

  cd "$INSTALLDIR" || { echo "❌ $INSTALLDIR 不存在"; exit 1; }
}


build_brotli() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build brotli⭐⭐⭐⭐⭐⭐"
  git clone --depth=1 https://github.com/google/brotli.git || exit 1
  cd brotli || exit 1
  mkdir build && cd build
  cmake .. \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_INSTALL_PREFIX=$INSTALLDIR \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release || exit 1
  make -j$(nproc) install || exit 1
  echo "显示原版libbrotlidec.pc内容"
  cat $INSTALLDIR/lib/pkgconfig/libbrotlidec.pc
  sed -i 's/^Libs: .*/& -lbrotlicommon/' "$INSTALLDIR/lib/pkgconfig/libbrotlidec.pc"
  cd ../.. && rm -rf brotli
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - pkg-config --cflags --libs libbrotlienc libbrotlidec libbrotlicommo结果如下⭐⭐⭐⭐⭐⭐" 
  pkg-config --cflags --libs libbrotlienc libbrotlidec libbrotlicommon
  echo "显示新版libbrotlidec.pc内容"
  cat $INSTALLDIR/lib/pkgconfig/libbrotlidec.pc
}

build_xz() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build xz⭐⭐⭐⭐⭐⭐" 
  sudo apt-get purge xz-utils
  git clone --depth=1 https://github.com/tukaani-project/xz.git || { echo "Git clone failed"; exit 1; }
  cd xz || { echo "cd xz failed"; exit 1; }
  mkdir build
  cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DXZ_NLS=ON -DBUILD_SHARED_LIBS=OFF || { echo "CMake failed"; exit 1; }
  cmake --build . -- -j$(nproc) || { echo "Build failed"; exit 1; }
  sudo cmake --install . || { echo "Install failed"; exit 1; }
  xz --version
  cd ../.. && rm -rf xz
}

build_zstd() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build zstd⭐⭐⭐⭐⭐⭐" 
  # 创建 Python 虚拟环境并安装meson
  rm -rf /tmp/venv
  python3 -m venv /tmp/venv
  source /tmp/venv/bin/activate
  pip3 install --no-cache-dir meson pytest

  # 编译 zstd
  git clone --depth=1 https://github.com/facebook/zstd.git || exit 1
  cd zstd || exit 1
  meson setup \
    --cross-file=${GITHUB_WORKSPACE}/cross_file.txt \
    --backend=ninja \
    --prefix=$INSTALLDIR \
    --libdir=$INSTALLDIR/lib \
    --bindir=$INSTALLDIR/bin \
    --pkg-config-path="$INSTALLDIR/lib/pkgconfig" \
    -Dbin_programs=false \
    -Dstatic_runtime=true \
    -Ddefault_library=static \
    -Db_lto=true --optimization=2 \
    build/meson builddir-st || exit 1
  sudo rm -f /usr/local/bin/zstd*
  sudo rm -f /usr/local/bin/*zstd
  meson compile -C builddir-st || exit 1
  meson install -C builddir-st || exit 1
  cd .. && rm -rf zstd
}

build_zlib-ng() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build zlib-ng⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 https://github.com/zlib-ng/zlib-ng || exit 1
  cd zlib-ng || exit 1
  CROSS_PREFIX="x86_64-w64-mingw32-" ARCH="x86_64" CFLAGS="-Os" CC=x86_64-w64-mingw32-gcc ./configure --prefix=$INSTALLDIR --static --64 --zlib-compat || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf zlib-ng
}

build_gnulibmirror() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build gnulib-mirror⭐⭐⭐⭐⭐⭐" 
  git clone --recursive --depth=1 https://gitlab.com/gnuwget/gnulib-mirror.git gnulib || exit 1
  export GNULIB_REFDIR=$INSTALLDIR/gnulib
}

build_PCRE2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build PCRE2⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 https://github.com/PCRE2Project/pcre2 || exit 1
  cd pcre2 || exit 1
  ./autogen.sh || exit 1
  ./configure --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf pcre2
}

build_libpsl() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build libpsl⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 --recursive https://github.com/rockdaboot/libpsl.git || exit 1
  cd libpsl || exit 1
  ./autogen.sh || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --enable-runtime=libidn2 --enable-builtin --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libpsl
}

build_wget2() {
  echo "⭐⭐⭐⭐⭐⭐$(date '+%Y/%m/%d %a %H:%M:%S.%N') - build wget2⭐⭐⭐⭐⭐⭐" 
  git clone https://gitlab.com/gnuwget/wget2.git || exit 1
  cd wget2 || exit 1
  if [ -d "gnulib" ]; then
      rm -rf gnulib
  fi
  git clone --depth=1 https://github.com/coreutils/gnulib.git
  ./bootstrap --skip-po --gnulib-srcdir=gnulib || exit 1
  export LDFLAGS="$LDFLAGS -L$INSTALLDIR/lib -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive"
  export CPPFLAGS="-I$INSTALLDIR/include -DNGHTTP2_STATICLIB"
  GNUTLS_CFLAGS=$CFLAGS \
  GNUTLS_LIBS="-L$INSTALLDIR/lib -lgnutls -lhogweed -lnettle -lgmp -ltasn1 -lidn2 -lbcrypt -lncrypt" \
  LIBPSL_CFLAGS=$CFLAGS \
  LIBPSL_LIBS="-L$INSTALLDIR/lib -lpsl" \
  LIBPCRE2_CFLAGS=$CFLAGS \
  LIBPCRE2_LIBS="-L$INSTALLDIR/lib -lpcre2-8"  \
  ./configure \
    --build=x86_64-pc-linux-gnu \
    --host=$PREFIX \
    --with-libiconv-prefix="$INSTALLDIR" \
    --with-ssl=gnutls \
    --disable-shared \
    --enable-static \
    --disable-nls \
    --disable-doc \
    --enable-year2038 \
    --with-zlib \
    --with-lzip \
    --without-lzma \
    --with-zstd \
    --without-bzip2 \
    --enable-threads=windows
  make -j$(nproc)  || exit 1
  strip $INSTALLDIR/wget2/src/wget2.exe || exit 1
  cp -fv "$INSTALLDIR/wget2/src/wget2.exe" "${GITHUB_WORKSPACE}" || exit 1
}
download_deps
wait
build_brotli
build_zstd
build_zlib-ng
build_PCRE2
wait
build_wget2
