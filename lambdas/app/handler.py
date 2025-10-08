import os
import json
import logging
import boto3
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")  # set this in Terraform if you want Lambda to publish

# create sns client (Lambda builtin environment includes boto3)
sns_client = boto3.client("sns")

def lambda_handler(event, context):
    """
    Basic Lambda handler for EventBridge events.
    - Logs the received event.
    - If SNS_TOPIC_ARN env var is set, publishes the event to SNS.
    """
    logger.info("Received EventBridge event: %s", json.dumps(event))

    # Example message payload for SNS: keep it JSON and set MessageStructure to json
    message = {
        "source": "eventbridge-lambda",
        "event": event
    }

    if SNS_TOPIC_ARN:
        try:
            resp = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps({"default": json.dumps(message)}),
                MessageStructure="json",
                Subject=f"Event from {context.function_name if context else 'lambda'}"
            )
            logger.info("Published to SNS topic %s, message id: %s", SNS_TOPIC_ARN, resp.get("MessageId"))
        except ClientError as e:
            logger.exception("Failed to publish to SNS: %s", e)
            # decide whether to raise or swallow; here we log and continue
    else:
        logger.info("SNS_TOPIC_ARN not configured — skipping publish")

    # Return a simple success structure
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "processed", "published_to_sns": bool(SNS_TOPIC_ARN)})
    }
