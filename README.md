# Smart Deal Notifier

A serverless application to scrape deals from a website, analyze them for relevance, and send alerts if a deal is relevant to the user.

## Components

- **AWS Lambda**: Processes deals and triggers relevant actions.
- **Amazon Comprehend**: Analyzes deal descriptions to determine relevance.
- **Amazon SNS**: Sends alerts when relevant deals are found.
- **Amazon DynamoDB**: Tracks which deals have been seen to avoid duplicate notifications.

## File Structure

- `lambda/`
  - `handler.py`: Main Lambda entry point.
  - `scraper.py`: Web scraping logic.
  - `relevance.py`: Analyzes deal descriptions using AWS Comprehend.
  - `notifier.py`: Sends notifications via SNS.
  - `db_helper.py`: Interacts with DynamoDB to track deals.
  - `requirements.txt`: Python dependencies.
  - `package.sh`: Script to package the Lambda function.

## Deployment

1. Install dependencies:
   ```bash
   pip install -r lambda/requirements.txt

