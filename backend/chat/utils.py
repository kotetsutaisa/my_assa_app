# chat/utils.py
import ulid
from typing import List
from django_redis import get_redis_connection

def generate_ulid():
    return str(ulid.new())


# WebSocket接続中かの判定(個人)
def is_user_online(user_id: int, conversation_id: str) -> bool:
    redis_conn = get_redis_connection('default')
    
    is_online = redis_conn.exists(f"online_user:{user_id}") == 1
    current_chat = redis_conn.get(f"chat_open:{user_id}")

    if not is_online or current_chat is None:
        return False
    
    return current_chat.decode() == str(conversation_id)


# WebSocket接続中かの判定(グループ)
def get_online_users_in_conversation(user_ids: List[int], conversation_id: str) -> List[int]:
    redis_conn = get_redis_connection('default')
    online_user_ids = []

    for user_id in user_ids:
        is_online = redis_conn.exists(f"online_user:{user_id}") == 1
        current_chat = redis_conn.get(f"chat_open:{user_id}")

        if not is_online or current_chat is None:
            continue

        if current_chat.decode() == str(conversation_id):
            online_user_ids.append(user_id)

    return online_user_ids