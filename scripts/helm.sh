#!/bin/bash
# All HELM related common logic should be kept here

function _set_variables() {

  ## internal func: Sets variables needed for running helm pacakge

  APP_NAME = $(echo $TRAVIS_REPO_SLUG | cut -d"/" -f2)

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

  # Thorws error if TRAVIS_REPO_SLUG not provided
  # Expected format: "quid/APP_NAME" eg: "quid/quid_datadog"
  if [ -z "$TRAVIS_REPO_SLUG" ]; then
    echo "Error: Must provide TRAVIS_REPO_SLUG"
    exit 1
  fi

  if [[ -z "$TRAVIS_TAG" ]]; then
    if [[ -z "$TRAVIS_COMMIT" ]]; then
      echo "Error: One of TRAVIS_COMMIT OR TRAVIS_TAG must be present"
      exit 1
    fi
  fi

  # Thorws error if DOCKER_USERNAME not provided
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "Error: Must provide DOCKER_USERNAME"
    exit 1
  fi

  # Thorws error if DOCKER_PASSWORD not provided
  if [ -z "$DOCKER_PASSWORD" ]; then
    echo "Error: Must provide DOCKER_PASSWORD"
    exit 1
  fi
}

function publish () {

  ## Create helm package and publish it to Artifactory
  ## Usage: curl -O https://raw.githubusercontent.com/quid/public/introudction-to-helm/scripts/helm.sh; source helm.sh; publish

  _validate_variables # interal func: Validates all required variables exist
  _set_variables # internal func: Sets variables needed for running helm pacakge

  echo "Packaging Helm for APP: ${APP_NAME}, VERSION: ${VERSION}, APP_VERSION: ${APP_VERSION}"

  helm package --version=$(VERSION) --app-version=$(APP_VERSION) chart/${APP_NAME}
	curl -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} -T ${APP_NAME}-$(VERSION).tgz "https://nexus.quid.com/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/${APP_VERSION}.tgz"
	cd chart/${APP_NAME} && \
	for d in values*; do { curl -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} -T $d "https://nexus.quid.com/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/$d"; } done
}
