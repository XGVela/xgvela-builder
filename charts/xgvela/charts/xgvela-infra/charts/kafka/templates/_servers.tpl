{{- define "kafkazkconnectendpoints" -}}
{{- $count := .count -}}
{{- $namespace := .namespace -}}
{{- $servers := list -}}
{{- range $index := int $count | until -}}
{{- $servers = print ("zk-") ($index|toString) (".zk.") ($namespace) (".svc.cluster.local:2181") | append $servers -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}
