#!/bin/bash
# All HELM related common logic should be kept here

function _set_variables() {

  ## internal func: Sets variables needed for running helm pacakge

  echo "Initializing variables needed for HELM Publish"

  APP_NAME=$(ls chart)

  if [[ -z $HELM_ARTIFACTORY_DOMAIN ]]; then
    HELM_ARTIFACTORY_DOMAIN="nexus.quid.com"
  fi

  if [[ -z $HELM_ARTIFACTORY_PATH ]]; then
    HELM_ARTIFACTORY_PATH="repository/quid-helm/quid"
  fi

  VERSION=$(date +%y.%m.%d)-${TRAVIS_COMMIT}
  APP_VERSION=${TRAVIS_COMMIT}
}

function _validate_variables() {

  ## internal func: Validates all required variables exist

  echo "Validating input variables needed for HELM Publish"

  # Thorws error if TRAVIS_COMMIT is not present
  if [[ -z "$TRAVIS_COMMIT" ]]; then
    echo "Error: TRAVIS_COMMIT must be present"
    exit 1
  fi

  if [[ -z $ARTIFACTORY_USERNAME ]]; then
    ARTIFACTORY_USERNAME=$ARTIFACTORY_USER
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
  ## Usage: curl -s https://raw.githubusercontent.com/quid/public/introudction-to-helm/scripts/helm.sh | bash

  _validate_variables # interal func: Validates all required variables exist
  _set_variables # internal func: Sets variables needed for running helm pacakge

  echo "Packaging Helm for APP: ${APP_NAME}, VERSION: ${VERSION}, APP_VERSION: ${APP_VERSION}"

  yq eval -i ".global.image.tag=\"${APP_VERSION}\"" chart/${APP_NAME}/values.yaml || true

  helm dependency update chart/${APP_NAME}
  helm package --version=${VERSION} --app-version=${APP_VERSION} chart/${APP_NAME}
  echo "Uploading Charts to https://${HELM_ARTIFACTORY_DOMAIN}/${HELM_ARTIFACTORY_PATH}/${APP_NAME}/${APP_VERSION}/${APP_VERSION}.tgz"
  curl -s -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} \
    -T ${APP_NAME}-${VERSION}.tgz -w "%{http_code}" \
    "https://${HELM_ARTIFACTORY_DOMAIN}/${HELM_ARTIFACTORY_PATH}/${APP_NAME}/${APP_VERSION}/${APP_VERSION}.tgz"

  cd chart/${APP_NAME} && \
  for d in values*; do { 
    echo "Uploading Values to https://${HELM_ARTIFACTORY_DOMAIN}/${HELM_ARTIFACTORY_PATH}/${APP_NAME}/${APP_VERSION}/$d"  
    curl -s -u ${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD} \
      -T $d -w "%{http_code}" \
      "https://${HELM_ARTIFACTORY_DOMAIN}/${HELM_ARTIFACTORY_PATH}/${APP_NAME}/${APP_VERSION}/$d"; 
  } done
}

publish
