{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}

{{- define "kong.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.metaLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
helm.sh/chart: {{ template "kong.chart" . }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
app.kubernetes.io/managed-by: "{{ .Release.Service }}"
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{- define "kong.selectorLabels" -}}
app.kubernetes.io/name: {{ template "kong.name" . }}
app.kubernetes.io/component: app
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end -}}

{{- define "kong.postgresql.fullname" -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kong.dblessConfig.fullname" -}}
{{- $name := default "kong-custom-dbless-config" .Values.dblessConfig.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "kong.serviceAccountName" -}}
{{- if .Values.ingressController.serviceAccount.create -}}
    {{ default (include "kong.fullname" .) .Values.ingressController.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.ingressController.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the KONG_PROXY_LISTEN value string
*/}}
{{- define "kong.kongProxyListenValue" -}}

{{- if and .Values.proxy.http.enabled .Values.proxy.tls.enabled -}}
   0.0.0.0:{{ .Values.proxy.http.containerPort }},0.0.0.0:{{ .Values.proxy.tls.containerPort }} ssl
{{- else -}}
{{- if .Values.proxy.http.enabled -}}
   0.0.0.0:{{ .Values.proxy.http.containerPort }}
{{- end -}}
{{- if .Values.proxy.tls.enabled -}}
   0.0.0.0:{{ .Values.proxy.tls.containerPort }} ssl
{{- end -}}
{{- end -}}

{{- end }}

{{/*
Create the KONG_ADMIN_GUI_LISTEN value string
*/}}
{{- define "kong.kongManagerListenValue" -}}

{{- if and .Values.manager.http.enabled .Values.manager.tls.enabled -}}
   0.0.0.0:{{ .Values.manager.http.containerPort }},0.0.0.0:{{ .Values.manager.tls.containerPort }} ssl
{{- else -}}
{{- if .Values.manager.http.enabled -}}
   0.0.0.0:{{ .Values.manager.http.containerPort }}
{{- end -}}
{{- if .Values.manager.tls.enabled -}}
   0.0.0.0:{{ .Values.manager.tls.containerPort }} ssl
{{- end -}}
{{- end -}}

{{- end }}

{{/*
Create the KONG_PORTAL_GUI_LISTEN value string
*/}}
{{- define "kong.kongPortalListenValue" -}}

{{- if and .Values.portal.http.enabled .Values.portal.tls.enabled -}}
   0.0.0.0:{{ .Values.portal.http.containerPort }},0.0.0.0:{{ .Values.portal.tls.containerPort }} ssl
{{- else -}}
{{- if .Values.portal.http.enabled -}}
   0.0.0.0:{{ .Values.portal.http.containerPort }}
{{- end -}}
{{- if .Values.portal.tls.enabled -}}
   0.0.0.0:{{ .Values.portal.tls.containerPort }} ssl
{{- end -}}
{{- end -}}

{{- end }}

{{/*
Create the KONG_PORTAL_API_LISTEN value string
*/}}
{{- define "kong.kongPortalApiListenValue" -}}

{{- if and .Values.portalapi.http.enabled .Values.portalapi.tls.enabled -}}
   0.0.0.0:{{ .Values.portalapi.http.containerPort }},0.0.0.0:{{ .Values.portalapi.tls.containerPort }} ssl
{{- else -}}
{{- if .Values.portalapi.http.enabled -}}
   0.0.0.0:{{ .Values.portalapi.http.containerPort }}
{{- end -}}
{{- if .Values.portalapi.tls.enabled -}}
   0.0.0.0:{{ .Values.portalapi.tls.containerPort }} ssl
{{- end -}}
{{- end -}}

{{- end }}

{{/*
Create the ingress servicePort value string
*/}}

{{- define "kong.ingress.servicePort" -}}
{{- if .tls.enabled -}}
   {{ .tls.servicePort }}
{{- else -}}
   {{ .http.servicePort }}
{{- end -}}
{{- end -}}

{{/*
Generate an appropriate external URL from a Kong service's ingress configuration
Strips trailing slashes from the path. Manager at least does not handle these
intelligently and will append its own slash regardless, and the admin API cannot handle
the extra slash.
*/}}

{{- define "kong.ingress.serviceUrl" -}}
{{- if .tls -}}
    https://{{ .hostname }}{{ .path | trimSuffix "/" }}
{{- else -}}
    http://{{ .hostname }}{{ .path | trimSuffix "/" }}
{{- end -}}
{{- end -}}

{{/*
The name of the service used for the ingress controller's validation webhook
*/}}

{{- define "kong.service.validationWebhook" -}}
{{ include "kong.fullname" . }}-validation-webhook
{{- end -}}

{{- define "kong.ingressController.env" -}}
{{- range $key, $val := .Values.ingressController.env }}
- name: CONTROLLER_{{ $key | upper}}
{{- $valueType := printf "%T" $val -}}
{{ if eq $valueType "map[string]interface {}" }}
{{ toYaml $val | indent 2 -}}
{{- else }}
  value: {{ $val | quote -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kong.volumes" -}}
- name: {{ template "kong.fullname" . }}-prefix-dir
  emptyDir: {}
- name: {{ template "kong.fullname" . }}-tmp
  emptyDir: {}
{{- range .Values.plugins.configMaps }}
- name: kong-plugin-{{ .pluginName }}
  configMap:
    name: {{ .name }}
{{- end }}
{{- range .Values.plugins.secrets }}
- name: kong-plugin-{{ .pluginName }}
  secret:
    secretName: {{ .name }}
{{- end }}
- name: custom-nginx-template-volume
  configMap:
    name: {{ template "kong.fullname" . }}-default-custom-server-blocks
{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
- name: kong-custom-dbless-config-volume
  configMap:
    {{- if .Values.dblessConfig.configMap }}
    name: {{ .Values.dblessConfig.configMap }}
    {{- else }}
    name: {{ template "kong.dblessConfig.fullname" . }}
    {{- end }}
{{- end }}
{{- if .Values.ingressController.admissionWebhook.enabled }}
- name: webhook-cert
  secret:
    secretName: {{ template "kong.fullname" . }}-validation-webhook-keypair
{{- end }}
{{- range $secretVolume := .Values.secretVolumes }}
- name: {{ . }}
  secret:
    secretName: {{ . }}
{{- end }}
{{- end -}}

{{- define "kong.volumeMounts" -}}
- name: {{ template "kong.fullname" . }}-prefix-dir
  mountPath: /kong_prefix/
- name: {{ template "kong.fullname" . }}-tmp
  mountPath: /tmp
- name: custom-nginx-template-volume
  mountPath: /kong
{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
- name: kong-custom-dbless-config-volume
  mountPath: /kong_dbless/
{{- end }}
{{- range .Values.secretVolumes }}
- name:  {{ . }}
  mountPath: /etc/secrets/{{ . }}
{{- end }}
{{- range .Values.plugins.configMaps }}
- name:  kong-plugin-{{ .pluginName }}
  mountPath: /opt/kong/plugins/{{ .pluginName }}
  readOnly: true
{{- end }}
{{- range .Values.plugins.secrets }}
- name:  kong-plugin-{{ .pluginName }}
  mountPath: /opt/kong/plugins/{{ .pluginName }}
  readOnly: true
{{- end }}
{{- end -}}

{{- define "kong.plugins" -}}
{{ $myList := list "bundled" }}
{{- range .Values.plugins.configMaps -}}
{{- $myList = append $myList .pluginName -}}
{{- end -}}
{{- range .Values.plugins.secrets -}}
  {{ $myList = append $myList .pluginName -}}
{{- end }}
{{- $myList | join "," -}}
{{- end -}}

{{- define "kong.wait-for-db" -}}
- name: wait-for-db
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  env:
  {{- include "kong.env" . | nindent 2 }}
  command: [ "/bin/sh", "-c", "until kong start; do echo 'waiting for db'; sleep 1; done; kong stop" ]
  volumeMounts:
  {{- include "kong.volumeMounts" . | nindent 4 }}
{{- end -}}

{{- define "kong.controller-container" -}}
- name: ingress-controller
  args:
  - /kong-ingress-controller
  # Service from were we extract the IP address/es to use in Ingress status
  - --publish-service={{ .Release.Namespace }}/{{ template "kong.fullname" . }}-proxy
  # Set the ingress class
  - --ingress-class={{ .Values.ingressController.ingressClass }}
  - --election-id=kong-ingress-controller-leader-{{ .Values.ingressController.ingressClass }}
  # the kong URL points to the kong admin api server
  {{- if .Values.admin.useTLS }}
  - --kong-url=https://localhost:{{ .Values.admin.containerPort }}
  - --admin-tls-skip-verify # TODO make this configurable
  {{- else }}
  - --kong-url=http://localhost:{{ .Values.admin.containerPort }}
  {{- end }}
  {{- if .Values.ingressController.admissionWebhook.enabled }}
  - --admission-webhook-listen=0.0.0.0:{{ .Values.ingressController.admissionWebhook.port }}
  {{- end }}
  env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        apiVersion: v1
        fieldPath: metadata.namespace
{{- include "kong.ingressController.env" .  | indent 2 }}
  image: "{{ .Values.ingressController.image.repository }}:{{ .Values.ingressController.image.tag }}"
  imagePullPolicy: {{ .Values.image.pullPolicy }}
  readinessProbe:
{{ toYaml .Values.ingressController.readinessProbe | indent 4 }}
  livenessProbe:
{{ toYaml .Values.ingressController.livenessProbe | indent 4 }}
  resources:
{{ toYaml .Values.ingressController.resources | indent 4 }}
{{- if .Values.ingressController.admissionWebhook.enabled }}
  volumeMounts:
  - name: webhook-cert
    mountPath: /admission-webhook
    readOnly: true
{{- end }}
{{- end -}}

{{- define "secretkeyref" -}}
valueFrom:
  secretKeyRef:
    name: {{ .name }}
    key: {{ .key }}
{{- end -}}

{{/*
Use the Pod security context defined in Values or set the UID by default
*/}}
{{- define "kong.podsecuritycontext" -}}
{{ .Values.securityContext | toYaml }}
{{- end -}}

{{- define "kong.no_daemon_env" -}}
{{- template "kong.env" . }}
- name: KONG_NGINX_DAEMON
  value: "off"
{{- end -}}

{{/*
The environment values passed to Kong; this should come after all
the template that it itself is using form the above sections.
*/}}
{{- define "kong.env" -}}
{{/*
    ====== AUTO-GENERATED ENVIRONMENT VARIABLES ======
*/}}
{{- $autoEnv := dict -}}

{{- $_ := set $autoEnv "KONG_LUA_PACKAGE_PATH" "/opt/?.lua;;" -}}

{{- if .Values.admin.useTLS }}
  {{- $_ := set $autoEnv "KONG_ADMIN_LISTEN" (printf "0.0.0.0:%d ssl" (int64 .Values.admin.containerPort)) -}}
{{- else }}
  {{- $_ := set $autoEnv "KONG_ADMIN_LISTEN" (printf "0.0.0.0:%d" (int64 .Values.admin.containerPort)) -}}
{{- end -}}

{{- if .Values.admin.ingress.enabled }}
  {{- $_ := set $autoEnv "KONG_ADMIN_API_URI" (include "kong.ingress.serviceUrl" .Values.admin.ingress) -}}
{{- end -}}

{{- if not .Values.env.proxy_listen }}
  {{- $_ := set $autoEnv "KONG_PROXY_LISTEN" (include "kong.kongProxyListenValue" .) -}}
{{- end -}}

{{- if and (not .Values.env.admin_gui_listen) (.Values.enterprise.enabled) }}
  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_LISTEN" (include "kong.kongManagerListenValue" .) -}}
{{- end -}}

{{- if and (.Values.manager.ingress.enabled) (.Values.enterprise.enabled) }}
  {{- $_ := set $autoEnv "KONG_ADMIN_GUI_URL" (include "kong.ingress.serviceUrl" .Values.manager.ingress) -}}
{{- end -}}

{{- if and (not .Values.env.portal_gui_listen) (.Values.enterprise.enabled) (.Values.enterprise.portal.enabled) }}
  {{- $_ := set $autoEnv "KONG_PORTAL_GUI_LISTEN" (include "kong.kongPortalListenValue" .) -}}
{{- end }}

{{- if and (.Values.portal.ingress.enabled) (.Values.enterprise.enabled) (.Values.enterprise.portal.enabled) }}
  {{- $_ := set $autoEnv "KONG_PORTAL_GUI_HOST" .Values.portal.ingress.hostname -}}
  {{- if .Values.portal.ingress.tls }}
    {{- $_ := set $autoEnv "KONG_PORTAL_GUI_PROTOCOL" "https" -}}
  {{- else }}
    {{- $_ := set $autoEnv "KONG_PORTAL_GUI_PROTOCOL" "http" -}}
  {{- end }}
{{- end }}

{{- if and (not .Values.env.portal_api_listen) (.Values.enterprise.enabled) (.Values.enterprise.portal.enabled) }}
  {{- $_ := set $autoEnv "KONG_PORTAL_API_LISTEN" (include "kong.kongPortalApiListenValue" .) -}}
{{- end }}

{{- if and (.Values.portalapi.ingress.enabled) (.Values.enterprise.enabled) (.Values.enterprise.portal.enabled) }}
  {{- $_ := set $autoEnv "KONG_PORTAL_API_URL" (include "kong.ingress.serviceUrl" .Values.portalapi.ingress) -}}
{{- end }}

{{- if .Values.enterprise.enabled }}
  {{- if not .Values.enterprise.vitals.enabled }}
    {{- $_ := set $autoEnv "KONG_VITALS" "off" -}}
  {{- end }}

  {{- if .Values.enterprise.portal.enabled }}
    {{- $_ := set $autoEnv "KONG_PORTAL" "on" -}}
    {{- if .Values.enterprise.portal.portal_auth }}
      {{- $_ := set $autoEnv "KONG_PORTAL_AUTH" .Values.enterprise.portal.portal_auth -}}
      {{- $portalSession := include "secretkeyref" (dict "name" .Values.enterprise.portal.session_conf_secret "key" "portal_session_conf") -}}
      {{- $_ := set $autoEnv "KONG_PORTAL_SESSION_CONF" $portalSession -}}
    {{- end }}
  {{- end }}

  {{- if .Values.enterprise.rbac.enabled }}
    {{- $_ := set $autoEnv "KONG_ENFORCE_RBAC" "on" -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH" .Values.enterprise.rbac.admin_gui_auth | default "basic-auth" -}}

    {{- if not (eq .Values.enterprise.rbac.admin_gui_auth "basic-auth") }}
      {{- $guiAuthConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.admin_gui_auth_conf_secret "key" "admin_gui_auth_conf") -}}
      {{- $_ := set $autoEnv "KONG_ADMIN_GUI_AUTH_CONF" $guiAuthConf -}}
    {{- end }}

    {{- $guiSessionConf := include "secretkeyref" (dict "name" .Values.enterprise.rbac.session_conf_secret "key" "admin_gui_session_conf") -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_GUI_SESSION_CONF" $guiSessionConf -}}
  {{- end }}

  {{- if .Values.enterprise.smtp.enabled }}
    {{- $_ := set $autoEnv "KONG_PORTAL_EMAILS_FROM" .Values.enterprise.smtp.portal_emails_from -}}
    {{- $_ := set $autoEnv "KONG_PORTAL_EMAILS_REPLY_TO" .Values.enterprise.smtp.portal_emails_reply_to -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_EMAILS_FROM" .Values.enterprise.smtp.admin_emails_from -}}
    {{- $_ := set $autoEnv "KONG_ADMIN_EMAILS_REPLY_TO" .Values.enterprise.smtp.admin_emails_reply_to -}}
    {{- $_ := set $autoEnv "KONG_SMTP_HOST" .Values.enterprise.smtp.smtp_host -}}
    {{- $_ := set $autoEnv "KONG_SMTP_PORT" .Values.enterprise.smtp.smtp_port -}}
    {{- $_ := set $autoEnv "KONG_SMTP_STARTTLS" (quote .Values.enterprise.smtp.smtp_starttls) -}}
    {{- if .Values.enterprise.smtp.auth.smtp_username }}
      {{- $_ := set $autoEnv "KONG_SMTP_USERNAME" .Values.enterprise.smtp.auth.smtp_username -}}
      {{- $smtpPassword := include "secretkeyref" (dict "name" .Values.enterprise.smtp.auth.smtp_password_secret "key" "smtp_password") -}}
      {{- $_ := set $autoEnv "KONG_SMTP_PASSWORD" $smtpPassword -}}
    {{- end }}
  {{- else }}
    {{- $_ := set $autoEnv "KONG_SMTP_MOCK" "on" -}}
  {{- end }}

  {{- $lic := include "secretkeyref" (dict "name" .Values.enterprise.license_secret "key" "license") -}}
  {{- $_ := set $autoEnv "KONG_LICENSE_DATA" $lic -}}

{{- end }} {{/* End of the Enterprise settings block */}}

{{- $_ := set $autoEnv "KONG_NGINX_HTTP_INCLUDE" "/kong/servers.conf" -}}

{{- if .Values.postgresql.enabled }}
  {{- $_ := set $autoEnv "KONG_PG_HOST" (include "kong.postgresql.fullname" .) -}}
  {{- $_ := set $autoEnv "KONG_PG_PORT" .Values.postgresql.service.port -}}
  {{- $pgPassword := include "secretkeyref" (dict "name" (include "kong.postgresql.fullname" .) "key" "postgresql-password") -}}
  {{- $_ := set $autoEnv "KONG_PG_PASSWORD" $pgPassword -}}
{{- end }}

{{- if (and (not .Values.ingressController.enabled) (eq .Values.env.database "off")) }}
  {{- $_ := set $autoEnv "KONG_DECLARATIVE_CONFIG" "/kong_dbless/kong.yml" -}}
{{- end }}

{{- $_ := set $autoEnv "KONG_PLUGINS" (include "kong.plugins" .) -}}

{{/*
    ====== USER-SET ENVIRONMENT VARIABLES ======
*/}}

{{- $userEnv := dict -}}
{{- range $key, $val := .Values.env }}
  {{- $upper := upper $key -}}
  {{- $var := printf "KONG_%s" $upper -}}
  {{- $_ := set $userEnv $var $val -}}
{{- end -}}

{{/*
      ====== MERGE AND RENDER ENV BLOCK ======
*/}}

{{- $completeEnv := mergeOverwrite $autoEnv $userEnv -}}

{{- range keys $completeEnv }}
{{- $val := pluck . $completeEnv | first -}}
{{- $valueType := printf "%T" $val -}}
{{ if eq $valueType "map[string]interface {}" }}
- name: {{ . }}
{{ toYaml $val | indent 2 -}}
{{- else if eq $valueType "string" }}
{{- if regexMatch "valueFrom" $val }}
- name: {{ . }}
{{ $val | indent 2 }}
{{- else }}
- name: {{ . }}
  value: {{ $val | quote }}
{{- end }}
{{- else }}
- name: {{ . }}
  value: {{ $val | quote }}
{{- end }}
{{- end -}}

{{- end -}}

{{- define "kong.wait-for-postgres" -}}
- name: wait-for-postgres
  image: "{{ .Values.waitImage.repository }}:{{ .Values.waitImage.tag }}"
  imagePullPolicy: {{ .Values.waitImage.pullPolicy }}
  env:
  {{- include "kong.no_daemon_env" . | nindent 2 }}
  command: [ "/bin/sh", "-c", "until nc -zv $KONG_PG_HOST $KONG_PG_PORT -w1; do echo 'waiting for db'; sleep 1; done" ]
{{- end -}}
