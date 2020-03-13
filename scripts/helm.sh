#!/bin/bash
# All HELM related common logic should be kept here

function _set_variables() {

  ## internal func: Sets variables needed for running helm pacakge

  echo "Intialising variables needed for HELM Publish"

  APP_NAME=$(echo $TRAVIS_REPO_SLUG | cut -d"/" -f2)

  if [[ -z "$TRAVIS_TAG" ]]; then
      VERSION=$(date +%y.%m.%d)-${TRAVIS_COMMIT}
      APP_VERSION=${TRAVIS_COMMIT}
  else
    VERSION=${TRAVIS_TAG}
    APP_VERSION=${TRAVIS_TAG}
  fi

}

function _validate_variables() {

  ## internal func: Validates all required variables exist

  echo "Validating input variables needed for HELM Publish"

  if [ -z "$ARTIFACTORY_URL" ]; then
    echo "Error: Must provide ARTIFACTORY_URL"
    exit 1
  fi

  # Thorws error if TRAVIS_REPO_SLUG not provided
  # Expected format: "quid/APP_NAME" eg: "quid/quid_datadog"
  if [ -z "$TRAVIS_REPO_SLUG" ]; then
    echo "Error: Must provide TRAVIS_REPO_SLUG"
    exit 1
  fi

  # Thorws error if TRAVIS_TAG as well as TRAVIS_COMMIT is not present
  if [[ -z "$TRAVIS_TAG" ]]; then
    if [[ -z "$TRAVIS_COMMIT" ]]; then
      echo "Error: One of TRAVIS_COMMIT OR TRAVIS_TAG must be present"
      exit 1
    fi
  fi

  # Thorws error if ARTIFACTORY_USERNAME not provided
  if [ -z "$ARTIFACTORY_USERNAME" ]; then
    echo "Error: Must provide ARTIFACTORY_USERNAME"
    exit 1
  fi

  # Thorws error if ARTIFACTORY_PASSWORD not provided
  if [ -z "$ARTIFACTORY_PASSWORD" ]; then
    echo "Error: Must provide ARTIFACTORY_PASSWORD"
    exit 1
  fi
}

function publish () {

  ## Create helm package and publish it to Artifactory
  ## Usage: curl -O https://raw.githubusercontent.com/quid/public/introudction-to-helm/scripts/helm.sh; source helm.sh; publish

  _validate_variables # interal func: Validates all required variables exist
  _set_variables # internal func: Sets variables needed for running helm pacakge

  echo "Packaging Helm for APP: ${APP_NAME}, VERSION: ${VERSION}, APP_VERSION: ${APP_VERSION}"

  helm package --version=${VERSION} --app-version=${APP_VERSION} chart/${APP_NAME}
	curl -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} -T ${APP_NAME}-${VERSION}.tgz "https://${ARTIFACTORY_URL}/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/${APP_VERSION}.tgz"
	cd chart/${APP_NAME} && \
	for d in values*; do { curl -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} -T $d "https://${ARTIFACTORY_URL}/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/$d"; } done
}
