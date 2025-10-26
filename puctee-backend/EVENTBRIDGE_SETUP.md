# EventBridge Scheduler Setup Guide

このガイドでは、AWS EventBridge SchedulerがRailway上のバックエンドエンドポイントにHTTPリクエストを送信する設定方法を説明します。

## アーキテクチャ

```
Plan作成 → EventBridge Scheduler → API Destination → Railway Backend → iOS Silent Notification
```

## 必要なAWSリソース

### 1. IAM Role: `puctee-scheduler-http-role`

EventBridge SchedulerがAPI Destinationを呼び出すために必要なロール。

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Permissions Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:InvokeApiDestination"
      ],
      "Resource": "arn:aws:events:ap-northeast-1:002066576827:api-destination/puctee-railway-api-destination/*"
    }
  ]
}
```

### 2. EventBridge API Destination

コードで自動的に作成されます：
- **Name:** `puctee-railway-api-destination`
- **Endpoint:** `https://{RAILWAY_PUBLIC_DOMAIN}/api/scheduler/silent-notification`
- **HTTP Method:** POST
- **Authentication:** API Key (X-API-Key header)

### 3. EventBridge Connection

コードで自動的に作成されます：
- **Name:** `puctee-railway-connection`
- **Auth Type:** API_KEY
- **API Key Name:** X-API-Key
- **API Key Value:** `{SCHEDULER_API_KEY}`

## 環境変数設定

Railway環境変数に以下を設定：

```bash
# Railway公開ドメイン（自動設定される場合もあり）
RAILWAY_PUBLIC_DOMAIN=your-app.up.railway.app

# スケジューラーAPI認証キー（任意の強力な文字列）
SCHEDULER_API_KEY=your-secure-random-key-here

# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=ap-northeast-1
```

## 動作フロー

### 1. Plan作成時

```python
# app/api/routers/plans/create.py
success = await schedule_silent_for_plan(db_plan.id, start_utc)
```

### 2. EventBridge Scheduler作成

- API DestinationとConnectionが存在しない場合は自動作成
- スケジュールを作成し、指定時刻にAPI Destinationを呼び出すよう設定

### 3. スケジュール実行時

指定時刻になると：
1. EventBridge SchedulerがAPI Destinationを呼び出す
2. API DestinationがRailwayエンドポイントにHTTP POSTリクエストを送信
3. リクエストボディ: `{"plan_id": 123}`
4. ヘッダー: `X-API-Key: {SCHEDULER_API_KEY}`, `Content-Type: application/json`

### 4. Railwayエンドポイント処理

```python
# app/api/routers/scheduler.py
@router.post("/silent-notification")
async def trigger_silent_notification(request: SchedulerRequest, ...):
    # 1. API Key検証
    # 2. Planとparticipantsを取得
    # 3. 各participantにサイレント通知を送信
```

## トラブルシューティング

### API Destinationが作成されない

```bash
# AWS CLIで確認
aws events describe-api-destination \
  --name puctee-railway-api-destination \
  --region ap-northeast-1
```

### スケジュールが実行されない

```bash
# スケジュール詳細を確認
aws scheduler get-schedule \
  --name puctee-plan-silent-{PLAN_ID} \
  --group-name default \
  --region ap-northeast-1
```

### エンドポイントにリクエストが届かない

1. CloudWatch Logsでエラーを確認
2. Railway logsでリクエストログを確認
3. API Destinationのエンドポイント設定を確認

```bash
# Railway logs
railway logs
```

### IAM権限エラー

IAM Roleに`events:InvokeApiDestination`権限があることを確認：

```bash
aws iam get-role-policy \
  --role-name puctee-scheduler-http-role \
  --policy-name EventBridgeSchedulerPolicy
```

## ログ確認

### Backend側（Railway）

```python
logger.info(f"[SCHEDULER] Received scheduled silent notification request for plan {request.plan_id}")
```

### EventBridge側（CloudWatch）

EventBridge Schedulerの実行ログはCloudWatch Logsに記録されます：
- Log Group: `/aws/events/scheduler/default`

## セキュリティ

1. **API Key認証**: `SCHEDULER_API_KEY`を使用してエンドポイントを保護
2. **HTTPS**: RailwayはデフォルトでHTTPSを提供
3. **IAM Role**: 最小権限の原則に従った権限設定

## コスト

- EventBridge Scheduler: 無料枠あり（月100万リクエストまで無料）
- API Destination呼び出し: 無料
- Railway: プランに応じた課金

## 参考リンク

- [EventBridge Scheduler Documentation](https://docs.aws.amazon.com/scheduler/latest/UserGuide/what-is-scheduler.html)
- [EventBridge API Destinations](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-api-destinations.html)
