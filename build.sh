#!/bin/bash
# wget2 build script for Windows environment (Split Build / Fixed)
# Author: rzhy1
# 2025/10/3

# 设置环境变量
export PREFIX="x86_64-w64-mingw32"
export INSTALLDIR="$HOME/usr/local/$PREFIX"
export PKG_CONFIG_PATH="$INSTALLDIR/lib/pkgconfig:/usr/$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_LIBDIR="$INSTALLDIR/lib/pkgconfig"
export PKG_CONFIG="/usr/bin/${PREFIX}-pkg-config"
export CPPFLAGS="-I$INSTALLDIR/include -DNGHTTP2_STATICLIB"

# LDFLAGS 中包含基础链接参数
export LDFLAGS="-L$INSTALLDIR/lib -static -s"
export CFLAGS="-march=tigerlake -mtune=tigerlake -Os -pipe -g0"
export CXXFLAGS="$CFLAGS"
export WINEPATH="$INSTALLDIR/bin;$INSTALLDIR/lib;/usr/$PREFIX/bin;/usr/$PREFIX/lib"
export LD=x86_64-w64-mingw32-ld.lld
ln -s $(which lld-link) /usr/bin/x86_64-w64-mingw32-ld.lld

# 确保目录存在
mkdir -p $INSTALLDIR

download_deps() { 
  echo ">>> 下载 wget2-deps.tar.zst"
  mkdir -p "$HOME/deps"
  cd "$HOME/deps"

  rm -f wget2-deps.tar.zst
  # 请确保该下载链接有效且 tar 包内结构正确
  curl -L -o wget2-deps.tar.zst \
    https://github.com/rzhy1/wget2-new/releases/download/wget2-deps/wget2-deps.tar.zst

  echo ">>> 解压 wget2-deps.tar.zst 到 $HOME/usr/local/$PREFIX"
  mkdir -p "$HOME/usr/local/$PREFIX"  
  
  if command -v zstd >/dev/null 2>&1; then
    tar -I zstd -xf wget2-deps.tar.zst -C "$HOME/usr/local/$PREFIX"
  else
    unzstd -c wget2-deps.tar.zst | tar -xf - -C "$HOME/usr/local/$PREFIX"
  fi

  echo ">>> 依赖解压完成"
  cd "$INSTALLDIR" || { echo "❌ $INSTALLDIR 不存在"; exit 1; }
}

build_brotli() {
  echo "⭐⭐⭐⭐⭐⭐ build brotli ⭐⭐⭐⭐⭐⭐"
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
  sed -i 's/^Libs: .*/& -lbrotlicommon/' "$INSTALLDIR/lib/pkgconfig/libbrotlidec.pc"
  cd ../.. && rm -rf brotli
}

build_xz() {
  echo "⭐⭐⭐⭐⭐⭐ build xz ⭐⭐⭐⭐⭐⭐" 
  apt-get purge -y xz-utils 2>/dev/null || true
  git clone --depth=1 https://github.com/tukaani-project/xz.git || { echo "Git clone failed"; exit 1; }
  cd xz || { echo "cd xz failed"; exit 1; }
  mkdir build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=$INSTALLDIR -DCMAKE_BUILD_TYPE=Release -DXZ_NLS=ON -DBUILD_SHARED_LIBS=OFF || { echo "CMake failed"; exit 1; }
  cmake --build . -- -j$(nproc) || { echo "Build failed"; exit 1; }
  cmake --install . || { echo "Install failed"; exit 1; }
  cd ../.. && rm -rf xz
}

