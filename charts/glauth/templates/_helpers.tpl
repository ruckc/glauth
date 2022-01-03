{{/*
Expand the name of the chart.
*/}}
{{- define "glauth.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart name prefix for resource names
Strip the "-controller" suffix from the default .Chart.Name if the nameOverride is not specified.
This enables using a shorter name for the resources, for example aws-load-balancer-webhook.
*/}}
{{- define "glauth.namePrefix" -}}
{{- $defaultNamePrefix := .Chart.Name -}}
{{- default $defaultNamePrefix .Values.nameOverride | trunc 42 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "glauth.fullname" -}}
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
{{- define "glauth.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "glauth.labels" -}}
helm.sh/chart: {{ include "glauth.chart" . }}
{{ include "glauth.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "glauth.selectorLabels" -}}
app.kubernetes.io/name: {{ include "glauth.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "glauth.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "glauth.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate certificates for api
*/}}
{{- define "glauth.api-certs" -}}
{{- $namePrefix := ( include "glauth.namePrefix" . ) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (printf "%s-api-tls" $namePrefix) -}}
{{- if and .Values.tls.keep $secret -}}
caCert: {{ index $secret.data "ca.crt" }}
clientCert: {{ index $secret.data "tls.crt" }}
clientKey: {{ index $secret.data "tls.key" }}
{{- else -}}
{{- $altNames := list ( printf "%s-%s.%s" $namePrefix "api" .Release.Namespace ) ( printf "%s-%s.%s.svc" $namePrefix "api" .Release.Namespace ) -}}
{{- $ca := genCA "glauth-api-ca" 3650 -}}
{{- $cert := genSignedCert ( include "glauth.fullname" . ) nil $altNames 3650 $ca -}}
caCert: {{ $ca.Cert | b64enc }}
clientCert: {{ $cert.Cert | b64enc }}
clientKey: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}

{{/*
Generate certificates for ldaps
*/}}
{{- define "glauth.ldaps-certs" -}}
{{- $namePrefix := ( include "glauth.namePrefix" . ) -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace (printf "%s-ldaps-tls" $namePrefix) -}}
{{- if and .Values.tls.keep $secret -}}
caCert: {{ index $secret.data "ca.crt" }}
clientCert: {{ index $secret.data "tls.crt" }}
clientKey: {{ index $secret.data "tls.key" }}
{{- else -}}
{{- $altNames := list ( printf "%s-%s.%s" $namePrefix "ldaps" .Release.Namespace ) ( printf "%s-%s.%s.svc" $namePrefix "ldaps" .Release.Namespace ) -}}
{{- $ca := genCA "glauth-ldaps-ca" 3650 -}}
{{- $cert := genSignedCert ( include "glauth.fullname" . ) nil $altNames 3650 $ca -}}
caCert: {{ $ca.Cert | b64enc }}
clientCert: {{ $cert.Cert | b64enc }}
clientKey: {{ $cert.Key | b64enc }}
{{- end -}}
{{- end -}}