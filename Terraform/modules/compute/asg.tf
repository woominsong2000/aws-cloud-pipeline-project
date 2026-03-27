
# 도커가 설치된 AMI 이미지를 가져옴
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# 1. EC2 시작 템플릿
resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-tpl-"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
    }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 강제
    http_put_response_hop_limit = 2        # 도커/컨테이너 환경에서 신분증을 잘 찾기 위한 핵심 설정!
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # 1. 서버 켜지자마자 도커 설치, 시작, 자동 실행

    # 도커가 설치된 ami 이미지를 사용함으로 제거
    # dnf update -y
    # dnf install -y docker

    systemctl start docker
    systemctl enable docker

    # 2. ec2-user가 sudo없이 쓸 수 있게
    usermod -aG docker ec2-user

    # 3. AWS CLI로 ECR 로그인(넘겨받은 ECR 주소 여기서 사용)
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${var.api_ecr_url}

    # 4. 유나 API 앱 이미지 가져오기(pull)
    docker pull ${var.api_ecr_url}:latest

    # 5. API 서버 실행 (S3_BUCKET_NAME을 환경변수로 꼭 넣어줘야 합니다!)
    sudo docker run -d -p 80:80 \
      -e S3_BUCKET_NAME=${var.source_bucket_id} \
      -e AWS_REGION=ap-northeast-2 \
      ${var.api_ecr_url}:latest
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-ec2" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Auto Scaling Group 
resource "aws_autoscaling_group" "this" {
  name                = "${var.project_name}-asg"
  
  # 위에서 만든 시작 템플릿 연결
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  # 인스턴스가 생성될 서브넷 (경락님께 받을)
  vpc_zone_identifier = var.private_subnet_ids

  # 서버 대수 (부하테스트 계획 미정이라 무난하게 설정,짝수)
  min_size         = 2
  max_size         = 6
  desired_capacity = 2

  # 추가: ASG 그룹 지표 수집 활성화 (대시보드 인스턴스 수 확인용)
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances",
    "GroupMinSize",
    "GroupMaxSize"
  ]

  # alb.tf에서 만든 대상 그룹의 ARN을 가져오기
  target_group_arns = [aws_lb_target_group.this.arn]

  # 서버 정상 여부 판단
  health_check_type         = "EC2"
  health_check_grace_period = 180 # 서버가 뜨고 도커 깔리는 시간(3분) 동안은 기다려줌

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true # 인스턴스가 뜰 때 이 태그를 그대로 복사함
  }

  instance_refresh {
    strategy = "Rolling"
  }

  warm_pool {
    pool_state = "Stopped"
    min_size   = 2

    instance_reuse_policy {
      reuse_on_scale_in = true
    }
  }
}

# 3. 스케일링 정책1 : ALB 기반(선제적)
resource "aws_autoscaling_policy" "scale_out_by_request" {
  name                   = "${var.project_name}-scale-out-request"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# 4. 스케일링 정책2 : CPU 기반 정책(방어적)
resource "aws_autoscaling_policy" "scale_out_by_cpu" {
  name                   = "${var.project_name}-scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

# 5. 스케일 인 정책1 : ALB 요청 수 감소 시
resource "aws_autoscaling_policy" "scale_in_by_request" {
  name                   = "${var.project_name}-scale-in-request"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 180
  policy_type            = "SimpleScaling"
}

// 트래픽이 몰리는 구간에서 메모리 부족으로 분산 속도가 느려짐에 따라 cpu가 제 역할을 못 할 수 있음.
// 그에 따라 cpu 사용률이 낮아지고 의도치 않은 scale-in이 발생할 수 있음. 따라서 제거
# # 6. 스케일 인 정책2 : CPU 사용량 감소 시
# resource "aws_autoscaling_policy" "scale_in_by_cpu" {
#   name                   = "${var.project_name}-scale-in-cpu"
#   autoscaling_group_name = aws_autoscaling_group.this.name
#   adjustment_type        = "ChangeInCapacity"
#   scaling_adjustment     = -1
#   cooldown               = 180
#   policy_type            = "SimpleScaling"
# }
