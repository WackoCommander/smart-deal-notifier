import boto3

sns = boto3.client('sns')

def send_alert(deal, topic_arn):
    """
    Send an email or SMS alert via SNS when a relevant deal is found.
    """
    sns.publish(
        TopicArn=topic_arn,
        Subject="🔥 New Deal Alert!",
        Message=f"{deal['title']} for ${deal['price']}!\n{deal['url']}"
    )

