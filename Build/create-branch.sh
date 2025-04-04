#!/bin/bash -xe

#
# Create a new branch for the distribution and the development collection
#
# Expects the following environment variables:
#
# SOURCE_BRANCH    the branch that will be used as source
# BRANCH           the branch that will be created
# BUILD_URL        used in commit message
#

set -e

if [ -z "${SOURCE_BRANCH}" ]; then
  echo "\$SOURCE_BRANCH not set"
  exit 1
fi
if [ -z "${BRANCH}" ]; then
  echo "\$BRANCH not set"
  exit 1
fi
if [ -z "$BUILD_URL" ]; then
  echo "\$BUILD_URL not set"
  exit 1
fi

if [ ! -e "composer.phar" ]; then
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
  then
      echo 'ERROR: Invalid installer checksum'
      rm composer-setup.php
      exit 1
  fi

  php composer-setup.php
  rm composer-setup.php
fi

php ./composer.phar -v update

source "$(dirname "${BASH_SOURCE[0]}")/BuildEssentials/ReleaseHelpers.sh"

# start with Base Distribution
rm -rf Distribution
git clone git@github.com:neos/flow-base-distribution.git Distribution

# branch distribution
cd Distribution && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Distribution"

# branch BuildEssentials
cd Build/BuildEssentials && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Build/BuildEssentials"

# branch development collection
cd Packages/Framework && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Packages/Framework"

# branch welcome package
cd Packages/Application/Neos.Welcome && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Packages/Application/Neos.Welcome"

# branch behat package
cd Packages/Application/Neos.Behat && git fetch origin && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Packages/Application/Neos.Behat"

"$(dirname "${BASH_SOURCE[0]}")/set-dependencies.sh" "${BRANCH}.x-dev" "${BRANCH}" "${BUILD_URL}" || exit 1

push_branch "${BRANCH}" "Distribution"
push_branch "${BRANCH}" "Build/BuildEssentials"
push_branch "${BRANCH}" "Packages/Framework"
push_branch "${BRANCH}" "Packages/Application/Neos.Welcome"
push_branch "${BRANCH}" "Packages/Application/Neos.Behat"

# same procedure again with the Development Distribution

rm -rf Distribution
git clone git@github.com:neos/flow-development-distribution.git Distribution

# branch distribution
cd Distribution && git checkout -b "${BRANCH}" "origin/${SOURCE_BRANCH}"
cd -
push_branch "${BRANCH}" "Distribution"

# special case for the Development Distribution
php ./composer.phar --working-dir=Distribution require --no-update "neos/flow-development-collection:${BRANCH}.x-dev"
"$(dirname "${BASH_SOURCE[0]}")/set-dependencies.sh" "${BRANCH}.x-dev" "${BRANCH}" "${BUILD_URL}" || exit 1

push_branch "${BRANCH}" "Distribution"
