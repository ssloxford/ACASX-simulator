import requests

headers = {"Content-type": "application/json"}
url = "URL HERE"
data = {"text": "Finished Run!"}
requests.post(url, headers=headers, json=data)