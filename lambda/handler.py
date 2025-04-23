import os
from scraper import scrape_deals
from relevance import is_relevant
from db_helper import is_seen, mark_seen
from notifier import send_alert

TABLE_NAME = os.environ['TABLE_NAME']
TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    # Step 1: Scrape deals
    deals = scrape_deals()

    # Step 2: Process each deal
    for deal in deals:
        if is_relevant(deal) and not is_seen(deal["id"], TABLE_NAME):
            send_alert(deal, TOPIC_ARN)
            mark_seen(deal["id"], TABLE_NAME)

