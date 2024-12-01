import os
import json
from locust import HttpUser, task, between
from dotenv import load_dotenv

load_dotenv('./variables.env')

class MyUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        self.api_key = os.environ['API_KEY']

    @task
    def call_api(self):
        self.host = os.environ['API_ENDPOINT']
        headers = {
            "api-key": self.api_key,
            "Content-Type": "application/json"
        }
        payload = {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "Tell me a joke."}
            ],
            "max_tokens": 300
        }
        self.client.post(f"openai/deployments/gpt-4o-mini/chat/completions/?api-version={os.environ['API_VERSION']}", 
                         headers=headers,
                         data=json.dumps(payload)
                         )
