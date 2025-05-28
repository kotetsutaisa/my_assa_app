import json
from .models import Conversation, Message
from .serializers import ConversationSerializer, ParticipantSerializer, MessageSerializer
from .utils import is_user_online
from timeline.permissions import IsCompanyMember

from rest_framework.generics import ListCreateAPIView
from rest_framework.serializers import ValidationError
from django.contrib.auth import get_user_model
from django.db import transaction
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer

User = get_user_model()

class ConversationAPIView(ListCreateAPIView):

    serializer_class = ConversationSerializer
    permission_classes = [IsCompanyMember,]

    def get_queryset(self):
        user = self.request.user
        company = self.request.user.company

        conversation_list = (
            Conversation.objects
                .filter(company=company, participants__user=user)
                .select_related("company")
                .prefetch_related("participants__user")
                .order_by('-updated_at')
        )

        return conversation_list
    
    def perform_create(self, serializer):
        
        request = self.request
        data = request.data
        partner_id = data.get('partner')

        if not serializer.validated_data.get("is_group", False):
            if not partner_id:
                raise ValidationError({"partner": "DM相手が指定されていません"})

            existing = (
                Conversation.objects.filter(
                    is_group=False,
                    company=request.user.company,
                    participants__user__id=request.user.id,
                )
                .filter(participants__user__id=partner_id)
                .distinct()
                .first()
            )

            if existing:
                # すでに会話があるなら、その情報をレスポンスとして返す
                self.instance = existing
                return
            
            with transaction.atomic():
                conversation = serializer.save()

                # 作成者のparticipantを作成
                if conversation.is_group:
                    # グループだったらオーナー
                    participant_data = {
                        "user": request.user.id,
                        "conversation": str(conversation.id),
                        "role": "owner"
                    }
                else:
                    participant_data = {
                    # DMだったらメンバー
                    "user": request.user.id,
                    "conversation": str(conversation.id),
                }

                participant_serializer = ParticipantSerializer(
                    data=participant_data,
                    context={"request": request}
                )

                participant_serializer.is_valid(raise_exception=True)
                participant_serializer.save()

            # DMの場合は相手のoarticipantも作成する
            if not conversation.is_group:
                if not partner_id:
                    raise ValidationError({"partner": "DMの相手が指定されていません"})
                
                try:
                    partner_user = User.objects.get(id=partner_id)
                except User.DoesNotExist:
                    raise ValidationError({"partner": "指定されたユーザーが存在しません"})
                
                if partner_id == request.user.id:
                    raise ValidationError({"partner": "自分自身とはDMできません"})
                
                partner_participant_data = {
                    "user": partner_user.id,
                    "conversation": str(conversation.id),
                }

                partner_participant_serializer = ParticipantSerializer(
                    data=partner_participant_data,
                    context={"request": request}
                )

                partner_participant_serializer.is_valid(raise_exception=True)
                partner_participant_serializer.save()



class MessageListCreateAPIView(ListCreateAPIView):

    serializer_class = MessageSerializer
    permission_classes = [IsCompanyMember,]

    def get_queryset(self):
        conversation_id = self.kwargs.get("conversation_id")
        return (
            Message.objects
            .filter(conversation_id=conversation_id)
            .select_related('sender')
            .order_by('created_at')
        )
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['conversation_id'] = self.kwargs['conversation_id']
        return context
        
    def perform_create(self, serializer):
        message = serializer.save()
        user = self.request.user
        conversation = message.conversation

        # 自分以外の参加者を取得
        partner = conversation.participants.exclude(user=user).first()

        if partner:
            partner_id = partner.user.id
            partner_online = is_user_online(partner_id, str(conversation.id))

            if partner_online:
                channel_layer = get_channel_layer()
                safe_message = json.loads(
                    json.dumps(MessageSerializer(message).data, default=str)
                )
                async_to_sync(channel_layer.group_send)(
                    f"chat_{conversation.id}",
                    {
                        "type": "chat.message",  # Consumer 内で定義されているメソッド名に対応
                        "message": safe_message # 送るメッセージ内容（シリアライズされた辞書）
                    }
                )
        else:
            partner_id = None
            print("パートナーが見つかりませんでした")

