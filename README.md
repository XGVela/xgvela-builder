# xgvela-builder
Build and package xGVela Telco PaaS.


# Installation
## Prerequisites
* golang
* OpenJdk 11
* Docker
* minikube [4 vCPU, 6GB RAM, 20GB Disk]
* Internet connection for build to download necessary packages

## Build
1. Clone repo 'xgvela-builder'
1. Checkout release branch 'release/xgvela-0.1'
1. Download Tail-f ConfD 7.1 binary and copy it under 'xgvela-builder' as 'confd-target.tgz'
1. Run './buildall.sh' to build

> Build is executed under 'xgvela-builder/build/' directory
>
> Script clones each module and invokes respective 'buildall.sh' with relevant parameters
>
> After a successful build, following messages are printed on the console,
> <pre>
> [2021.09.27-03:57:44 IST] [94106] INFO   Packaging XGVela chart
> [2021.09.27-03:57:47 IST] [94106] INFO   Deleting intermediate artifacts: cim
> [2021.09.27-03:57:47 IST] [94106] INFO   Deleting intermediate artifacts: cmaas
> [2021.09.27-03:57:47 IST] [94106] INFO   Deleting intermediate artifacts: fmaas
> [2021.09.27-03:57:47 IST] [94106] INFO   Deleting intermediate artifacts: vesgw
> [2021.09.27-03:57:47 IST] [94106] INFO   Deleting intermediate artifacts: tmaas
> [2021.09.27-03:57:48 IST] [94106] INFO   Deleting intermediate artifacts: tmaas-gw
> [2021.09.27-03:57:48 IST] [94106] INFO   Deleting intermediate artifacts: service-init
> [2021.09.27-03:57:48 IST] [94106] INFO   Deleting intermediate artifacts: cnf-packaging
> [2021.09.27-03:57:48 IST] [94106] INFO   Completed XGVela Build
> </pre>
>
> Initial build might take 60+ minutes as Docker and Maven download necessary packages from internet. Subsequent builds will be shorter.
>
> Following artifacts are generated under 'xgvela-builder/build'.
> <pre>
> build
> └── artifacts
>     ├── images
>     │   ├── LICENSE_etcd-alpine
>     │   ├── LICENSE_kafka-alpine
>     │   ├── LICENSE_zk-alpine
>     │   ├── cim-v0.1.tar.gz
>     │   ├── cmaas-v0.1.tar.gz
>     │   ├── etcd-alpine-v3.3.15.tar.gz
>     │   ├── fmaas-v0.1.tar.gz
>     │   ├── kafka-alpine-v2.1.0-3.tar.gz
>     │   ├── tmaas-gw-v0.1.tar.gz
>     │   ├── tmaas-v0.1.tar.gz
>     │   ├── ves-gw-v0.1.tar.gz
>     │   ├── xgvela-svc-init-v0.1.tar.gz
>     │   └── zk-alpine-v3.4.13.tar.gz
>     ├── md5sum.info
>     ├── xgvela-0.1-sdk.tgz
>     └── xgvela-0.1.tgz
> </pre>

## Deploy
1. Ensure Docker and Minikube are running
1. Prepare deployment yaml configuration
    1. Deployment yaml provides necessary inputs and overrides for deploying an instance of XGVela.
        * 'deployment/xgvela_small_deployment_template.yaml' provides a small non-HA configuration.
        * Current code requires host path to be mounted to PODs for logs and volumes.
    1. Make a copy of 'deployment/xgvela_small_deployment_template.yaml' using appropriate name and make following edits.
    1. Replace $xgvelaId with chosen identifier.
    1. Replace $hostDataDir and $hostLogsDir with appropriate path available in k8s/minikube VM.
    1. Replece $hostId with k8s/minikube node name. Minikube creates a single node cluster. Use below command to identify the host name.
        ```
        $ kubectl get nodes
        NAME             STATUS   ROLES                  AGE   VERSION
        docker-desktop   Ready    control-plane,master   21h   v1.21.4

        Here 'docker-desktop' is the hostId.
        ```
1. Prepare the cluster
    * Set node labels intra=true and mgmt=true using below commands
        ```
        $ kubectl label nodes docker-desktop infra=true
        $ kubectl label nodes docker-desktop mgmt=true
        ```
    * Check if labels are set using below command
        ```
        $ kubectl get nodes --show-labels                        
        NAME             STATUS   ROLES                  AGE   VERSION   LABELS
          docker-desktop   Ready    control-plane,master   94m   v1.21.4   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,infra=true,kubernetes.io/arch=amd64,kubernetes.io/hostname=docker-desktop,kubernetes.io/os=linux,mgmt=true,node-role.kubernetes.io/control-plane=,node-role.kubernetes.io/master=,node.kubernetes.io/exclude-from-external-load-balancers=
        ```
1. If an image registration is not available, create one locally using below command,
    ```
    $  docker run -d -p 5000:5000 --restart=always --name registry registry:2
    ```

    ```
    Unable to find image 'registry:2' locally
    2: Pulling from library/registry
    6a428f9f83b0: Pull complete 
    90cad49de35d: Pull complete 
    b215d0b40846: Pull complete 
    429305b6c15c: Pull complete 
    6f7e10a4e907: Pull complete 
    Digest: sha256:265d4a5ed8bf0df27d1107edb00b70e658ee9aa5acb3f37336c5a17db634481e
    Status: Downloaded newer image for registry:2
    766e4a41f784cd8fe0d6d08e2dc8024cd42380cc322499b81d0adfabf905d2da
    ```
1. Deploy images
    ```
    $ ./deploy.sh images
    ```
1. Install xgvela
    ```
    $ ./deploy.sh install
    ```

## Debug
* Check status of XGVela services
    ```
    $ kubectl get po -n xgvela
    ```
* Check $hostDataDir and $hostLogsDir
    
    **Example**
    ```
    /tmp/xgvela
    └── data
        ├── config
        │   └── model
        ├── logs
        │   ├── cmaas-5bb6b8b88-8xttr_xgvela_cim-burstable.log
        │   ├── cmaas-5bb6b8b88-8xttr_xgvela_cmaas-burstable.log
        │   ├── fmaas-6f4d4bffdc-m9wzd_xgvela_cim-burstable.log
        │   ├── fmaas-6f4d4bffdc-m9wzd_xgvela_fmaas-burstable.log
        │   ├── tmaas-65575c944c-jkf2x_xgvela_cim-burstable.log
        │   ├── tmaas-65575c944c-jkf2x_xgvela_tmaas-burstable.log
        │   ├── tmaas-gw-b994bf445-t5ktb_xgvela_cim-burstable.log
        │   ├── tmaas-gw-b994bf445-t5ktb_xgvela_tmaas-gw-burstable.log
        │   ├── vesgw-0_xgvela_cim-burstable.log
        │   └── vesgw-0_xgvela_vesgw-.log
        └── xgvela-volumes
            ├── etcd-pv
            │   └── vol-0
            │       └── etcd-0
            │           └── member
            │               ├── snap
            │               └── wal
            ├── kafka-pv
            │   └── vol-0
            │       └── kafka-logs-kafka-0
            └── zk-pv
                └── vol-0
                    ├── myid
                    └── version-2
                        └── log.1
    ```