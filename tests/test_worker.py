import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[1] / "templates/02-aws-async/app/worker.py"
spec = importlib.util.spec_from_file_location("worker", path)
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)


class WorkerTests(unittest.TestCase):
    def test_partial_failure_does_not_retry_successful_records(self):
        event = {"Records": [
            {"messageId": "ok", "body": '{"job":"demo"}'},
            {"messageId": "bad", "body": "not-json"},
            {"messageId": "retry", "body": '{"fail":true}'},
            {"messageId": "wrong-shape", "body": "[]"},
        ]}
        self.assertEqual(worker.handler(event, None), {"batchItemFailures": [
            {"itemIdentifier": "bad"}, {"itemIdentifier": "retry"},
            {"itemIdentifier": "wrong-shape"},
        ]})

    def test_empty_batch(self):
        self.assertEqual(worker.handler({"Records": []}, None), {"batchItemFailures": []})
