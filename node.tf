resource "aws_iam_role" "nodes" {
  name = "${local.env}-${local.eks_name}-eks-nodes"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.nodes.name 
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.nodes.name 
}
resource "aws_iam_role_policy_attachment" "eks_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role = aws_iam_role.nodes.name 
}
resource "aws_eks_node_group" "node" {
  cluster_name = aws_eks_cluster.eks.name 
  version = local.eks_version
  node_group_name = "staging-1"
  node_role_arn = aws_iam_role.nodes.arn
  subnet_ids = [  
    aws_subnet.private-sub1.id,
    aws_subnet.private-sub2.id
   ]
   capacity_type = "ON_DEMAND"
   instance_types = [ "t3.large" ]
   scaling_config {
     desired_size = 1
     max_size = 5
     min_size = 0
   }
   update_config {
     max_unavailable = 1
   }
   labels = {
     role = "staging-1"
   }
   depends_on = [  
    aws_iam_role_policy_attachment.eks,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_node_policy,
    ]
    lifecycle {
      ignore_changes = [ scaling_config[0].desired_size ]
    }

}