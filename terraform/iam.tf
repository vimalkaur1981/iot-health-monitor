############################################
# ECS TASK EXECUTION ROLE
# Grants ECS tasks permissions to pull images,
# write logs, and access Secrets Manager.
############################################
resource "aws_iam_role" "group5_ecs_task_execution" {
  name = "group5_ecs_task_execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name = "${terraform.workspace}-ecs-task-execution"
    Env  = terraform.workspace
  }
}

# Attach ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.group5_ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "group5_ecs_task_execution_secrets" {
  name = "group5-ecs-task-execution-secrets"
  role = aws_iam_role.group5_ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      "Resource": [
				"arn:aws:secretsmanager:us-east-1:255945442255:secret:gmail_user-*",
				"arn:aws:secretsmanager:us-east-1:255945442255:secret:gmail_password-*"
			]
    }]
  })
}

############################################
# ECS TASK ROLE (APPLICATION ROLE)
# Role for application code running in ECS.
############################################
resource "aws_iam_role" "group5_ecs_task_role" {
  name = "${terraform.workspace}-g5-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${terraform.workspace}-ecs-task-role"
    Env  = terraform.workspace
  }
}

# Example: allow app to write logs (add app-specific policies as needed)
resource "aws_iam_role_policy_attachment" "task_logs" {
  role       = aws_iam_role.group5_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

############################################
# GITHUB ACTIONS ROLE
############################################
resource "aws_iam_role" "github_actions" {
  name = "${terraform.workspace}-github-actions-ecr-ecs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::255945442255:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:vimalkaur1981/iot-health-monitor:*"
          }
        }
      }
    ]
  })
  tags = {
    Name = "${terraform.workspace}-github-actions"
    Env  = terraform.workspace
  }
}

############################################
# GITHUB ACTIONS POLICIES
############################################
resource "aws_iam_role_policy_attachment" "github_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "github_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

############################################
# PASSROLE PERMISSION FOR ECS
############################################
resource "aws_iam_role_policy" "github_actions_passrole" {
  name = "github-actions-passrole"
  role = aws_iam_role.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "iam:PassRole"
      Resource = [
        aws_iam_role.group5_ecs_task_execution.arn,
        aws_iam_role.group5_ecs_task_role.arn
      ]
      Condition = {
        StringEquals = {
          "iam:PassedToService" = "ecs-tasks.amazonaws.com"
        }
      }
    }]
  })
}

