# Build binutils, c wrapper, and uClibc++

# TOOLCHAIN_PREFIX affects the name of the generated tools, ala "${ARCH}-".

# Force gcc to build, largely against its will.

setupfor gcc-core
[ -z "$NO_CPLUSPLUS" ] && REUSE_CURSRC=1 setupfor gcc-g++

blank_workdir build-gcc

# GCC tries to "help out in the kitchen" by screwing up the kernel include
# files.  Surgery with sed to cut out that horrible idea throw it away.

sed -i 's@^STMP_FIX.*@@' "${CURSRC}/gcc/Makefile.in" || dienow

# The gcc ./configure manages to make the binutils one look sane.  Again,
# wrap it so we can call it with different variables to beat sense out of it.

function configure_gcc()
{
  # Are we building C only, or C and C++?
  [ -z "$NO_CPLUSPLUS" ] &&
    STUFF="--enable-languages=c,c++ --disable-libstdcxx-pch" ||
    STUFF="--enable-languages=c"

  # Configure gcc
  "$CURSRC/configure" --target="$CROSS_TARGET" --prefix="$STAGE_DIR" \
    --disable-multilib --disable-nls --enable-c99 --enable-long-long \
    --enable-__cxa_atexit $STUFF --program-prefix="$TOOLCHAIN_PREFIX" \
    "$@" $GCC_FLAGS &&

  # Provide xgcc as a symlink to the target compiler, so gcc doesn't waste
  # time trying to rebuild itself with itself.  (If we want that, we'll do it
  # ourselves via canadian cross.)
  mkdir -p gcc &&
  ln -s "$(which ${CC_FOR_TARGET:-cc})" gcc/xgcc || dienow
}

if [ -z "$HOST_ARCH" ]
then
  # Produce a standard host->target cross compiler, which does not include
  # thread support or libgcc_s.so to make it depend on the host less.

  # The only prerequisite for this is binutils, above.  (It doesn't even
  # require a C library for the target to exist yet, which is good because you
  # have a chicken and egg problem otherwise.  What would you have compiled
  # that C library _with_?)

  AR_FOR_TARGET="${CC_PREFIX}ar" configure_gcc \
    --disable-threads --disable-shared --host="$CROSS_HOST"
else
  # Canadian cross a compiler to run on $HOST_ARCH as its host and output
  # binaries for $ARCH as its target.

  # GCC has some deep assumptions here, which are wrong.  Lots of redundant
  # corrections are required to make it stop.

  [ -z "$ELF2FLT" ] && X=--enable-shared || X=--disable-shared
  CC="${HOST_ARCH}-cc" AR="${HOST_ARCH}-ar" AS="${HOST_ARCH}-as" \
    LD="${HOST_ARCH}-ld" NM="${HOST_ARCH}-nm" \
    CC_FOR_TARGET="${CC_PREFIX}cc" AR_FOR_TARGET="${CC_PREFIX}ar" \
    NM_FOR_TARGET="${CC_PREFIX}nm" GCC_FOR_TARGET="${CC_PREFIX}cc" \
    AS_FOR_TARGET="${CC_PREFIX}as" LD_FOR_TARGET="${CC_PREFIX}ld" \
    CXX_FOR_TARGET="${CC_PREFIX}c++" \
    ac_cv_path_AR_FOR_TARGET="${CC_PREFIX}ar" \
    ac_cv_path_RANLIB_FOR_TARGET="${CC_PREFIX}ranlib" \
    ac_cv_path_NM_FOR_TARGET="${CC_PREFIX}nm" \
    ac_cv_path_AS_FOR_TARGET="${CC_PREFIX}as" \
    ac_cv_path_LD_FOR_TARGET="${CC_PREFIX}ld" \
    configure_gcc --enable-threads=posix $X \
      --build="$CROSS_HOST" --host="${CROSS_TARGET/unknown-elf/walrus-elf}"
fi

# Now that it's configured, build and install gcc

