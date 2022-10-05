#!/bin/bash

set -euo pipefail

declare -a args=()

add_env_var_as_env_prop() {
  if [ "$1" ]; then
    args+=("-D$2=$1")
  fi
}

# If there are certificates in /tmp/cacers we will import those into the systems truststore
if [ -d /tmp/cacerts ]; then
  if [ "$(ls -A /tmp/cacerts)" ]; then
    for f in /tmp/cacerts/*
    do
      keytool -importcert -file "${f}" -alias "$(basename ${f})" -keystore /usr/lib/jvm/default-jvm/jre/lib/security/cacerts -storepass changeit 
-trustcacerts -noprompt
    done
  fi
fi

# if nothing is passed, assume we want to run sonar-scanner
if [[ "$#" == 0 ]]; then
  set -- sonar-scanner
fi

# if first arg looks like a flag, assume we want to run sonar-scanner with flags
if [[ "${1#-}" != "${1}" ]] || [[ -z "$(command -v "${1}")" ]]; then
  set -- sonar-scanner "$@"
fi

if [[ "$1" = 'sonar-scanner' ]]; then
  add_env_var_as_env_prop "${SONAR_LOGIN:-}" "sonar.login"
  add_env_var_as_env_prop "${SONAR_PASSWORD:-}" "sonar.password"
  add_env_var_as_env_prop "${SONAR_PROJECT_BASE_DIR:-}" "sonar.projectBaseDir"
  if [ ${#args[@]} -ne 0 ]; then
    set -- sonar-scanner "${args[@]}" "${@:2}"
  fi
fi

copy_reference_files() {
  local log="$MAVEN_CONFIG/copy_reference_file.log"
  local ref="/usr/share/maven/ref"

  if mkdir -p "${MAVEN_CONFIG}/repository" && touch "${log}" > /dev/null 2>&1 ; then
      cd "${ref}"
      local reflink=""
      if cp --help 2>&1 | grep -q reflink ; then
          reflink="--reflink=auto"
      fi
      if [ -n "$(find "${MAVEN_CONFIG}/repository" -maxdepth 0 -type d -empty 2>/dev/null)" ] ; then
          # destination is empty...
          echo "--- Copying all files to ${MAVEN_CONFIG} at $(date)" >> "${log}"
          cp -rv ${reflink} . "${MAVEN_CONFIG}" >> "${log}"
      else
          # destination is non-empty, copy file-by-file
          echo "--- Copying individual files to ${MAVEN_CONFIG} at $(date)" >> "${log}"
          find . -type f -exec sh -eu -c '
              log="${1}"
              shift
              reflink="${1}"
              shift
              for f in "$@" ; do
                  if [ ! -e "${MAVEN_CONFIG}/${f}" ] || [ -e "${f}.override" ] ; then
                      mkdir -p "${MAVEN_CONFIG}/$(dirname "${f}")"
                      cp -rv ${reflink} "${f}" "${MAVEN_CONFIG}/${f}" >> "${log}"
                  fi
              done
          ' _ "${log}" "${reflink}" {} +
      fi
      echo >> "${log}"
  else
    echo "Can not write to ${log}. Wrong volume permissions? Carrying on ..."
  fi
}

owd="$(pwd)"
copy_reference_files
unset MAVEN_CONFIG

cd "${owd}"
unset owd


exec "$@"
