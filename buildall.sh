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

CNF_MGMT_VERSION="0.1-xgvela"

CIM_IMAGE_VERSION="v0.1-xgvela"
CMAAS_IMAGE_VERSION="v0.1-xgvela"
FMAAS_IMAGE_VERSION="v0.1-xgvela"
VESGW_IMAGE_VERSION="v0.1-xgvela"
VESSIM_IMAGE_VERSION="v0.1-xgvela"
TOPOENG_IMAGE_VERSION="v0.1-xgvela"
TOPOGW_IMAGE_VERSION="v0.1-xgvela"
SVCINIT_IMAGE_VERSION="v0.1-xgvela"


GIT_MCF_REPO_PREFIX="git clone ssh://git@bbmirror-us-rch.mavenir.com:7999/at/mcf"

#######
XGVela_ARTIFACTS=./artifacts
XGVela_IMAGES=$XGVela_ARTIFACTS/images
XGVela_CHARTS=$XGVela_ARTIFACTS/charts
XGVela_TEMPLATES=$XGVela_ARTIFACTS/templates
XGVela_CONFIGS=$XGVela_ARTIFACTS/configs

build_mcf_repo() {
WORKDIR=$1
MODULE=$2
ARGS=$3
echo -e "\e[1;32;40m[XGVela-BUILD] Building Repo: $MODULE $ARGS \e[0m"
cd $WORKDIR
$GIT_MCF_REPO_PREFIX/$MODULE.git
cd $WORKDIR/$MODULE
git checkout feature/xgvela 
./buildall.sh $ARGS
}

prepare_xgvela_release_env() {
WORKDIR=$1
echo -e "\e[1;32;40m[XGVela-BUILD] Preparing XGVela Release Environment\e[0m"
cd $WORKDIR
rm -rf $XGVela_ARTIFACTS
mkdir -p $XGVela_ARTIFACTS
mkdir -p $XGVela_IMAGES 
mkdir -p $XGVela_TEMPLATES 
mkdir -p $XGVela_CONFIGS
mkdir -p $XGVela_CHARTS 
cp -rf charts/xgvela $XGVela_CHARTS/
cp -rf images/* $XGVela_IMAGES
mkdir -p $XGVela_CHARTS/xgvela/charts/xgvela-mgmt/charts/
sed -i "s/cnf_mgmt_tag/$CNF_MGMT_VERSION/" $XGVela_CHARTS/xgvela/Chart.yaml
}

generate_xgvela_artifacts() {
WORKDIR=$1
MODULE=$2
echo -e "\e[1;32;40m[XGVela-BUILD] Generating XGVela Artifacts for $MODULE\e[0m"
cd $WORKDIR
[ -d $MODULE/artifacts/template/ ] && cp -rf $MODULE/artifacts/template/* $XGVela_TEMPLATES/ || echo "Ignoring template"
[ -d $MODULE/artifacts/images/ ] && cp -rf $MODULE/artifacts/images/* $XGVela_IMAGES/ || echo "Ignoring images"
[ -d $MODULE/artifacts/config/ ] && cp -rf $MODULE/artifacts/config/* $XGVela_CONFIGS/ || echo "Ignoring config"
[ -d $MODULE/artifacts/charts/ ] && cp -rf $MODULE/artifacts/charts/* $XGVela_CHARTS/xgvela/charts/xgvela-mgmt/charts/ || echo "Ignoring charts"
}

package_xgvela_chart() {
WORKDIR=$1
echo -e "\e[1;32;40m[XGVela-BUILD] Packaging XGVela chart\e[0m"
cd $XGVela_CHARTS
tar -czf "xgvela-$CNF_MGMT_VERSION.tgz" xgvela
cp "xgvela-$CNF_MGMT_VERSION.tgz" ../
cd $WORKDIR/artifacts
tar -czf "xgvela-$CNF_MGMT_VERSION-sdk.tgz" configs templates
md5sum images/* >> md5sum.info
md5sum *.tgz >> md5sum.info
rm -rf charts configs templates
}


clean_intermediate_artifacts() {
WORKDIR=$1
MODULE=$2
echo -e "\e[1;32;40m[XGVela-BUILD] Deleting intermediate artifacts: $MODULE \e[0m"
cd $WORKDIR
rm -rf $WORKDIR/$MODULE
}

CUR_WORKDIR=$(pwd)

build_mcf_repo $CUR_WORKDIR cim   "$CIM_IMAGE_VERSION" 
build_mcf_repo $CUR_WORKDIR cfgs  "$CMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR fmaas "$FMAAS_IMAGE_VERSION $CIM_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR vesgw "$VESGW_IMAGE_VERSION $VESSIM_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR tmaas_topo-engine "$TOPOENG_IMAGE_VERSION $CIM_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR tmaas_topo-gw "$TOPOGW_IMAGE_VERSION $CIM_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR mtcil-svc-init "$SVCINIT_IMAGE_VERSION"
build_mcf_repo $CUR_WORKDIR cnf-packaging ""

prepare_xgvela_release_env $CUR_WORKDIR

generate_xgvela_artifacts $CUR_WORKDIR cim
generate_xgvela_artifacts $CUR_WORKDIR cfgs
generate_xgvela_artifacts $CUR_WORKDIR fmaas
generate_xgvela_artifacts $CUR_WORKDIR vesgw
generate_xgvela_artifacts $CUR_WORKDIR tmaas_topo-engine 
generate_xgvela_artifacts $CUR_WORKDIR tmaas_topo-gw
generate_xgvela_artifacts $CUR_WORKDIR mtcil-svc-init
generate_xgvela_artifacts $CUR_WORKDIR cnf-packaging

package_xgvela_chart $CUR_WORKDIR

clean_intermediate_artifacts $CUR_WORKDIR cim
clean_intermediate_artifacts $CUR_WORKDIR cfgs
clean_intermediate_artifacts $CUR_WORKDIR fmaas
clean_intermediate_artifacts $CUR_WORKDIR vesgw
clean_intermediate_artifacts $CUR_WORKDIR tmaas_topo-engine 
clean_intermediate_artifacts $CUR_WORKDIR tmaas_topo-gw
clean_intermediate_artifacts $CUR_WORKDIR mtcil-svc-init
clean_intermediate_artifacts $CUR_WORKDIR cnf-packaging