make -j $CPUS configure-host &&
make -j $CPUS all-gcc LDFLAGS="$STATIC_FLAGS" &&

mkdir -p "$STAGE_DIR"/cc/lib || dienow

if [ ! -z "$HOST_ARCH" ] && [ -z "$NO_CPLUSPLUS" ]
then
  # We also need to beat libsupc++ out of gcc (which uClibc++ needs to build).
  # But don't want to build the whole of libstdc++-v3 because
  # A) we're using uClibc++ instead,  B) the build breaks.

  # The libsupc++ ./configure dies if run after the simple cross compiling
  # ./configure, because gcc's build system is overcomplicated crap, so skip
  # the uClibc++ build first time around and only do it for the canadian cross
  # builds.  (The simple cross compiler still needs basic C++ support to build
  # the C++ libraries with, though.)

  make -j $CPUS configure-target-libstdc++-v3 SHELL=sh &&
  cd "$CROSS_TARGET"/libstdc++-v3/libsupc++ &&
  make -j $CPUS &&
  mv .libs/libsupc++.a "$STAGE_DIR"/cc/lib &&
  cd ../../.. || dienow
fi

# Work around gcc bug during the install: we disabled multilib but it doesn't
# always notice.

ln -s lib "$STAGE_DIR/lib64" &&
make -j $CPUS install-gcc &&
rm "$STAGE_DIR/lib64" || dienow

# Move the gcc internal libraries and headers somewhere sane

rm -rf "$STAGE_DIR"/lib/gcc/*/*/install-tools 2>/dev/null
mv "$STAGE_DIR"/lib/gcc/*/*/include "$STAGE_DIR"/cc/include &&
mv "$STAGE_DIR"/lib/gcc/*/*/* "$STAGE_DIR"/cc/lib &&

# Move the compiler internal binaries into "tools"
ln -s "$CROSS_TARGET" "$STAGE_DIR/tools" &&
cp "$STAGE_DIR/libexec/gcc/"*/*/c* "$STAGE_DIR/tools/bin" &&
rm -rf "$STAGE_DIR/libexec" || dienow

# collect2 is evil, kill it.
# ln -sf ../../../../tools/bin/ld  ${STAGE_DIR}/libexec/gcc/*/*/collect2 || dienow

# Prepare for ccwrap

mv "$STAGE_DIR/bin/${TOOLCHAIN_PREFIX}gcc" "$STAGE_DIR/tools/bin/cc" &&
ln -sf "${TOOLCHAIN_PREFIX}cc" "$STAGE_DIR/bin/${TOOLCHAIN_PREFIX}gcc" &&
ln -s cc "$STAGE_DIR/tools/bin/rawcc" &&

# Wrap C++ too.

if [ -z "$NO_CPLUSPLUS" ]
then
  mv "$STAGE_DIR/bin/${TOOLCHAIN_PREFIX}g++" "$STAGE_DIR/tools/bin/c++" &&
  ln -sf "${TOOLCHAIN_PREFIX}cc" "$STAGE_DIR/bin/${TOOLCHAIN_PREFIX}g++" &&
  ln -sf "${TOOLCHAIN_PREFIX}cc" "$STAGE_DIR/bin/${TOOLCHAIN_PREFIX}c++" &&
  ln -s c++ "$STAGE_DIR/tools/bin/raw++" || dienow
fi

# Make sure "tools" has everything distccd needs.

cd "$STAGE_DIR/tools" || dienow
ln -s cc "$STAGE_DIR/tools/bin/gcc" 2>/dev/null
[ -z "$NO_CPLUSPLUS" ] && ln -s c++ "$STAGE_DIR/tools/bin/g++" 2>/dev/null

rm -rf "${STAGE_DIR}"/{lib/gcc,libexec/gcc/install-tools,bin/${ARCH}-unknown-*}

# Call binary package tarball "gcc", not "gcc-core".

PACKAGE=gcc cleanup
