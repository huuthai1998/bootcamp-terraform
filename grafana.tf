# # Install Grafana chart
# resource "helm_release" "grafana" {
#   name       = "grafana"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "grafana"
#   version    = var.grafana_version.helm_chart_version
#   namespace  = var.eks_grafana_namespace
#   # Configure ingress route for the UI
#   set {
#     name  = "service.type"
#     value = "NodePort"
#   }
#   set {
#     name  = "ingress.enabled"
#     value = true
#   }
#   set {
#     name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
#     value = "alb"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
#     value = "grafana-alb"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
#     value = var.internal_alb ? "internal" : "internet-facing"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "instance"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/inbound-cidrs"
#     value = "0.0.0.0/0"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
#     value = "[{\"HTTPS\": 443}]"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
#     value = var.acm_certificate_arn
#   }
#   dynamic "set" {
#     for_each = var.wafv2_acl_arn != null ? ["1"] : []
#     content {
#       name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/wafv2-acl-arn"
#       value = var.wafv2_acl_arn
#     }
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-path"
#     value = "/health"
#   }
#   set {
#     name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/group\\.name"
#     value = "grafana"
#   }
#   set {
#     name  = "ingress.hosts[0]"
#     value = "monitor.${var.dns_name}"
#   }
#   set {
#     name  = "ingress.path"
#     value = "/"
#   }
#   # Configure data storage
#   set {
#     name  = "persistence.enabled"
#     value = true
#   }
#   set {
#     name  = "persistence.type"
#     value = "pvc"
#   }
#   set {
#     name  = "persistence.size"
#     value = "20Gi"
#   }
#   set {
#     name  = "persistence.accessModes[0]"
#     value = "ReadWriteOnce"
#   }
#   depends_on = [kubernetes_namespace.grafana]
# }
