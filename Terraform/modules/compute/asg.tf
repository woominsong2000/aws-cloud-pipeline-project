# 1. EC2 시작 템플릿
resource "aws_launch_template" "this" {
  name_prefix   = "${var.project_name}-tpl-"
  image_id      = "ami-040c33c6a51fd5d96" 
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # 1. 서버 켜지자마자 도커 설치, 시작, 자동 실행
    dnf update -y
    dnf install -y docker
    systemctl start docker
    systemctl enable docker
    # 2. ec2-user가 sudo없이 쓸 수 있게
    usermod -aG docker ec2-user
    # 3. API 서버 실행(ECR에서 가져오기!!)
    # 테스트용 컨테이너
    sudo docker run -d -p 80:80 --name web-server nginx
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

  # alb.tf에서 만든 대상 그룹의 ARN을 가져오기
  target_group_arns = [aws_lb_target_group.this.arn]

  # 서버 정상 여부 판단
  health_check_type         = "ELB"
  health_check_grace_period = 300 # 서버가 뜨고 도커 깔리는 시간(5분) 동안은 기다려줌

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true # 인스턴스가 뜰 때 이 태그를 그대로 복사함
  }

  instance_refresh {
    strategy = "RollingUpdate"
  }
}

# 3. 스케일링 정책1 : ALB 기반(선제적)
resource "aws_autoscaling_policy" "scale_out_by_request" {
  name                   = "${var.project_name}-scale-out-request"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

# 4. 스케일링 정책2 : CPU 기반 정책(방어적)
resource "aws_autoscaling_policy" "scale_out_by_cpu" {
  name                   = "${var.project_name}-scale-out-cpu"
  autoscaling_group_name = aws_autoscaling_group.this.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}