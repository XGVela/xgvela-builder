#helm3 commands
$KUBECTL_BIN --kubeconfig $KUBE_CONFIG create ns xgvela
/root/cdm-r4/cdm/pkg-manager/bin/linux/helm-v3 --kubeconfig $KUBE_CONFIG install xgvela --namespace xgvela ~/xgvela-0.1-xgvela.tgz -f ~/xgvela_small.yaml
/root/cdm-r4/cdm/pkg-manager/bin/linux/helm-v3 --kubeconfig $KUBE_CONFIG uninstall xgvela --namespace xgvela
$KUBECTL_BIN --kubeconfig $KUBE_CONFIG delete ns xgvela
