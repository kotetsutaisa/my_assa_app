from django.urls import path
from .views import ConversationAPIView, MessageListCreateAPIView

urlpatterns = [
    path('conversation/', ConversationAPIView.as_view(), name='conversation-get'),
    path('conversation/<uuid:conversation_id>/message/', MessageListCreateAPIView.as_view(), name='conversation-message'),
]
