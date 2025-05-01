from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from deal_model import Deal
import boto3
from boto3.dynamodb.types import TypeDeserializer
import os
import logging
from typing import List, Optional
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment
DYNAMO_TABLE = os.getenv('DYNAMO_TABLE', 'deals')
REGION = os.getenv('AWS_REGION', 'ap-southeast-2')

app = FastAPI(title="Smart Deal Notifier API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True, 
    allow_methods=["*"], 
    allow_headers=["*"]
)

# Initialize AWS clients
try:
    dynamodb = boto3.client('dynamodb', region_name=REGION)
    deserializer = TypeDeserializer()
    logger.info(f"Initialized DynamoDB client for region: {REGION}, table: {DYNAMO_TABLE}")
except Exception as e:
    logger.error(f"Failed to initialize AWS clients: {str(e)}")
    raise

def convert_item(raw_item):
    """Convert DynamoDB typed dict to regular dict."""
    try:
        return {k: deserializer.deserialize(v) for k, v in raw_item.items()}
    except Exception as e:
        logger.error(f"Error deserializing DynamoDB item: {str(e)}")
        raise

@app.get("/deals", response_model=List[Deal])
async def get_deals(
    min_voteup: Optional[int] = Query(None, description="Minimum number of upvotes"),
    user_notified: Optional[bool] = Query(None, description="Filter by notification status"),
    relevance_assessed: Optional[bool] = Query(None, description="Filter by relevance assessment status"),
):
    """
    Retrieve deals from DynamoDB with optional filtering.
    """
    try:
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
        
        logger.info(f"Querying DynamoDB table {DYNAMO_TABLE} with filters: {filters}")
        
        if filters:
            filter_expr = " AND ".join(filters)
            resp = dynamodb.scan(
                TableName=DYNAMO_TABLE,
                FilterExpression=filter_expr,
                ExpressionAttributeValues=values,
            )
        else:
            resp = dynamodb.scan(TableName=DYNAMO_TABLE)
        
        items = resp.get('Items', [])
        logger.info(f"Retrieved {len(items)} deals from DynamoDB")
        
        # Convert DynamoDB items to Deal objects
        deals = []
        for item in items:
            try:
                deal_dict = convert_item(item)
                deals.append(Deal(**deal_dict))
            except Exception as e:
                logger.error(f"Failed to process deal item: {str(e)}")
        
        return deals
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']
        logger.error(f"DynamoDB error: {error_code} - {error_message}")
        raise HTTPException(status_code=500, detail=f"Database error: {error_code}")
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "online", "service": "Smart Deal Notifier API"}