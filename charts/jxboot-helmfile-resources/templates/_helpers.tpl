{{- define "ingressAnnotations" }}
  {{- $annotations := dict }}
  {{- $componentSpec := index .Values .component }}

  {{- if hasKey $componentSpec.ingress "annotations" }}
    {{- $_ := merge $annotations $componentSpec.ingress.annotations }}
  {{- end }}

  {{- $_ := merge $annotations .Values.ingress.annotations .Values.jxRequirements.ingress.annotations  }}

  {{- if not (hasKey $annotations "kubernetes.io/ingress.class") }}
    {{- $customIngressClass := "" }}
    {{- if $componentSpec.ingress.customIngressClass }}
      {{- $customIngressClass := $componentSpec.ingress.customIngressClass }}
      {{- $_ := set $annotations "kubernetes.io/ingress.class" $customIngressClass }}
    {{- else if hasKey .Values.ingress "customIngressClass" }}
      {{- if eq .component "docker-registry" }}
        {{- if hasKey .Values.ingress.customIngressClass "dockerRegistry" }}
          {{- $customIngressClass := index .Values.ingress.customIngressClass "dockerRegistry" }}
          {{- $_ := set $annotations "kubernetes.io/ingress.class" $customIngressClass }}
        {{- end }}
      {{- else if hasKey .Values.ingress.customIngressClass .component }}
        {{- $customIngressClass := index .Values.ingress.customIngressClass .component }}
        {{- $_ := set $annotations "kubernetes.io/ingress.class" $customIngressClass }}
      {{- end }}
    {{- end }}
    {{- if not (hasKey $annotations "kubernetes.io/ingress.class") }}
      {{- $_ := set $annotations "kubernetes.io/ingress.class" ($customIngressClass | default "nginx")  }}
    {{- end }}
  {{- end }}
  {{- if and (hasKey .Values.jxRequirements.ingress "serviceType") (.Values.jxRequirements.ingress.serviceType) (eq .Values.jxRequirements.ingress.serviceType "NodePort") (not (hasKey $annotations "jenkins.io/host")) }}
    {{- $_ := set $annotations "jenkins.io/host" .Values.jxRequirements.ingress.domain }}
  {{- end }}
  {{- if $annotations }}
{{ toYaml $annotations | indent 4 }}
  {{- end }}
{{- end }}

{{- /*
httpRouteParentRefs renders the parentRefs list entries for an HTTPRoute.
The "http" listener is attached whenever gatewayApi.attachHttp is set; the
"https" listener is additionally attached when gatewayApi.attachHttps and
jxRequirements.ingress.tls.enabled are both true. Section names and the gateway
name/namespace come from the gatewayApi values block.
*/ -}}
{{- define "httpRouteParentRefs" -}}
{{- $gw := .Values.gatewayApi.gateway -}}
{{- $name := $gw.name | default "envoy-gateway" -}}
{{- $ns := $gw.namespace | default "envoy-gateway-system" -}}
{{- if .Values.gatewayApi.attachHttp -}}
- name: {{ $name }}
  namespace: {{ $ns }}
  sectionName: {{ $gw.sectionName.http | default "http" }}
{{- end }}
{{- if and .Values.gatewayApi.attachHttps .Values.jxRequirements.ingress.tls.enabled }}
- name: {{ $name }}
  namespace: {{ $ns }}
  sectionName: {{ $gw.sectionName.https | default "https" }}
{{- end }}
{{- end }}

{{- /*
httpRouteHostname returns the hostname for a component's HTTPRoute: the
per-component httpRoute.customHost if set, otherwise the composed
<prefix><namespaceSubDomain><domain>. Call with (dict "Values" .Values "component" "<name>").
*/ -}}
{{- define "httpRouteHostname" -}}
{{- $spec := index .Values .component -}}
{{- if $spec.httpRoute.customHost -}}
{{ $spec.httpRoute.customHost }}
{{- else -}}
{{ $spec.httpRoute.prefix }}{{ .Values.jxRequirements.ingress.namespaceSubDomain }}{{ .Values.jxRequirements.ingress.domain }}
{{- end -}}
{{- end }}

{{- /*
httpRouteAnnotations merges the global gatewayApi.annotations with the
per-component httpRoute.annotations and returns them as raw (unindented) YAML,
or an empty string when there are none. Call with
(dict "Values" .Values "component" "<name>"); the caller is responsible for
indenting (e.g. `nindent 4`) and for only emitting the `annotations:` key when
the result is non-empty.
*/ -}}
{{- define "httpRouteAnnotations" -}}
{{- $annotations := dict -}}
{{- $componentSpec := index .Values .component -}}
{{- if hasKey $componentSpec.httpRoute "annotations" -}}
{{- $_ := merge $annotations $componentSpec.httpRoute.annotations -}}
{{- end -}}
{{- if .Values.gatewayApi.annotations -}}
{{- $_ := merge $annotations .Values.gatewayApi.annotations -}}
{{- end -}}
{{- if $annotations -}}
{{ toYaml $annotations }}
{{- end -}}
{{- end }}
