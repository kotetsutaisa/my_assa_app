import os
import django
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
django.setup()                       # ① ここでアプリ登録を完了させる

from chat.middleware import TokenAuthMiddleware  # ② 以降は安全にインポートできる
from chat.routing import websocket_urlpatterns

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": TokenAuthMiddleware(
        URLRouter(websocket_urlpatterns)
    ),
})



