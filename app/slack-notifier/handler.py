import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, _context):
    # 1. SNS 메시지 추출
    sns_message = event['Records'][0]['Sns']['Message']

    # 2. 메시지 가독성 개선 (JSON 파싱)
    try:
        # SNS 메시지가 JSON 문자열이므로 객체로 변환
        msg_data = json.loads(sns_message)
        alarm_name = msg_data.get('AlarmName', '알 수 없는 알람')
        reason = msg_data.get('NewStateReason', '상세 사유 없음')
        region = msg_data.get('Region', 'Asia Pacific (Seoul)')

        # 보기 좋게 포맷팅
        text = (
            f"🚨 *AWS 인프라 경보 발령!* 🚨\n\n"
            f"> *경보명:* `{alarm_name}`\n"
            f"> *상태:* `ALARM` 🔴\n"
            f"> *지역:* `{region}`\n"
            f"> *원인:* {reason}"
        )
    except Exception:
        # JSON 파싱에 실패할 경우를 대비한 기본 텍스트
        text = f"🚨 *AWS 인프라 알람 발생!* 🚨\n\n> *내용:* {sns_message}"

    # 3. 슬랙 메시지 구성
    slack_body = {
        "text": text,
        "username": "Reliability-Bot"
    }

    # 4. 환경변수에서 URL 가져오기 및 전송
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")

    response = http.request(
        'POST',
        webhook_url,
        body=json.dumps(slack_body),
        headers={'Content-Type': 'application/json'}
    )

    return {"status": response.status}