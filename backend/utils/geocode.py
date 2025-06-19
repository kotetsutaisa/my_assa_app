import requests
from django.conf import settings

def geocode_address(address: str):
    api_key = settings.GOOGLE_MAPS_API_KEY
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {"address": address, "key": api_key}
    
    response = requests.get(url, params=params)
    if response.status_code != 200:
        raise Exception("Google APIリクエスト失敗")

    data = response.json()
    if data["status"] != "OK":
        raise Exception(f"ジオコーディング失敗: {data['status']}")

    location = data["results"][0]["geometry"]["location"]
    return location["lat"], location["lng"]
