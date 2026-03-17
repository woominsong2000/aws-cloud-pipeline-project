# 1. SSM 역할을 위한 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "k6_ssm_profile" {
  name = "wegotosamsung-k6-ssm-profile"
  role = aws_iam_role.k6_ssm_role.name
}

# 2. IAM 역할 생성
resource "aws_iam_role" "k6_ssm_role" {
  name = "wegotosamsung-k6-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 3. AWS가 미리 만들어둔 SSM 핵심 권한 연결 (이게 핵심!)
resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.k6_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4. K6 EC2 instance 생성
resource "aws_instance" "k6_worker" {
  ami                    = "ami-0c9c942bd7bf113a2"
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.k6_sg.id]
  key_name               = "wegotosamsung-key-hong"
  
  iam_instance_profile   = aws_iam_instance_profile.k6_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E34671
              echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
              sudo apt-get update
              sudo apt-get install k6 -y
              EOF

  tags = { Name = "${var.project_name}-k6-tester" }
}
