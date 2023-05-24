locals {
  deployment_k8s_rbac_group = "spacelift-worker-deployer"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.24"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.small"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      asg_desired_capacity          = 2
    }
  ]
    
  map_roles = [
    {
      rolearn  = "arn:aws:iam::163754997915:role/myAmazonEKSClusterRole"
      username = "arn:aws:iam::163754997915:role/myAmazonEKSClusterRole"
      groups   = [local.deployment_k8s_rbac_group]
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
  
resource "kubernetes_cluster_role" "deployer" {
  depends_on = [module.eks]

  metadata {
    name = "spacelift-worker-deployer-clusterrole"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}
  
resource "kubernetes_cluster_role_binding" "deployer" {
  depends_on = [module.eks]

  metadata {
    name = "spacelift-worker-deployer-clusterrole-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "spacelift-worker-deployer-clusterrole"
  }

  subject {
    kind      = "Group"
    name      = local.deployment_k8s_rbac_group
    api_group = "rbac.authorization.k8s.io"
  }
}
  
resource "kubernetes_role" "deployer" {
  depends_on = [module.eks]

  metadata {
    name      = "spacelift-worker-deployer-role"
    namespace = "default"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "secrets", "services", "serviceaccounts"]
    verbs      = ["create", "get", "list", "update", "delete", "patch", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "configmaps"]
    verbs      = ["create", "get", "list", "update", "delete", "patch", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["replicasets"]
    verbs      = ["get", "list", "watch"]
  }
}
  
resource "kubernetes_role_binding" "deployer" {
  depends_on = [module.eks]

  metadata {
    name      = "spacelift-worker-deployer-role-binding"
    namespace = "default"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "spacelift-worker-deployer-role"
  }

  subject {
    kind      = "Group"
    name      = local.deployment_k8s_rbac_group
    api_group = "rbac.authorization.k8s.io"
  }
}
