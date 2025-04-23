import boto3

# Initialize Comprehend client
comprehend = boto3.client('comprehend')

def is_relevant(deal):
    """
    Use AWS Comprehend to analyze the deal description and check relevance.
    Returns True if relevant, False otherwise.
    """
    response = comprehend.detect_entities(
        Text=deal["description"],
        LanguageCode="en"
    )

    # Define a list of relevant entities/keywords
    relevant_keywords = ["MacBook", "laptop", "smartphone", "discount", "sale", "offer"]

    # Check if detected entities match any of the relevant keywords
    for entity in response['Entities']:
        if entity['Text'].lower() in relevant_keywords:
            print(f"Relevant entity found: {entity['Text']}")
            return True  # Return True if any relevant entity is found
    return False

