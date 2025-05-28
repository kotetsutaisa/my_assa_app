from urllib.parse import parse_qs
from channels.middleware import BaseMiddleware
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import UntypedToken
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from channels.db import database_sync_to_async
import jwt
from django.conf import settings

User = get_user_model()

@database_sync_to_async
def get_user(user_id):
    try:
        return User.objects.get(id=user_id)
    except User.DoesNotExist:
        return AnonymousUser()

class TokenAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = scope.get("query_string", b"").decode()
        query_params = parse_qs(query_string)
        token = query_params.get("token", [None])[0]

        if token is None:
            scope["user"] = AnonymousUser()
            return await super().__call__(scope, receive, send)

        try:
            validated_token = UntypedToken(token)
            user_id = validated_token["user_id"]
            scope["user"] = await get_user(user_id)
        except (InvalidToken, TokenError, jwt.exceptions.DecodeError):
            scope["user"] = AnonymousUser()

        return await super().__call__(scope, receive, send)
