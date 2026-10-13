"""Demo sin efectos externos: fallo por registro, sin registrar payloads."""
import json
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event, context):
    failures = []
    for record in event["Records"]:
        try:
            payload = json.loads(record["body"])
            if not isinstance(payload, dict) or payload.get("fail") is True:
                raise ValueError("invalid job")
            logger.info("job_processed message_id=%s", record["messageId"])
        except (ValueError, TypeError):
            failures.append({"itemIdentifier": record["messageId"]})
            logger.warning("job_rejected message_id=%s", record["messageId"])
    return {"batchItemFailures": failures}
