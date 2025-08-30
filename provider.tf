terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">=1.0"
}

provider "aws" {
  region = local.region
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name 
}
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.eks.token
   
}

provider "helm" { 
  kubernetes = {
    host                   = aws_eks_cluster.eks.endpoint
      cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
      token = data.aws_eks_cluster_auth.eks.token
}  
  }
 
      
