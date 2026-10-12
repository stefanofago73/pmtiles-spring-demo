#!/bin/sh
# Maven Wrapper: downloads Maven if not present, then runs it.
# https://maven.apache.org/wrapper/
set -e

# Resolve project base directory
if [ -z "$MAVEN_PROJECTBASEDIR" ]; then
  exec_dir=$(pwd -P)
  wdir=$exec_dir
  while [ ! -f "$wdir/.mvn/wrapper/maven-wrapper.properties" ] && [ "$wdir" != "/" ]; do
    wdir=$(cd "$wdir/.." && pwd -P)
  done
  MAVEN_PROJECTBASEDIR=$wdir
  export MAVEN_PROJECTBASEDIR
fi

WRAPPER_PROPERTIES="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.properties"
if [ ! -f "$WRAPPER_PROPERTIES" ]; then
  echo "Error: .mvn/wrapper/maven-wrapper.properties not found." >&2; exit 1
fi

# Read distribution URL
distributionUrl=$(grep "^distributionUrl=" "$WRAPPER_PROPERTIES" | cut -d'=' -f2-)
if [ -z "$distributionUrl" ]; then
  echo "Error: distributionUrl not found in maven-wrapper.properties" >&2; exit 1
fi

# Maven user home
MAVEN_USER_HOME="${MAVEN_USER_HOME:-${HOME}/.m2}"
WRAPPER_DIR="$MAVEN_USER_HOME/wrapper/dists"

# Extract version from URL
mvn_version=$(echo "$distributionUrl" | sed 's|.*/apache-maven-\([0-9.]*\)-bin\.zip|\1|')
MAVEN_HOME="$WRAPPER_DIR/apache-maven-$mvn_version"

if [ ! -d "$MAVEN_HOME/bin" ]; then
  echo "Downloading Maven $mvn_version..."
  mkdir -p "$WRAPPER_DIR"
  TMP_FILE="$WRAPPER_DIR/maven-$mvn_version.zip"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL -o "$TMP_FILE" "$distributionUrl"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$TMP_FILE" "$distributionUrl"
  else
    echo "Error: curl or wget required." >&2; exit 1
  fi
  unzip -q -o "$TMP_FILE" -d "$WRAPPER_DIR"
  rm -f "$TMP_FILE"
  chmod +x "$MAVEN_HOME/bin/mvn"
fi

exec "$MAVEN_HOME/bin/mvn" "$@"
