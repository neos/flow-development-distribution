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

source $(dirname ${BASH_SOURCE[0]})/BuildEssentials/ReleaseHelpers.sh

COMPOSER_PHAR="$(dirname ${BASH_SOURCE[0]})/../composer.phar"
if [ ! -f ${COMPOSER_PHAR} ]; then
    echo >&2 "No composer.phar, expected it at ${COMPOSER_PHAR}"
    exit 1
fi

if [ -z "$1" ] ; then
    echo >&2 "No version specified (e.g. 2.1.*) as first parameter."
    exit 1
else
    if [[ $1 =~ (dev)-.+ || $1 =~ .+(@dev|.x-dev) || $1 =~ (alpha|beta|RC|rc)[0-9]+ ]] ; then
        VERSION=$1
        STABILITY_FLAG=${BASH_REMATCH[1]}
    else
        if [[ $1 =~ ([0-9]+\.[0-9]+)\.[0-9] ]] ; then
            VERSION=~${BASH_REMATCH[1]}.0
        else
            echo >&2 "Version $1 could not be parsed."
            exit 1
        fi
    fi
fi

if [ -z "$2" ] ; then
    echo >&2 "No branch specified (e.g. 2.1) as second parameter."
    exit 1
fi
BRANCH=$2

if [ -z "$3" ] ; then
    echo >&2 "No build URL specified as third parameter."
    exit 1
fi
BUILD_URL="$3"

if [ ! -d "Distribution" ]; then echo '"Distribution" folder not found. Clone the base distribution into "Distribution"'; exit 1; fi

echo "Setting distribution dependencies"

# Require exact versions of the main packages
php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/flow:${VERSION}"
php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/welcome:${VERSION}"

# Require exact versions of sub dependency packages, allowing unstable
if [[ ${STABILITY_FLAG} ]] ; then
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/cache:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/eel:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/error-messages:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/flow-log:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-arrays:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-files:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-mediatypes:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-objecthandling:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-opcodecache:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-pdo:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-schema:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/utility-unicode:${VERSION}"
    php "${COMPOSER_PHAR}" --working-dir=Distribution require --no-update "neos/http-factories:${VERSION}"
# Remove dependencies not needed if releasing a stable version
else
    # Remove requirements for development version of sub dependency packages
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/cache"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/eel"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/error-messages"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/flow-log"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/fluid-adaptor"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-arrays"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-files"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-mediatypes"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-objecthandling"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-opcodecache"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-pdo"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-schema"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/utility-unicode"
    php "${COMPOSER_PHAR}" --working-dir=Distribution remove --no-update "neos/http-factories"
fi

php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/kickstarter:${VERSION}"
php "${COMPOSER_PHAR}" --working-dir=Distribution require --dev --no-update "neos/buildessentials:${VERSION}"

commit_manifest_update ${BRANCH} "${BUILD_URL}" ${VERSION} "Distribution"

echo "Setting packages dependencies"

php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/cache:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/eel:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/error-messages:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/flow-log:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-arrays:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-files:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-mediatypes:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-objecthandling:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-opcodecache:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-pdo:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-schema:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/utility-unicode:~${BRANCH}.0"
php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Flow require --no-update "neos/http-factories:~${BRANCH}.0"

for PACKAGE in Neos.Eel Neos.FluidAdaptor Neos.Kickstarter ; do
    php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/${PACKAGE} require --no-update "neos/flow:~${BRANCH}.0"
done

php "${COMPOSER_PHAR}" --working-dir=Packages/Framework/Neos.Kickstarter require --no-update "neos/fluid-adaptor:~${BRANCH}.0"

commit_manifest_update ${BRANCH} "${BUILD_URL}" ${VERSION} "Packages/Framework"
