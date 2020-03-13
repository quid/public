#!/bin/bash
# All HELM related common logic should be kept here

function validate_variables() {

  # Validate needful variables, set defaults where possible

  # Thorws error if APP_NAME not provided
  if [[ -z "$APP_NAME" ]]; then
    echo "Must provide APP_NAME" 1>&2
    exit 1
  fi

  # Thorws error if IMAGE_TAG not provided
  if [[ -z "$IMAGE_TAG" ]];  then
    if [[ -z "$VERSION" ]] && [[ -z "$APP_VERSION" ]]; then
      echo "Error: One of VERION & APP_VERSION or IMAGE_TAG must be provided"
      exit 1
    fi
  else
    # default values
    VERSION=$(date +%y.%m.%d)-${IMAGE_TAG}
    APP_VERSION=${IMAGE_TAG}
  fi


  # Thorws error if IMAGE_TAG not provided
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "Must provide DOCKER_USERNAME"
    exit 1
  fi

  # Thorws error if IMAGE_TAG not provided
  if [ -z "$DOCKER_PASSWORD" ]; then
    echo "Must provide DOCKER_PASSWORD"
    exit 1
  fi

}


function publish () {

  ## Create helm package and publish it to Artifactory

  validate_variables

  echo "Packaging Helm for APP: ${APP_NAME}, VERSION: ${VERSION}, APP_VERSION: ${APP_VERSION}"

  helm package --version=$(VERSION) --app-version=$(APP_VERSION) chart/${APP_NAME}
	curl -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} -T ${APP_NAME}-$(VERSION).tgz "https://nexus.quid.com/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/${APP_VERSION}.tgz"
	cd chart/${APP_NAME} && \
	for d in values*; do { curl -u ${DOCKER_USERNAME}:${DOCKER_PASSWORD} -T $d "https://nexus.quid.com/repository/quid-helm/quid/${APP_NAME}/${APP_VERSION}/$d"; } done
}
