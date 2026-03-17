import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, _context):
    # 1. SNS 메시지 추출
    sns_message = event['Records'][0]['Sns']['Message']

    # 2. 슬랙 메시지 포맷팅
    slack_body = {
        "text": f"🚨 *AWS 인프라 알람 발생!* 🚨\n\n> *내용:* {sns_message}",
        "username": "Reliability-Bot"
    }

    # 3. 테라폼에서 주입한 환경변수 읽기
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")

    # 4. 슬랙으로 전송
    response = http.request(
        'POST',
        webhook_url, # 변수 이름 일치 확인!
        body=json.dumps(slack_body),
        headers={'Content-Type': 'application/json'}
    )

    return {"status": response.status}