from django.urls import path
from .views import ConversationListAPIView, ConversationCreateAPIView, MessageListCreateAPIView, InvitationConversationAPIView, ParticipantAPIView, LeaveConversationAPIView

urlpatterns = [
    path('conversation/', ConversationListAPIView.as_view(), name='conversation-get'),
    path('conversation/create/', ConversationCreateAPIView.as_view(), name='conversation-create'),
    path('conversation/<uuid:conversation_id>/message/', MessageListCreateAPIView.as_view(), name='conversation-message'),
    path('conversation/<uuid:conversation_id>/invite/', InvitationConversationAPIView.as_view(), name='conversation-invite'),
    path('conversation/<uuid:conversation_id>/participant/', ParticipantAPIView.as_view(), name='conversation-participant'),
    path('conversation/<uuid:conversation_id>/delete/', LeaveConversationAPIView.as_view(), name='conversation-delete'),
]
