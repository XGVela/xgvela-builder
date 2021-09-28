#!/bin/bash
# Copyright 2020 Mavenir
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

CNF_MGMT_VERSION="0.1"

CIM_IMAGE_VERSION="v0.1"
CMAAS_IMAGE_VERSION="v0.1"
FMAAS_IMAGE_VERSION="v0.1"
VESGW_IMAGE_VERSION="v0.1"
VESSIM_IMAGE_VERSION="v0.1"
TOPOENG_IMAGE_VERSION="v0.1"
TOPOGW_IMAGE_VERSION="v0.1"
SVCINIT_IMAGE_VERSION="v0.1"

GIT_MCF_REPO_PREFIX="git clone https://github.com/XGVela"
RELEASE_BRANCH=`git rev-parse --abbrev-ref HEAD`

#######
BUILD_DIR=$(pwd)/build
ARTIFACTS_DIR=./artifacts
IMAGES_DIR=$ARTIFACTS_DIR/images
CHARTS_DIR=$ARTIFACTS_DIR/charts
TEMPLATES_DIR=$ARTIFACTS_DIR/templates
CONFIGS_DIR=$ARTIFACTS_DIR/configs

DEBUG=1
LOGFILE="xgvela-build-"$(date +"%Y%m%d").log
RETAIN_NUM_LINES=10

log() {
    type_of_msg=$(echo $* | cut -d" " -f1)
    msg=$(echo "$*" | cut -d" " -f2-)
    if [[ "$type_of_msg" == "DEBUG" || "$type_of_msg" == "INFO" || "$type_of_msg" == "WARN" ]]; then
        [[ $type_of_msg == DEBUG ]] && [[ $DEBUG -ne 1 ]] && return
        [[ $type_of_msg == INFO ]] && type_of_msg="INFO " # one space for aligning
        [[ $type_of_msg == WARN ]] && type_of_msg="WARN " # as well
    else
        msg="$type_of_msg $msg"
        type_of_msg="INFO "
    fi

    echo "[$(date "+%Y.%m.%d-%H:%M:%S %Z")] [$$] $type_of_msg $msg"
}

logsetup() {
    #TMP=$(tail -n $RETAIN_NUM_LINES $LOGFILE 2>/dev/null) && echo "${TMP}"
    exec > >(tee -ia $LOGFILE)
    exec 2> >(tee -ia $LOGFILE)
}

info() {
    log "INFO  $*"
}

warn() {
    log "WARN  $*"
}

error() {
    log "ERROR $*"
}

debug() {
    log "DEBUG $*"
}

build_mcf_repo() {
    MODULE=$1
    ARGS=$2
    info "Building Repo: $MODULE $ARGS"
    cd $BUILD_DIR
    $GIT_MCF_REPO_PREFIX/$MODULE.git
    cd $BUILD_DIR/$MODULE
    git checkout $RELEASE_BRANCH
    if [[ "$MODULE" == "cmaas" ]]; then
        cp ../../confd-target.tgz build/cmaas-base/
    fi
    ./buildall.sh $ARGS
}

prepare_xgvela_release_env() {
    info "Preparing XGVela Release Environment"
    cd $BUILD_DIR
    rm -rf $ARTIFACTS_DIR
    mkdir -p $ARTIFACTS_DIR
    mkdir -p $IMAGES_DIR
    mkdir -p $TEMPLATES_DIR
    mkdir -p $CONFIGS_DIR
    mkdir -p $CHARTS_DIR
    cp -rf ../charts/xgvela $CHARTS_DIR/
    cp -rf ../images/* $IMAGES_DIR
    mkdir -p $CHARTS_DIR/xgvela/charts/xgvela-mgmt/charts/
    sed -i -e "s/cnf_mgmt_tag/$CNF_MGMT_VERSION/" $CHARTS_DIR/xgvela/Chart.yaml
}

generate_xgvela_artifacts() {
    MODULE=$1
    info "Generating XGVela Artifacts for $MODULE"
    cd $BUILD_DIR
    [ -d $MODULE/artifacts/template/ ] && cp -rf $MODULE/artifacts/template/* $TEMPLATES_DIR/ || echo "Ignoring template"
    [ -d $MODULE/artifacts/images/ ] && cp -rf $MODULE/artifacts/images/* $IMAGES_DIR/ || echo "Ignoring images"
    [ -d $MODULE/artifacts/config/ ] && cp -rf $MODULE/artifacts/config/* $CONFIGS_DIR/ || echo "Ignoring config"
    [ -d $MODULE/artifacts/charts/ ] && cp -rf $MODULE/artifacts/charts/* $CHARTS_DIR/xgvela/charts/xgvela-mgmt/charts/ || echo "Ignoring charts"
}

package_xgvela_chart() {
    info "Packaging XGVela chart"
    cd $CHARTS_DIR
    tar -czf "xgvela-$CNF_MGMT_VERSION.tgz" xgvela
    cp "xgvela-$CNF_MGMT_VERSION.tgz" ../
    cd $BUILD_DIR/artifacts
    tar -czf "xgvela-$CNF_MGMT_VERSION-sdk.tgz" configs templates
    md5sum images/* >>md5sum.info
    md5sum *.tgz >>md5sum.info
    rm -rf charts configs templates
}

clean_intermediate_artifacts() {
    MODULE=$1
    info "Deleting intermediate artifacts: $MODULE"
    rm -rf $BUILD_DIR/$MODULE
}

clean() {
    rm -rf $BUILD_DIR/*
    mkdir -p $BUILD_DIR
}

build() {
    info "Starting XGVela Build..."
    build_mcf_repo cim "$CIM_IMAGE_VERSION"
    build_mcf_repo cmaas "$CMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo fmaas "$FMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo vesgw "$VESGW_IMAGE_VERSION $VESSIM_IMAGE_VERSION"
    build_mcf_repo tmaas "$TOPOENG_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo tmaas-gw "$TOPOGW_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo service-init "$SVCINIT_IMAGE_VERSION"
    build_mcf_repo cnf-packaging ""

    prepare_xgvela_release_env

    generate_xgvela_artifacts cim
    generate_xgvela_artifacts cmaas
    generate_xgvela_artifacts fmaas
    generate_xgvela_artifacts vesgw
    generate_xgvela_artifacts tmaas
    generate_xgvela_artifacts tmaas-gw
    generate_xgvela_artifacts service-init
    generate_xgvela_artifacts cnf-packaging

    package_xgvela_chart

    clean_intermediate_artifacts cim
    clean_intermediate_artifacts cmaas
    clean_intermediate_artifacts fmaas
    clean_intermediate_artifacts vesgw
    clean_intermediate_artifacts tmaas
    clean_intermediate_artifacts tmaas-gw
    clean_intermediate_artifacts service-init
    clean_intermediate_artifacts cnf-packaging
    info "Completed XGVela Build"
}


#logsetup
clean
build