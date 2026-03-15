import os
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import boto3
from botocore.exceptions import NoCredentialsError

app = FastAPI()

# --- 환경변수 설정 (테라폼에서 넘겨받을 값들) ---
# 유나님이 테라폼으로 만든 S3 버킷 이름을 여기에 넣어야 합니다.
# 나중에 도커로 실행할 때 환경변수로 세팅해줄 거예요.
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "유나님의-s3-버킷-이름-직접입력")
AWS_REGION = os.getenv("AWS_REGION", "ap-northeast-2") # 서울 리전 기본값

# --- Boto3 S3 클라이언트 초기화 ---
# EC2 인스턴스 프로파을을 통해 권한을 주었으므로, 별도의 키 입력 없이 작동합니다.
s3_client = boto3.client('s3', region_name=AWS_REGION)

@app.get("/")
async def root():
    return {"message": "Hello, Yuna's API App is Running!"}

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    """
    사용자가 보낸 사진을 받아서 S3 버킷에 업로드하는 API 엔드포인트
    """
    # 1. 파일 이름 가져오기
    filename = file.filename
    
    # 2. S3에 업로드할 때 사용할 키(경로+이름) 설정
    # 예: uploads/2023-10-27/mypicture.jpg 처럼 날짜별로 정리해도 좋아요.
    s3_key = f"uploads/{filename}"

    try:
        # 3. Boto3를 이용해 S3에 업로드 (가장 핵심 부분!)
        s3_client.upload_fileobj(
            file.file,          # 업로드할 파일 객체
            S3_BUCKET_NAME,      # 대상 S3 버킷 이름
            s3_key,              # S3 내 저장 경로/이름
            ExtraArgs={
                'ContentType': file.content_type # 파일 타입(jpg, png 등) 유지
            }
        )
        
        # 4. 성공 시 반환할 메시지
        return JSONResponse(content={
            "message": "File uploaded successfully!",
            "bucket": S3_BUCKET_NAME,
            "key": s3_key,
            "url": f"https://{S3_BUCKET_NAME}.s3.{AWS_REGION}.amazonaws.com/{s3_key}"
        }, status_code=200)

    except NoCredentialsError:
        # 권한이 없을 때 예외 처리
        raise HTTPException(status_code=403, detail="AWS credentials not found. Check IAM Role.")
    except Exception as e:
        # 기타 에러 처리
        raise HTTPException(status_code=500, detail=f"An error occurred: {str(e)}")