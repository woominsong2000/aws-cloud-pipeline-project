# 1. 베이스 이미지 설정 (가벼운 Python Alpine 이미지 추천)
FROM python:3.9-slim-buster

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 필요한 라이브러리 목록 복사
COPY requirements.txt .

# 4. 라이브러리 설치 (fastapi, uvicorn, boto3 등)
RUN pip install --no-cache-dir -r requirements.txt

# 5. 애플리케이션 코드 복사
COPY main.py .

# 6. API 서버 실행 명령어 (Port 80 사용)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]