module "eks_cluster" {
  source                               = "git@github.com:McK-Internal/cf-terraform-aws-eks-cluster.git?ref=v3.0.0"
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_name                         = "vtbxmck-bootcamp"
  cluster_version                      = "1.28"
  log_aggregation_s3 = {
    bucket_name = aws_s3_bucket.eks.bucket
    kms_key_arn = aws_kms_key.codepipeline.arn
  }

  vpc_details = {
    vpc_id             = "vpc-0142ed266c5de6da2"
    public_subnet_ids  = ["subnet-0933ed5932e1155d7", "subnet-01fda852bbec5aed5"]
    private_subnet_ids = ["subnet-04519d94985a172cc", "subnet-0368ee10ab9aa48f5"]
  }
  providers = {
    aws.spoke   = aws
    aws.logging = aws
  }
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "aws-ebs-csi-driver"
  depends_on   = [aws_eks_node_group.node-ec2]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "vpc-cni"
  depends_on   = [aws_eks_node_group.node-ec2]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_node_group.node-ec2]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.node-ec2]
}

resource "aws_s3_bucket" "eks" {
  force_destroy = true
  bucket        = "vtbxmck-bootcamp-eks-api"
}

resource "aws_iam_role" "node_group_role" {
  name = "EKSNodeGroupRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_eks_node_group" "node-ec2" {
  cluster_name    = module.eks_cluster.eks_cluster_details.name
  node_group_name = "t3_large_node_group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = ["subnet-04519d94985a172cc", "subnet-0933ed5932e1155d7", "subnet-0368ee10ab9aa48f5", "subnet-01fda852bbec5aed5"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  ami_type       = "AL2_x86_64"
  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]
}

// Creating Full EKS Role for codebuild. Can be refactored
resource "aws_iam_role" "full_eks_permission_role" {
  name = "FullEKSPermission"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com",
          AWS : aws_iam_role.codebuild_api.arn
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.full_eks_permission_role.name
}
resource "aws_iam_role_policy_attachment" "eks_vppc_resource__fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.full_eks_permission_role.name
}
resource "aws_iam_role_policy_attachment" "eks_service_fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.full_eks_permission_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cni_fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.full_eks_permission_role.name
}
resource "aws_iam_role_policy_attachment" "eks_cluster_fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.full_eks_permission_role.name
}
resource "aws_iam_role_policy_attachment" "eks_worker_node_fullEKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.full_eks_permission_role.name
}

resource "aws_security_group_rule" "codebuild_eks_sg_inbound" {
  # S3 Gateway interfaces are implemented at the routing level which means we
  # can avoid the metered billing of a VPC endpoint interface by allowing
  # outbound traffic to the public IP ranges, which will be routed through
  # the Gateway interface:
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/privatelink-interface-endpoints.html
  description              = "Codebuild to EKS"
  type                     = "ingress"
  security_group_id        = module.eks_cluster.cluster_security_group
  from_port                = 0
  to_port                  = 65535
  protocol                 = "All"
  source_security_group_id = "sg-082cc0efcee8ad457"
}
