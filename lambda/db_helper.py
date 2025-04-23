import boto3

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')

def is_seen(deal_id, table_name):
    """
    Check if the deal has already been alerted by querying DynamoDB.
    """
    table = dynamodb.Table(table_name)
    resp = table.get_item(Key={"deal_id": deal_id})
    return "Item" in resp

def mark_seen(deal_id, table_name):
    """
    Mark the deal as seen in DynamoDB to avoid duplicate alerts.
    """
    table = dynamodb.Table(table_name)
    table.put_item(Item={"deal_id": deal_id})

