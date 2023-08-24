#!/bin/bash

# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script for building bazel from scratch without bazel

PROTO_FILES=$(ls src/main/protobuf/*.proto src/main/java/com/google/devtools/build/lib/buildeventstream/proto/*.proto)
LIBRARY_JARS=$(find third_party -name '*.jar' | grep -Fv /javac.jar | grep -Fv /javac7.jar | grep -Fv JavaBuilder | grep -ve third_party/grpc/grpc.*jar | tr "\n" " ")
GRPC_JAVA_VERSION=0.15.0
GRPC_LIBRARY_JARS=$(find third_party/grpc -name '*.jar' | grep -e .*${GRPC_JAVA_VERSION}.*jar | tr "\n" " ")
LIBRARY_JARS="${LIBRARY_JARS} ${GRPC_LIBRARY_JARS}"
DIRS=$(echo src/{java_tools/singlejar/java/com/google/devtools/build/zip,main/java,tools/xcode-common/java/com/google/devtools/build/xcode/{common,util}} third_party/java/dd_plist/java ${OUTPUT_DIR}/src)
EXCLUDE_FILES=src/main/java/com/google/devtools/build/lib/server/GrpcServerImpl.java

mkdir -p ${OUTPUT_DIR}/classes
mkdir -p ${OUTPUT_DIR}/src

# May be passed in from outside.
ZIPOPTS="$ZIPOPTS"

unset JAVA_TOOL_OPTIONS
unset _JAVA_OPTIONS

LDFLAGS=${LDFLAGS:-""}

MSYS_DLLS=""
PATHSEP=":"

case "${PLATFORM}" in
linux)
  # JAVA_HOME must point to a Java installation.
  JAVA_HOME="${JAVA_HOME:-$(readlink -f $(which javac) | sed 's_/bin/javac__')}"
  if [ "${MACHINE_IS_64BIT}" = 'yes' ]; then
    if [ "${MACHINE_IS_Z}" = 'yes' ]; then
       PROTOC=${PROTOC:-third_party/protobuf/protoc-linux-s390x_64.exe}
       GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-linux-s390x_64.exe}
    else
       PROTOC=${PROTOC:-third_party/protobuf/protoc-linux-x86_64.exe}
       GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-linux-x86_64.exe}
    fi
  else
    if [ "${MACHINE_IS_ARM}" = 'yes' ]; then
      PROTOC=${PROTOC:-third_party/protobuf/protoc-linux-arm32.exe}
    else
      PROTOC=${PROTOC:-third_party/protobuf/protoc-linux-x86_32.exe}
      GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-linux-x86_32.exe}
    fi
  fi
  ;;

freebsd)
  # JAVA_HOME must point to a Java installation.
  JAVA_HOME="${JAVA_HOME:-/usr/local/openjdk8}"
  # Note: the linux protoc binary works on freebsd using linux emulation.
  # We choose the 32-bit version for maximum compatiblity since 64-bit
  # linux binaries are only supported in FreeBSD-11.
  PROTOC=${PROTOC:-third_party/protobuf/protoc-linux-x86_32.exe}
  GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-linux-x86_32.exe}
  ;;

darwin)
  if [[ -z "$JAVA_HOME" ]]; then
    JAVA_HOME="$(/usr/libexec/java_home -v ${JAVA_VERSION}+ 2> /dev/null)" \
      || fail "Could not find JAVA_HOME, please ensure a JDK (version ${JAVA_VERSION}+) is installed."
  fi
  if [ "${MACHINE_IS_64BIT}" = 'yes' ]; then
    PROTOC=${PROTOC:-third_party/protobuf/protoc-osx-x86_64.exe}
    GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-osx-x86_64.exe}
  else
    PROTOC=${PROTOC:-third_party/protobuf/protoc-osx-x86_32.exe}
  fi
  ;;

msys*|mingw*)
  # Use a simplified platform string.
  PLATFORM="mingw"
  PATHSEP=";"
  # Find the latest available version of the SDK.
  JAVA_HOME="${JAVA_HOME:-$(ls -d /c/Program\ Files/Java/jdk* | sort | tail -n 1)}"
  # We do not use the JNI library on Windows.
  if [ "${MACHINE_IS_64BIT}" = 'yes' ]; then
    PROTOC=${PROTOC:-third_party/protobuf/protoc-windows-x86_64.exe}
    GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-windows-x86_64.exe}
  else
    PROTOC=${PROTOC:-third_party/protobuf/protoc-windows-x86_32.exe}
    GRPC_JAVA_PLUGIN=${GRPC_JAVA_PLUGIN:-third_party/grpc/protoc-gen-grpc-java-0.15.0-windows-x86_32.exe}
  fi
esac

[[ -x "${PROTOC-}" ]] \
    || fail "Protobuf compiler not found in ${PROTOC-}"

[[ -x "${GRPC_JAVA_PLUGIN-}" ]] \
    || fail "gRPC Java plugin not found in ${GRPC_JAVA_PLUGIN-}"

# Check that javac -version returns a upper version than $JAVA_VERSION.
get_java_version
[ ${JAVA_VERSION#*.} -le ${JAVAC_VERSION#*.} ] || \
  fail "JDK version (${JAVAC_VERSION}) is lower than ${JAVA_VERSION}, please set \$JAVA_HOME."

JAR="${JAVA_HOME}/bin/jar"

# Compiles java classes.
function java_compilation() {
  local name=$1
  local directories=$2
  local excludes=$3
  local library_jars=$4
  local output=$5

  local classpath=${library_jars// /$PATHSEP}:$5
  local sourcepath=${directories// /$PATHSEP}

  tempdir
  local tmp="${NEW_TMPDIR}"
  local paramfile="${tmp}/param"
  local filelist="${tmp}/filelist"
  local excludefile="${tmp}/excludefile"
  touch $paramfile

  mkdir -p "${output}/classes"

  # Compile .java files (incl. generated ones) using javac
  log "Compiling $name code..."
  find ${directories} -name "*.java" | sort > "$filelist"
  # Quotes around $excludes intentionally omitted in the for statement so that
  # it's split on spaces
  (for i in $excludes; do
    echo $i
  done) | sort > "$excludefile"

  comm -23 "$filelist" "$excludefile" > "$paramfile"

  if [ ! -z "$BAZEL_DEBUG_JAVA_COMPILATION" ]; then
    echo "directories=${directories}" >&2
    echo "classpath=${classpath}" >&2
    echo "sourcepath=${sourcepath}" >&2
    echo "libraries=${library_jars}" >&2
    echo "output=${output}/classes" >&2
    echo "List of compiled files:" >&2
    cat "$paramfile" >&2
  fi

  run "${JAVAC}" -classpath "${classpath}" -sourcepath "${sourcepath}" \
      -d "${output}/classes" -source "$JAVA_VERSION" -target "$JAVA_VERSION" \
      -encoding UTF-8 "@${paramfile}"

  log "Extracting helper classes for $name..."
  for f in ${library_jars} ; do
    run unzip -qn ${f} -d "${output}/classes"
  done
}

# Create the deploy JAR
function create_deploy_jar() {
  local name=$1
  local mainClass=$2
  local output=$3
  shift 3
  local packages=""
  for i in $output/classes/*; do
    local package=$(basename $i)
    if [[ "$package" != "META-INF" ]]; then
      packages="$packages -C $output/classes $package"
    fi
  done

  log "Creating $name.jar..."
  echo "Main-Class: $mainClass" > $output/MANIFEST.MF
  run "$JAR" cmf $output/MANIFEST.MF $output/$name.jar $packages "$@"
}

if [ -z "${BAZEL_SKIP_JAVA_COMPILATION}" ]; then
  log "Compiling Java stubs for protocol buffers..."
  for f in $PROTO_FILES ; do
    run "${PROTOC}" -Isrc/main/protobuf/ \
        -Isrc/main/java/com/google/devtools/build/lib/buildeventstream/proto/ \
        --java_out=${OUTPUT_DIR}/src \
        --plugin=protoc-gen-grpc="${GRPC_JAVA_PLUGIN-}" \
        --grpc_out=${OUTPUT_DIR}/src "$f"
  done

  java_compilation "Bazel Java" "$DIRS" "$EXCLUDE_FILES" "$LIBRARY_JARS" "${OUTPUT_DIR}"

  # help files: all non java and BUILD files in src/main/java.
  for i in $(find src/main/java -type f -a \! -name '*.java' -a \! -name 'BUILD' | sed 's|src/main/java/||'); do
    mkdir -p $(dirname ${OUTPUT_DIR}/classes/$i)
    cp src/main/java/$i ${OUTPUT_DIR}/classes/$i
  done

  # Overwrite tools.WORKSPACE, this is only for the bootstrap binary
  chmod u+w "${OUTPUT_DIR}/classes/com/google/devtools/build/lib/bazel/rules/tools.WORKSPACE"
  cat <<EOF >${OUTPUT_DIR}/classes/com/google/devtools/build/lib/bazel/rules/tools.WORKSPACE
local_repository(name = 'bazel_tools', path = __workspace_dir__)
bind(name = "cc_toolchain", actual = "@bazel_tools//tools/cpp:default-toolchain")
EOF

  create_deploy_jar "libblaze" "com.google.devtools.build.lib.bazel.BazelMain" \
      ${OUTPUT_DIR}
fi

log "Creating Bazel install base..."
ARCHIVE_DIR=${OUTPUT_DIR}/archive
mkdir -p ${ARCHIVE_DIR}/_embedded_binaries

# Dummy build-runfiles
cat <<'EOF' >${ARCHIVE_DIR}/_embedded_binaries/build-runfiles${EXE_EXT}
#!/bin/sh
mkdir -p $2
cp $1 $2/MANIFEST
EOF
chmod 0755 ${ARCHIVE_DIR}/_embedded_binaries/build-runfiles${EXE_EXT}

log "Creating process-wrapper..."
cat <<'EOF' >${ARCHIVE_DIR}/_embedded_binaries/process-wrapper${EXE_EXT}
#!/bin/sh
# Dummy process wrapper, does not support timeout
shift 2
stdout="$1"
stderr="$2"
shift 2

if [ "$stdout" = "-" ]
then
  if [ "$stderr" = "-" ]
  then
    "$@"
    exit $?
  else
    "$@" 2>"$stderr"
    exit $?
  fi
else
  if [ "$stderr" = "-" ]
  then
    "$@" >"$stdout"
    exit $?
  else
    "$@" 2>"$stderr" >"$stdout"
    exit $?
  fi
fi


"$@"
exit $?
EOF
chmod 0755 ${ARCHIVE_DIR}/_embedded_binaries/process-wrapper${EXE_EXT}

cp src/main/tools/build_interface_so ${ARCHIVE_DIR}/_embedded_binaries/build_interface_so
cp src/main/tools/jdk.BUILD ${ARCHIVE_DIR}/_embedded_binaries/jdk.BUILD
cp $OUTPUT_DIR/libblaze.jar ${ARCHIVE_DIR}

# TODO(b/28965185): Remove when xcode-locator is no longer required in embedded_binaries.
log "Compiling xcode-locator..."
if [[ $PLATFORM == "darwin" ]]; then
  run /usr/bin/xcrun clang -fobjc-arc -framework CoreServices -framework Foundation -o ${ARCHIVE_DIR}/_embedded_binaries/xcode-locator tools/osx/xcode_locator.m
else
  cp tools/osx/xcode_locator_stub.sh ${ARCHIVE_DIR}/_embedded_binaries/xcode-locator
fi

function run_bazel_jar() {
  local command=$1
  shift
  "${JAVA_HOME}/bin/java" \
      -XX:+HeapDumpOnOutOfMemoryError -Xverify:none -Dfile.encoding=ISO-8859-1 \
      -XX:HeapDumpPath=${OUTPUT_DIR} \
      -Djava.util.logging.config.file=${OUTPUT_DIR}/javalog.properties \
      -Dio.bazel.EnableJni=0 \
      -jar ${ARCHIVE_DIR}/libblaze.jar \
      --batch \
      --install_base=${ARCHIVE_DIR} \
      --output_base=${OUTPUT_DIR}/out \
      --install_md5= \
      --workspace_directory=${PWD} \
      --nofatal_event_bus_exceptions \
      ${BAZEL_DIR_STARTUP_OPTIONS} \
      ${BAZEL_BOOTSTRAP_STARTUP_OPTIONS:-} \
      $command \
      --ignore_unsupported_sandboxing \
      --startup_time=329 --extract_data_time=523 \
      --rc_source=/dev/null --isatty=1 \
      --ignore_client_env \
      --client_cwd=${PWD} \
      "${@}"
}
