terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name  = "vpc-id"
    value = data.aws_vpc.default.id
  }
}

resource "aws_ecs_cluster" "main" {
  name = "prototype-perf-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "prototype-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "prototype-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "prototype-ecs-exec-policy"
  description = "Allows ECS tasks to host SSM sessions for ECS Exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}

resource "aws_ecs_task_definition" "app" {
  family                   = "spring-boot-perf-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024" # 1 vCPU
  memory                   = "2048" # 2 GB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "spring-app"
      image     = "<YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/spring-boot-perf-repo:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      linuxParameters = {
        capabilities = {
          add = ["SYS_PTRACE"]
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/spring-boot-perf"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "app"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])
}

resource "aws_security_group" "ecs_tasks" {
  name        = "prototype-ecs-tasks-sg"
  description = "Allow inbound traffic to Spring Boot app"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "main" {
  name            = "spring-boot-perf-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
  }
}
