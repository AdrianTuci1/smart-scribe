# AWS Setup for VoiceScribe

## 1. DynamoDB Tables
Create two tables in `eu-central-1`:
1. **Name**: `NotesTable`
   - **PK**: `userId` (String)
   - **SK**: `noteId` (String)
2. **Name**: `UserConfigsTable`
   - **PK**: `userId` (String)
   - **SK**: `configType` (String)

## 2. Cognito User Pool
1. Create User Pool in `eu-central-1`.
2. Create App Client (generate Client ID).
3. (Optional) Configure Hosted UI or Domain.

## 3. IAM Roles
Create a Task Role for ECS Fargate:
- Allow `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:Query` on `NotesTable` and `UserConfigsTable`.
- Allow `bedrock:InvokeModel` on `anthropic.claude-3-haiku-20240307-v1:0`.
- Allow `transcribe:StartStreamTranscriptionWebSocket`.

## 3. IAM Policies
### Transcribe Streaming Policy
Attach this policy to the user/role used by the backend:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TranscribeStreaming",
            "Effect": "Allow",
            "Action": "transcribe:StartStreamTranscriptionWebSocket",
            "Resource": "*"
        }
    ]
}
```

### Bedrock Policy
Attach this policy to allow invoking models:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BedrockInvoke",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream"
            ],
            "Resource": [
                "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
            ]
        }
    ]
}
```

## 4. ECS Fargate
1. Create Cluster `Phoenix`.
2. Create ECR Repository `elixir_voicescribe_backend`.
3. Push Docker image.
4. Create Service + Task Definition mapping port 4000.
5. Setup ALB with HTTPS listener forwarding to Target Group (HTTP 4000).

## 5. Environment Variables (Task Def)
- `PHX_HOST`: your-alb-dns.com
- `SECRET_KEY_BASE`: (generate with `mix phx.gen.secret`)
- `AWS_REGION`: `eu-central-1`
