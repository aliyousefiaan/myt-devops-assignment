replicaCount: ${replicaCount}

service:
  type: ClusterIP
  port: 5000

ingress:
  enabled: true
  className: "alb"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/load-balancer-name: app-ingress-${env}
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/subnets: main-${env}-public-${aws_region}a, main-${env}-public-${aws_region}b
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn}
    external-dns.alpha.kubernetes.io/hostname: app.${public_domain}
  hosts:
    - host: app.${public_domain}
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.${public_domain}

resources:
  requests:
    cpu: ${cpu_requests}
    memory: ${memory_requests}
  limits:
    cpu: ${cpu_limits}
    memory: ${memory_limits}

livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

autoscaling:
  enabled: true
  minReplicas: ${minReplicas}
  maxReplicas: ${maxReplicas}
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

poddisruptionbudget:
  enabled: true
  minAvailable: 1

servicemonitor:
  enabled: true
  interval: 30s
  path: /metrics
  port: http

networkpolicy:
  enabled: true
  policy:
    policyTypes:
      - Ingress
      - Egress
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
%{ for subnet in allowed_subnets }
          - ipBlock:
              cidr: "${subnet}"
%{ endfor }
    egress: []

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: kubernetes.io/hostname
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: app
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        topologyKey: failure-domain.beta.kubernetes.io/zone
        labelSelector:
          matchLabels:
            app.kubernetes.io/name: app

podSecurityContext:
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  capabilities:
    drop:
      - ALL

env:
  - name: API_BASE_URL
    value: "app.${public_domain}"
  - name: LOG_LEVEL
    value: "%{ if env == "dev" }debug%{ else }info%{ endif }"
  - name: MAX_CONNECTIONS
    value: "100"
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: "app-secrets"
        key: "secret_key"
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: "app-secrets"
        key: "db_password"
