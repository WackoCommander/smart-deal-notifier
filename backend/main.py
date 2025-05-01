from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from deal_model import Deal
import boto3
from boto3.dynamodb.types import TypeDeserializer
import os

# Load environment
DYNAMO_TABLE = os.getenv('DYNAMO_TABLE', 'deals')
REGION = os.getenv('AWS_REGION', 'ap-southeast-2')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"]
)

dynamodb = boto3.client('dynamodb', region_name=REGION)
sns = boto3.client('sns', region_name=REGION)
deserializer = TypeDeserializer()

def convert_item(raw_item):
    """Convert DynamoDB typed dict to regular dict."""
    return {k: deserializer.deserialize(v) for k, v in raw_item.items()}

@app.get("/deals", response_model=list[Deal])
def get_deals(
    min_voteup: int = Query(None),
    user_notified: bool = Query(None),
    relevance_assessed: bool = Query(None),
):
    filters = []
    values = {}

    if min_voteup is not None:
        filters.append("VoteUp >= :voteup")
        values[":voteup"] = {'N': str(min_voteup)}
    if user_notified is not None:
        filters.append("UserNotified = :notified")
        values[":notified"] = {'BOOL': user_notified}
    if relevance_assessed is not None:
        filters.append("RelevanceAssessed = :rel")
        values[":rel"] = {'BOOL': relevance_assessed}
    
    if filters:
        filter_expr = " AND ".join(filters)
        resp = dynamodb.scan(
            TableName=DYNAMO_TABLE,
            FilterExpression=filter_expr,
            ExpressionAttributeValues=values,
        )
    else:
        resp = dynamodb.scan(TableName=DYNAMO_TABLE)

    return [Deal(**convert_item(item)) for item in resp.get('Items', [])]

@app.post("/notify")
def send_notification(deal: Deal):
    message = f"Deal: {deal.DealName}\nVotes: {deal.VoteUp - deal.VoteDown}\nURL: {deal.DealURL}"
    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=message,
        Subject="New Deal Notification"
    )
    return {"message": "Notification sent", "response": response}