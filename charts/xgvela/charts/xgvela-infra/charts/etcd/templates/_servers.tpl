# Copyright 2021 Mavenir
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
{{- define "etcdendpoints" -}}
{{- $count := .count -}}
{{- $servers := list -}}
{{- range $index := int $count | until -}}
{{- $servers = print ("etcd-") ($index|toString) ("=http://etcd-") ($index|toString) ("._{HOST_DOMAIN_COMMAND}:2380") | append $servers -}}
{{- end -}}
{{- (join "," $servers) -}}
{{- end -}}
