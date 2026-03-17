import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, context):
    # SNS에서 보낸 메시지 추출
    sns_message = event['Records'][0]['Sns']['Message']

    # 슬랙에 보낼 데이터 포맷팅
    slack_body = {
        "text": f"🚨 *AWS 인프라 알람 발생!* 🚨\n\n> *내용:* {sns_message}",
        "username": "Reliability-Bot"
    }

    # 슬랙 Webhook URL로 전송 (아까 복사한 URL로 대체하거나 환경변수 사용)
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")

    response = http.request(
        'POST', url,
        body=json.dumps(slack_body),
        headers={'Content-Type': 'application/json'}
    )

    return {"status": response.status}