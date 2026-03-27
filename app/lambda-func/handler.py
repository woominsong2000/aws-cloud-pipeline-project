import os
import json
import boto3
from PIL import Image
from io import BytesIO

s3 = boto3.client("s3")

PROCESSED_BUCKET = os.environ["PROCESSED_BUCKET"]
RESIZE_WIDTH = 640
RESIZE_HEIGHT = 640


def handler(event, context):
    # event.get()을 사용하여 Records가 없는 예상치 못한 이벤트 구조에도 대비 (안전한 파싱)
    for record in event.get("Records", []):
        # 1. SQS 메시지에서 S3 이벤트 파싱
        body = json.loads(record["body"])

        # 2. S3 테스트 이벤트(s3:TestEvent) 등 처리할 필요가 없는 이벤트 무시 (skip)
        # 정상적인 S3 ObjectCreated 이벤트라면 "Records" 필드가 존재함
        if "Records" not in body:
            print(f"Skipping non-S3 event or test event: {body.get('Event', 'unknown')}")
            continue

        # 3. 실제 이미지 처리 로직
        try:
            s3_event = body["Records"][0]["s3"]

            source_bucket = s3_event["bucket"]["name"]
            object_key = s3_event["object"]["key"]

            print(f"Processing: s3://{source_bucket}/{object_key}")

            # source 버킷에서 이미지 다운로드
            response = s3.get_object(Bucket=source_bucket, Key=object_key)
            image_data = response["Body"].read()

            # Pillow로 리사이즈
            image = Image.open(BytesIO(image_data))
            resized = image.resize((RESIZE_WIDTH, RESIZE_HEIGHT))

            # processed 버킷에 업로드
            buffer = BytesIO()
            resized.save(buffer, format=image.format or "JPEG")
            buffer.seek(0)

            s3.put_object(
                Bucket=PROCESSED_BUCKET,
                Key=object_key,
                Body=buffer,
                ContentType=response["ContentType"],
            )

            print(f"Saved: s3://{PROCESSED_BUCKET}/{object_key}")

        except Exception as e:
            # 4. 실제 에러 발생 시 명시적으로 에러 발생 (raise)
            # 에러를 숨기지 않고 밖으로 던져야 SQS가 실패를 인지하고 재시도(maxReceiveCount) 후 DLQ로 보냅니다.
            print(f"Error processing image {object_key} from bucket {source_bucket}: {str(e)}")
            raise e