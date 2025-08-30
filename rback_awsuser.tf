# Create ClusterRole using kubernetes_manifest
resource "kubernetes_manifest" "read_only_cluster_role" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "viewer"
    }
    rules = [
      {
        apiGroups = ["*"]
        resources = [
          "configmaps",
          "pods",
          "deployments",
          "secrets",
          "services",
          "pods/log"  # Added log access as it's commonly needed for read-only
        ]
        verbs = ["get", "list", "watch"]
      },
     
    ]
  }
  depends_on = [ aws_eks_cluster.eks,aws_eks_node_group.node ]

}
resource "kubernetes_manifest" "role_binding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "viewer-binding"
    }
    subjects = [
      {
        kind      = "Group"
        name      = "my-viewer-group"
        apiGroup  = "rbac.authorization.k8s.io"
      }
    ]
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "viewer"
    }
  }

  depends_on = [kubernetes_manifest.read_only_cluster_role]
}

## Aws user creation and bind to rback group.

resource "aws_iam_user" "name" {
  name = "developer"
}

# Create IAM policy for EKS read-only access
resource "aws_iam_policy" "eks_readonly_policy" {
  name        = "EKSReadOnlyAccessPolicy"
  description = "Policy for EKS read-only access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = "*"
      },
      
    ]
  })
}

resource "aws_iam_user_policy_attachment" "eks_readonly_attachment" {
  user       = aws_iam_user.name.name
  policy_arn = aws_iam_policy.eks_readonly_policy.arn
}
resource "aws_eks_access_entry" "access" {
  cluster_name = aws_eks_cluster.eks.name 
  principal_arn = aws_iam_user.name.arn
  kubernetes_groups = ["my-viewer-group"]

  depends_on = [ aws_eks_cluster.eks,aws_eks_node_group.node ]
}

resource "aws_iam_access_key" "eks_readonly_user_key" {
  user = aws_iam_user.name.name
}

output "access_key_id" {
  value     = aws_iam_access_key.eks_readonly_user_key.id
  sensitive = true
}

output "secret_access_key" {
  value     = aws_iam_access_key.eks_readonly_user_key.secret
    sensitive = true
}