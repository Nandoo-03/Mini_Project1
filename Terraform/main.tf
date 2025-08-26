terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

#create VPC

resource "aws_vpc" "Guvi_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "My_VPC"
    }
}

#private_subnet
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.Guvi_vpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "Private-subnet"
    }  
}

#Public_subnet
resource "aws_subnet" "Public_subnet_1" {
    vpc_id = aws_vpc.Guvi_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public-subnet-1"
    }
}

resource "aws_subnet" "Public_subnet_2" {
    vpc_id = aws_vpc.Guvi_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "Public-subnet-2"
    }
}


#internet_gateway
resource "aws_internet_gateway" "my-ig" {
     vpc_id = aws_vpc.Guvi_vpc.id

     tags = {
       Name = "My-IG"
     }
}

#route_table
resource "aws_route_table" "My-Route-Table" {
    vpc_id = aws_vpc.Guvi_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-ig.id
    }
}

resource "aws_route_table_association" "public-RT" {
    route_table_id = aws_route_table.My-Route-Table.id
    subnet_id = aws_subnet.Public_subnet_1.id
  
}

resource "aws_route_table_association" "public-RT2" {
    route_table_id = aws_route_table.My-Route-Table.id
    subnet_id = aws_subnet.Public_subnet_2.id
  
}


#key
resource "aws_key_pair" "my-key" {
  key_name = "my-key"
  public_key = file("mini-key.pub")
}

#security-groups
resource "aws_security_group" "instance-sg" {
  name = "Instance-sg"
  description = "This is the SG for my instance"
  vpc_id = aws_vpc.Guvi_vpc.id

  #inbound rule
  ingress {
    from_port =22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH open"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP open"
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jenkins"
  }
  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Trend-app"
  }


  #outbound rule
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All access"
  }
  tags = {
    name = "my-instance-sg"
  }
  
}


# IAM Role for EC2 (Jenkins)
resource "aws_iam_role" "ec2_role" {
  name = "ec2_jenkins_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Effect = "Allow"
     Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "allow_describe_eks_cluster" {
  name = "AllowDescribeEKSCluster"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "eks:DescribeCluster"
        Resource = "arn:aws:eks:ap-south-1:412902451006:cluster/eks-cluster"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "eks_cluster_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_readonly" {
  role       = aws_iam_role.ec2_role.name 
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "eks_read_only_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.eks_readonly_policy.arn
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_full_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_jenkins_profile"
  role = aws_iam_role.ec2_role.name
}



#EC2 instance
resource "aws_instance" "myserver" {

    ami = "ami-02d26659fd82cf299"
    instance_type = "t2.medium"
    depends_on = [aws_security_group.instance-sg,aws_key_pair.my-key]
    subnet_id = aws_subnet.Public_subnet_1.id
    vpc_security_group_ids = [aws_security_group.instance-sg.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    key_name = aws_key_pair.my-key.key_name
    

    user_data = file("jenkins.sh")

  tags = {
    Name = "jenkins-server"
  }
}

# IAM Role for EKS
#resource "aws_iam_role" "eks_cluster_role" {
  #name = "eks-cluster-role"

  #assume_role_policy = jsonencode({
  #  Version = "2012-10-17"
   # Statement = [{
    #  Effect = "Allow"
     # Principal = {
      #  Service = "eks.amazonaws.com"
      #}
      #Action = "sts:AssumeRole"
 #   }]
  #})
#}

#resource "aws_iam_role_policy_attachment" "eks_cluster_role_attach" {
 # policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  #role       = aws_iam_role.eks_cluster_role.name
#}

#EKS cluster

#resource "aws_eks_cluster" "Eks_cluster" {
   # name = "eks-cluster"
   # role_arn = aws_iam_role.eks_cluster_role.arn

   # vpc_config {
   ##   subnet_ids = [aws_subnet.Public_subnet.id, aws_subnet.public_subnet-2.id]
   # }

   #   depends_on = [aws_iam_role_policy_attachment.eks_cluster_role_attach]
#}
