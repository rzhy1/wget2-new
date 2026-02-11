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
export CFLAGS="-march=tigerlake -mtune=tigerlake -Os -pipe -flto=$(nproc) -g0 -fvisibility=hidden -Wno-attributes -Wno-inline -Wno-pointer-to-int-cast -Wno-return-local-addr"
export CXXFLAGS="$CFLAGS"
export WINEPATH="$INSTALLDIR/bin;$INSTALLDIR/lib;/usr/$PREFIX/bin;/usr/$PREFIX/lib"
#export LD=x86_64-w64-mingw32-ld.lld
#ln -s $(which lld-link) /usr/bin/x86_64-w64-mingw32-ld.lld
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
  apt-get purge xz-utils
  git clone --depth=1 https://github.com/tukaani-project/xz.git || { echo "Git clone failed"; exit 1; }
  cd xz || { echo "cd xz failed"; exit 1; }
  mkdir build
  cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DXZ_NLS=ON -DBUILD_SHARED_LIBS=OFF || { echo "CMake failed"; exit 1; }
  cmake --build . -- -j$(nproc) || { echo "Build failed"; exit 1; }
  cmake --install . || { echo "Install failed"; exit 1; }
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
  rm -f /usr/local/bin/zstd*
  rm -f /usr/local/bin/*zstd
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
  rm -rf gnulib
  git clone --depth=1 https://github.com/coreutils/gnulib.git
  ./bootstrap --skip-po --gnulib-srcdir=gnulib || exit 1

  # ========== 应用源码补丁，修复已知警告 ==========
  # 1. blacklist.c: 修复返回局部变量地址（第156行）
  if grep -q "return fname;" src/blacklist.c; then
    echo ">>> 应用 blacklist.c 补丁"
    sed -i 's/char tmp\[1024\];/static char tmp[1024];/' src/blacklist.c
  fi

  # 2. css.c / css_tokenizer.c: 匹配 yyalloc/yyrealloc 签名
  if grep -q "void \*yyalloc(size_t size)" libwget/css.c; then
    echo ">>> 应用 css.c 补丁"
    sed -i 's/void \*yyalloc(size_t size)/void \*yyalloc(size_t size, void *yyscanner)/' libwget/css.c
    sed -i 's/void \*yyrealloc(void \*p, size_t size)/void \*yyrealloc(void \*p, size_t size, void *yyscanner)/' libwget/css.c
  fi

  # ========== 配置编译 ==========
  export LDFLAGS="$LDFLAGS -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive"
  export CPPFLAGS="$CPPFLAGS -I$INSTALLDIR/include"

  GNUTLS_CFLAGS="-I$INSTALLDIR/include" \
  GNUTLS_LIBS="-L$INSTALLDIR/lib -lgnutls -lhogweed -lnettle -lgmp -ltasn1 -lidn2 -lunistring -liconv -lbcrypt -lncrypt -lws2_32 -lcrypt32 -lsecur32 -luser32 -lkernel32 -lwinpthread" \
  LIBPSL_CFLAGS="-I$INSTALLDIR/include" \
  LIBPSL_LIBS="-L$INSTALLDIR/lib -lpsl" \
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
    --enable-threads=windows

  # Winsock 补丁（测试代码）
  sed -i '/#include <config.h>/a #ifdef _WIN32\n#include <winsock2.h>\n#include <pthread.h>\n#endif' tests/libtest.c
  sed -i 's/int flags = fcntl(client_fd, F_GETFL, 0);/#ifdef _WIN32\n\t\tunsigned long mode = 1;\n\t\tioctlsocket(client_fd, FIONBIO, \&mode);\n#else\n\t\tint flags = fcntl(client_fd, F_GETFL, 0);/' tests/libtest.c
  sed -i '/fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);/a #endif' tests/libtest.c

  # 编译
  make -j$(nproc) || exit 1

  # 检查并复制产物
  if [ -f "src/wget2.exe" ]; then
    strip src/wget2.exe
    cp -fv src/wget2.exe "${GITHUB_WORKSPACE:-.}"
    echo "✅ wget2.exe 编译成功！"
  else
    echo "❌ 编译失败：未找到 wget2.exe"
    exit 1
  fi
}
download_deps
wait
build_brotli &
build_zstd &
build_zlib-ng &
build_PCRE2 &
wait
build_wget2
