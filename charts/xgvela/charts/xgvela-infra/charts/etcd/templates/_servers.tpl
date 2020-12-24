{{- define "etcdendpoints" -}}
{{- $count := .count -}}
{{- $servers := list -}}
{{- range $index := int $count | until -}}
{{- $servers = print ("etcd-") ($index|toString) ("=http://etcd-") ($index|toString) ("._{HOST_DOMAIN_COMMAND}:2380") | append $servers -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}
