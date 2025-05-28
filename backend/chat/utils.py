# chat/utils.py
import ulid
from django_redis import get_redis_connection

def generate_ulid():
    return str(ulid.new())


# WebSocket接続中かの判定
def is_user_online(user_id: int, conversation_id: str) -> bool:
    redis_conn = get_redis_connection('default')
    
    is_online = redis_conn.exists(f"online_user:{user_id}") == 1
    current_chat = redis_conn.get(f"chat_open:{user_id}")

    if not is_online or current_chat is None:
        return False
    
    return current_chat.decode() == str(conversation_id)