build_zstd() {
  echo "⭐⭐⭐⭐⭐⭐ build zstd ⭐⭐⭐⭐⭐⭐" 
  rm -rf /tmp/venv
  python3 -m venv /tmp/venv
  source /tmp/venv/bin/activate
  pip3 install --no-cache-dir meson pytest

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
  
  rm -f /usr/local/bin/zstd*
  rm -f /usr/local/bin/*zstd
  meson compile -C builddir-st || exit 1
  meson install -C builddir-st || exit 1
  cd .. && rm -rf zstd
}

build_zlib-ng() {
  echo "⭐⭐⭐⭐⭐⭐ build zlib-ng ⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 https://github.com/zlib-ng/zlib-ng || exit 1
  cd zlib-ng || exit 1
  CROSS_PREFIX="x86_64-w64-mingw32-" ARCH="x86_64" CFLAGS="-Os" CC=x86_64-w64-mingw32-gcc ./configure --prefix=$INSTALLDIR --static --64 --zlib-compat || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf zlib-ng
}

build_PCRE2() {
  echo "⭐⭐⭐⭐⭐⭐ build PCRE2 ⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 https://github.com/PCRE2Project/pcre2 || exit 1
  cd pcre2 || exit 1
  ./autogen.sh || exit 1
  ./configure --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf pcre2
}

build_libpsl() {
  echo "⭐⭐⭐⭐⭐⭐ build libpsl ⭐⭐⭐⭐⭐⭐" 
  git clone --depth=1 --recursive https://github.com/rockdaboot/libpsl.git || exit 1
  cd libpsl || exit 1
  ./autogen.sh || exit 1
  ./configure --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --enable-runtime=libidn2 --enable-builtin --prefix=$INSTALLDIR || exit 1
  make -j$(nproc) || exit 1
  make install || exit 1
  cd .. && rm -rf libpsl
}

build_wget2() {
  echo "⭐⭐⭐⭐⭐⭐ build wget2 ⭐⭐⭐⭐⭐⭐" 
  git clone https://gitlab.com/gnuwget/wget2.git || exit 1
  cd wget2 || exit 1
  if [ -d "gnulib" ]; then rm -rf gnulib; fi
  git clone --depth=1 https://github.com/coreutils/gnulib.git
  ./bootstrap --skip-po --gnulib-srcdir=gnulib || exit 1

  # 【核心修改】
  # 1. 移除全局导出的 LIBS，避免污染 configure 的特性检测。
  # 2. 将依赖库通过各自的 *_LIBS 变量传递。
  # 3. 将通用系统库和 LDFLAGS 整合。
  
  # 依赖组件定义
  MY_SSL_LIBS="-L$INSTALLDIR/lib -lgnutls -lhogweed -lnettle -lgmp"
  MY_BASE_LIBS="-ltasn1 -lidn2 -lunistring -liconv"
  MY_SYS_LIBS="-lbcrypt -lncrypt -lws2_32 -lcrypt32 -lsecur32 -luser32 -lkernel32 -lwinpthread"
  MY_COMP_LIBS="-lzstd -lbrotlidec -lbrotlicommon -lz"
  
  # 注意：这里我们通过 LDFLAGS 确保静态链接行为，
  # 并通过特定的变量告诉 configure 如何链接特定模块，而不是把所有东西塞进 LIBS。
  
  export LDFLAGS="$LDFLAGS -L$INSTALLDIR/lib -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive"

  GNUTLS_CFLAGS="-I$INSTALLDIR/include" \
  GNUTLS_LIBS="$MY_SSL_LIBS $MY_BASE_LIBS $MY_SYS_LIBS" \
  LIBPSL_CFLAGS="-I$INSTALLDIR/include" \
  LIBPSL_LIBS="-L$INSTALLDIR/lib -lpsl $MY_BASE_LIBS" \
  LIBPCRE2_CFLAGS="-I$INSTALLDIR/include" \
  LIBPCRE2_LIBS="-L$INSTALLDIR/lib -lpcre2-8" \
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
    --enable-threads=windows \
    LIBS="$MY_SYS_LIBS $MY_COMP_LIBS" || exit 1
    # 上面这行 LIBS 仅作为补充，用于传递 configure 无法通过 PKG_CONFIG 自动找到的底层库（如系统库）
    # 但不要包含像 gnutls 这样需要精确检测的库

  # Winsock 补丁
  sed -i '/#include <config.h>/a #ifdef _WIN32\n#include <winsock2.h>\n#include <pthread.h>\n#endif' tests/libtest.c
  sed -i 's/int flags = fcntl(client_fd, F_GETFL, 0);/#ifdef _WIN32\n\t\tunsigned long mode = 1;\n\t\tioctlsocket(client_fd, FIONBIO, \&mode);\n#else\n\t\tint flags = fcntl(client_fd, F_GETFL, 0);/' tests/libtest.c
  sed -i '/fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);/a #endif' tests/libtest.c
  
  make -j$(nproc) || exit 1
  strip $INSTALLDIR/wget2/src/wget2.exe || exit 1
  cp -fv "$INSTALLDIR/wget2/src/wget2.exe" "${GITHUB_WORKSPACE}" || exit 1
}

# 流程执行
download_deps
wait

# 并行编译依赖
build_brotli &
build_zstd &
build_zlib-ng &
build_PCRE2 &
wait

# 单独编译 libpsl
build_libpsl 

# 最后编译 wget2
build_wget2
