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
    for record in event["Records"]:
        # 1. SQS 메시지에서 S3 이벤트 파싱
        body = json.loads(record["body"])

        # # S3 테스트 이벤트 무시
        # if "Records" not in body:
        #     print(f"Skipping non-S3 event: {body.get('Event', 'unknown')}")
        #     continue

        s3_event = body["Records"][0]["s3"]

        source_bucket = s3_event["bucket"]["name"]
        object_key = s3_event["object"]["key"]

        print(f"Processing: s3://{source_bucket}/{object_key}")

        # 2. source 버킷에서 이미지 다운로드
        response = s3.get_object(Bucket=source_bucket, Key=object_key)
        image_data = response["Body"].read()

        # 3. Pillow로 리사이즈
        image = Image.open(BytesIO(image_data))
        resized = image.resize((RESIZE_WIDTH, RESIZE_HEIGHT))

        # 4. processed 버킷에 업로드
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
