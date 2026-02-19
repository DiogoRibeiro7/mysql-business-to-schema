{{/*
Expand the name of the chart.
*/}}
{{- define "mysql-business-schema.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mysql-business-schema.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mysql-business-schema.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysql-business-schema.labels" -}}
helm.sh/chart: {{ include "mysql-business-schema.chart" . }}
{{ include "mysql-business-schema.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mysql-business-schema.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql-business-schema.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mysql-business-schema.serviceAccountName" -}}
{{- if .Values.rbac.serviceAccount.create }}
{{- default (include "mysql-business-schema.fullname" .) .Values.rbac.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.rbac.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the MySQL image
*/}}
{{- define "mysql-business-schema.mysqlImage" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag }}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag }}
{{- end }}
{{- end }}

{{/*
Return the proper Storage Class
*/}}
{{- define "mysql-business-schema.storageClass" -}}
{{- $storageClass := .Values.persistence.storageClass -}}
{{- if $storageClass -}}
{{- if (eq "-" $storageClass) -}}
{{- printf "storageClassName: \"\"" -}}
{{- else }}
{{- printf "storageClassName: %s" $storageClass -}}
{{- end -}}
{{- else if .Values.global.storageClass -}}
{{- printf "storageClassName: %s" .Values.global.storageClass -}}
{{- end -}}
{{- end }}

{{/*
Return namespace
*/}}
{{- define "mysql-business-schema.namespace" -}}
{{- if .Values.global.namespace -}}
{{- .Values.global.namespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end }}

{{/*
Return monitoring namespace
*/}}
{{- define "mysql-business-schema.monitoringNamespace" -}}
{{- if .Values.monitoring.namespace -}}
{{- .Values.monitoring.namespace -}}
{{- else -}}
{{- include "mysql-business-schema.namespace" . -}}
{{- end -}}
{{- end }}

{{/*
Return true if cert-manager is enabled
*/}}
{{- define "mysql-business-schema.certManager.enabled" -}}
{{- if .Values.ingress.tls }}
{{- if .Values.ingress.certManager }}
{{- .Values.ingress.certManager.enabled -}}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for ingress
*/}}
{{- define "mysql-business-schema.ingress.apiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.Version -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.Version -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}

{{/*
Return true if ingress is enabled
*/}}
{{- define "mysql-business-schema.ingress.enabled" -}}
{{- or .Values.webDemo.ingress.enabled .Values.monitoring.grafana.ingress.enabled -}}
{{- end -}}

{{/*
Get the password secret
*/}}
{{- define "mysql-business-schema.secretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- printf "%s" .Values.auth.existingSecret -}}
{{- else -}}
{{- printf "%s" (include "mysql-business-schema.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if we should create RBAC resources
*/}}
{{- define "mysql-business-schema.createRBAC" -}}
{{- if .Values.rbac.create -}}
true
{{- end -}}
{{- end -}}

{{/*
Return podAnnotations
*/}}
{{- define "mysql-business-schema.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{- toYaml .Values.podAnnotations }}
{{- end }}
{{- end -}}

{{/*
Compile all warnings into a single message
*/}}
{{- define "mysql-business-schema.validateValues" -}}
{{- $messages := list -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{- printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}