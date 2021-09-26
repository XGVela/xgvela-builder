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
XGVela_ARTIFACTS=./artifacts
XGVela_IMAGES=$XGVela_ARTIFACTS/images
XGVela_CHARTS=$XGVela_ARTIFACTS/charts
XGVela_TEMPLATES=$XGVela_ARTIFACTS/templates
XGVela_CONFIGS=$XGVela_ARTIFACTS/configs

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
    WORKDIR=$1
    MODULE=$2
    ARGS=$3
    info "Building Repo: $MODULE $ARGS"
    cd $WORKDIR
    $GIT_MCF_REPO_PREFIX/$MODULE.git
    cd $WORKDIR/$MODULE
    git checkout $RELEASE_BRANCH
    if [[ "$MODULE" == "cmaas" ]]; then
        cp ../../confd-target.tgz build/cmaas-base/
    fi
    ./buildall.sh $ARGS
}

prepare_xgvela_release_env() {
    WORKDIR=$1
    info "Preparing XGVela Release Environment"
    cd $WORKDIR
    rm -rf $XGVela_ARTIFACTS
    mkdir -p $XGVela_ARTIFACTS
    mkdir -p $XGVela_IMAGES
    mkdir -p $XGVela_TEMPLATES
    mkdir -p $XGVela_CONFIGS
    mkdir -p $XGVela_CHARTS
    cp -rf ../charts/xgvela $XGVela_CHARTS/
    cp -rf ../images/* $XGVela_IMAGES
    mkdir -p $XGVela_CHARTS/xgvela/charts/xgvela-mgmt/charts/
    sed -i -e "s/cnf_mgmt_tag/$CNF_MGMT_VERSION/" $XGVela_CHARTS/xgvela/Chart.yaml
}

generate_xgvela_artifacts() {
    WORKDIR=$1
    MODULE=$2
    info "Generating XGVela Artifacts for $MODULE"
    cd $WORKDIR
    [ -d $MODULE/artifacts/template/ ] && cp -rf $MODULE/artifacts/template/* $XGVela_TEMPLATES/ || echo "Ignoring template"
    [ -d $MODULE/artifacts/images/ ] && cp -rf $MODULE/artifacts/images/* $XGVela_IMAGES/ || echo "Ignoring images"
    [ -d $MODULE/artifacts/config/ ] && cp -rf $MODULE/artifacts/config/* $XGVela_CONFIGS/ || echo "Ignoring config"
    [ -d $MODULE/artifacts/charts/ ] && cp -rf $MODULE/artifacts/charts/* $XGVela_CHARTS/xgvela/charts/xgvela-mgmt/charts/ || echo "Ignoring charts"
}

package_xgvela_chart() {
    WORKDIR=$1
    info "Packaging XGVela chart"
    cd $XGVela_CHARTS
    tar -czf "xgvela-$CNF_MGMT_VERSION.tgz" xgvela
    cp "xgvela-$CNF_MGMT_VERSION.tgz" ../
    cd $WORKDIR/artifacts
    tar -czf "xgvela-$CNF_MGMT_VERSION-sdk.tgz" configs templates
    md5sum images/* >>md5sum.info
    md5sum *.tgz >>md5sum.info
    rm -rf charts configs templates
}

clean_intermediate_artifacts() {
    WORKDIR=$1
    MODULE=$2
    info "Deleting intermediate artifacts: $MODULE"
    cd $WORKDIR
    rm -rf $WORKDIR/$MODULE
}

clean() {
    rm -rf b build/*
}

build() {
    info "Starting XGVela Build..."
    build_mcf_repo $CUR_WORKDIR cim "$CIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR cmaas "$CMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR fmaas "$FMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR vesgw "$VESGW_IMAGE_VERSION $VESSIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR tmaas "$TOPOENG_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR tmaas-gw "$TOPOGW_IMAGE_VERSION $CIM_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR service-init "$SVCINIT_IMAGE_VERSION"
    build_mcf_repo $CUR_WORKDIR cnf-packaging ""

    prepare_xgvela_release_env $CUR_WORKDIR

    generate_xgvela_artifacts $CUR_WORKDIR cim
    generate_xgvela_artifacts $CUR_WORKDIR cmaas
    generate_xgvela_artifacts $CUR_WORKDIR fmaas
    generate_xgvela_artifacts $CUR_WORKDIR vesgw
    generate_xgvela_artifacts $CUR_WORKDIR tmaas
    generate_xgvela_artifacts $CUR_WORKDIR tmaas-gw
    generate_xgvela_artifacts $CUR_WORKDIR service-init
    generate_xgvela_artifacts $CUR_WORKDIR cnf-packaging

    package_xgvela_chart $CUR_WORKDIR

    clean_intermediate_artifacts $CUR_WORKDIR cim
    clean_intermediate_artifacts $CUR_WORKDIR cmaas
    clean_intermediate_artifacts $CUR_WORKDIR fmaas
    clean_intermediate_artifacts $CUR_WORKDIR vesgw
    clean_intermediate_artifacts $CUR_WORKDIR tmaas
    clean_intermediate_artifacts $CUR_WORKDIR tmaas-gw
    clean_intermediate_artifacts $CUR_WORKDIR service-init
    clean_intermediate_artifacts $CUR_WORKDIR cnf-packaging
    info "Completed XGVela Build"
}

CUR_WORKDIR=$(pwd)/build
#logsetup
clean
build