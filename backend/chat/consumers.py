import json
from channels.generic.websocket import AsyncWebsocketConsumer
from django_redis import get_redis_connection

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        # room_id = conversation_id
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'chat_{self.room_id}'

        if self.user.is_authenticated:
            # Redis にオンライン状態を記録（有効期限 5分）
            redis_conn = get_redis_connection('default')
            # 接続中状態
            redis_conn.set(f"online_user:{self.user.id}", "1", ex=300)
            # 特定のチャット画面を開いている状態
            redis_conn.set(f"chat_open:{self.user.id}", self.room_id, ex=300)

        # グループに参加
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        await self.accept()
        print("WebSocketに接続開始")

    async def disconnect(self, close_code):
        if self.user.is_authenticated:
            # Redis から削除
            redis_conn = get_redis_connection('default')
            redis_conn.delete(f"online_user:{self.user.id}")
            redis_conn.delete(f"chat_open:{self.user.id}")

        # グループから離脱
        await self.channel_layer.group_discard(
            self.room_group_name,
            self.channel_name
        )

    async def chat_message(self, event):
        print("✅ 全体送信: ", event['message'])
        message = event['message']

        await self.send(text_data=json.dumps(message))
