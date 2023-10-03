module "eks_cluster" {
  source                               = "git@github.com:McK-Internal/cf-terraform-aws-eks-cluster.git?ref=v3.0.0"
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cluster_name                         = "vtbxmck-bootcamp"
  cluster_version                      = "1.27"
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
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks_cluster.eks_cluster_details.name
  addon_name   = "coredns"
}

resource "aws_s3_bucket" "eks" {
  bucket = "vtbxmck-bootcamp-eks-api"
}
