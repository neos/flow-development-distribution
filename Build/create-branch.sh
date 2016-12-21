#!/bin/bash

#
# Create a new branch for the distribution and the development collection
#
# Expects the following environment variables:
#
# BRANCH           the branch that will be created
# BUILD_URL        used in commit message
#

if [ -z "$BRANCH" ]; then echo "\$BRANCH not set"; exit 1; fi
if [ -z "$BUILD_URL" ]; then echo "\$BUILD_URL not set"; exit 1; fi

if [ ! -e "composer.phar" ]; then
    ln -s /usr/local/bin/composer.phar composer.phar
fi

composer.phar -v update

source $(dirname ${BASH_SOURCE[0]})/BuildEssentials/ReleaseHelpers.sh

rm -rf Distribution
git clone -b ${BRANCH} git@github.com:neos/flow-base-distribution.git Distribution

# branch distribution
cd Distribution && git checkout -b ${BRANCH} origin/master ; cd -

# branch development collection
cd Packages/Framework&& git checkout -b ${BRANCH} origin/master ; cd -

$(dirname ${BASH_SOURCE[0]})/set-dependencies.sh "${BRANCH}.x-dev" ${BRANCH} "${BUILD_URL}" || exit 1

push_branch ${BRANCH} "Distribution"
push_branch ${BRANCH} "Packages/Framework"
