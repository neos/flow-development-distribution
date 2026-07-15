#!/bin/bash -xe

#
# Updates the dependencies in composer.json files of the dist and its
# packages.
#
# Needs the following parameters
#
# VERSION          the version that is "to be released"
# BRANCH           the branch that is worked on, used in commit message
# BUILD_URL        used in commit message
#

source "$(dirname "${BASH_SOURCE[0]}")/BuildEssentials/ReleaseHelpers.sh"

COMPOSER_PHAR="$(dirname "${BASH_SOURCE[0]}")/../composer.phar"
if [ ! -f "${COMPOSER_PHAR}" ]; then
  echo >&2 "No composer.phar, expected it at ${COMPOSER_PHAR}"
  exit 1
fi

if [ -z "$1" ]; then
  echo >&2 "No version specified (e.g. 2.1.*) as first parameter."
  exit 1
else
  if [[ $1 =~ (dev)-.+ || $1 =~ .+(@dev|.x-dev) || $1 =~ (alpha|beta|RC|rc)[0-9]+ ]]; then
    EXACT_VERSION_OR_MINOR="$1"
    STABILITY_FLAG=${BASH_REMATCH[1]}
  else
    if [[ $1 =~ ([0-9]+\.[0-9]+)\.[0-9] ]]; then
      EXACT_VERSION_OR_MINOR="~${BASH_REMATCH[1]}.0"
    else
      echo >&2 "Version $1 could not be parsed."
      exit 1
    fi
  fi
fi

if [ -z "$2" ]; then
  echo >&2 "No branch specified (e.g. 2.1) as second parameter."
  exit 1
fi
BRANCH=$2

if [ -z "$3" ]; then
  echo >&2 "No build URL specified as third parameter."
  exit 1
fi
BUILD_URL="$3"

if [ ! -d "Distribution" ]; then
  echo '"Distribution" folder not found. Clone the base distribution into "Distribution"'
  exit 1
fi

echo "Setting distribution dependencies"

# Require exact versions or minor level of the main packages
php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/flow:${EXACT_VERSION_OR_MINOR}"

# Require some version of the same minor level of the main packages
if [[ ${STABILITY_FLAG} ]]; then
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/welcome:${BRANCH}.x-dev"
else
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/welcome:~${BRANCH}.0"
fi

# Allow main packages require their required sub dependency packages, allowing unstable
if [[ ${STABILITY_FLAG} ]]; then
  if [[ "$STABILITY_FLAG" =~ ^(dev|alpha|beta|RC|rc)$ ]]; then
    COMPOSER_STABILITY_FLAG=${STABILITY_FLAG}
  else
    COMPOSER_STABILITY_FLAG="dev"
  fi
  composer config minimum-stability $COMPOSER_STABILITY_FLAG
  composer config prefer-stable true
else
  composer config --unset prefer-stable
  composer config --unset minimum-stability
fi

# Require exact versions of the main dev packages
php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/kickstarter:${EXACT_VERSION_OR_MINOR}"

# Require some version of the same minor level of main dev packages
if [[ ${STABILITY_FLAG} ]]; then
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/behat:${BRANCH}.x-dev"
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/buildessentials:${BRANCH}.x-dev"
else
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/behat:~${BRANCH}.0"
  php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/buildessentials:~${BRANCH}.0"
fi
commit_manifest_update "${BRANCH}" "${BUILD_URL}" "${EXACT_VERSION_OR_MINOR}" "Distribution"

echo "Setting packages dependencies"

php "${COMPOSER_PHAR}" --working-dir=Packages/Application/Neos.Welcome require --no-update "neos/flow:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Application/Neos.Welcome require --no-update "neos/fluid-adaptor:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Application/Neos.Behat require --no-update "neos/flow:~${BRANCH}.0"

commit_manifest_update ${BRANCH} "${BUILD_URL}" ${EXACT_VERSION_OR_MINOR} "Packages/Application/Neos.Behat"
commit_manifest_update ${BRANCH} "${BUILD_URL}" ${EXACT_VERSION_OR_MINOR} "Packages/Application/Neos.Welcome"
