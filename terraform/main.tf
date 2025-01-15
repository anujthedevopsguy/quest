

# Provider
provider "aws" {
  region = var.region
}

# Netowrk stack

# VPC
resource "aws_vpc" "quest_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "quest-vpc" }
}

data "aws_availability_zones" "available" {}
# Public subnet
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.quest_vpc.id
  cidr_block              = var.subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "public-subnet-${count.index}" }
}

# Internet Gateway and Route Table
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.quest_vpc.id
  tags   = { Name = "ecs-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.quest_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# private subnet settings

# Create Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.quest_vpc.id
  tags = {
    Name = "private-route-table"
  }
}

# Create Subnets
resource "aws_subnet" "pri_subnet_1" {
  vpc_id                  = aws_vpc.quest_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "pri_subnet_2" {
  vpc_id                  = aws_vpc.quest_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-2"
  }
}

# Security Group for load balancer
resource "aws_security_group" "quest_sg" {
  vpc_id = aws_vpc.quest_vpc.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "quest-alb-sg" }
}

# Security group for ECS service
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.quest_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.quest_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "ecs-cluster-alb-sg" }
}

# ECS Cluster for quest application
resource "aws_ecs_cluster" "main" {
  name = "quest-cluster"
}

# Load Balancer
resource "aws_lb" "ecs_quest_alb" {
  name               = "quest-alb"
  internal           = false
  security_groups    = [aws_security_group.quest_sg.id]
  subnets            = aws_subnet.public[*].id
  load_balancer_type = "application"
  tags = { Name = "quest-alb" }
}

resource "aws_lb_target_group" "ecs" {
  name        = "quest-tg"
  port        = var.container_port_1
  protocol    = "HTTP"
  vpc_id      = aws_vpc.quest_vpc.id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_quest_alb.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# Task Definition
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "ecs-task"
  network_mode             = "awsvpc"
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "quest"
      image     = "quest:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port_1
          hostPort      = var.container_port_1
        }
      ],
      secret = {
        valueFrom = "SECRET_WORD"
        name = "SECRET_WORD" 
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.pri_subnet_1.id, aws_subnet.pri_subnet_2.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "quest"
    container_port   = var.container_port_1
  }
  tags = { Name = "ecs-service" }
}


# Iam role and policy of ECS tasks
# Create IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "ecs-task-execution-role"
  }
}

# IAM Policy for ECS Task Role
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecs-task-policy"
  description = "Policy for ECS tasks to fetch ECR images and secrets from Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:us-east-1:207990345110:secret:quest-secret"
      }
    ]
  })
}

# Attach IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}



