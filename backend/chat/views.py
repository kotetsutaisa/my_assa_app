import json
from .models import Conversation, Message, MessageRead, InvitationConversation, Participant
from .serializers import ConversationSerializer, ParticipantSerializer, MessageSerializer, InvitationConversationSerializer, ConversationWrapperSerializer, InvitationUpdateSerializer, CandidateUserSerializer
from .utils import is_user_online, get_online_users_in_conversation
from timeline.permissions import IsCompanyMember
from users.serializers import SimpleUserSerializer

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, CreateAPIView, ListAPIView, GenericAPIView
from rest_framework.mixins import UpdateModelMixin
from rest_framework.serializers import ValidationError
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Subquery, OuterRef
from django.utils import timezone
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.shortcuts import get_object_or_404


User = get_user_model()

# --- conversation作成 ---
class ConversationCreateAPIView(CreateAPIView):

    serializer_class = ConversationSerializer
    permission_classes = [IsCompanyMember]

    def create(self, request, *args, **kwargs):
        self.instance = None  # ← 明示的に初期化
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # 明示的にインスタンス取得
        conversation_instance = self.instance or serializer.instance
        if conversation_instance is None:
            return Response({'detail': 'Conversation instance could not be resolved.'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        response_serializer = self.get_serializer(instance=conversation_instance)
        return Response(response_serializer.data, status=status.HTTP_200_OK)

    
    def perform_create(self, serializer):
        
        request = self.request
        data = request.data
        partner_id = data.get('partner')

        if not serializer.validated_data.get("is_group", False) and not partner_id:
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
            # 自分が以前抜けた場合は left_at をリセット
            participant = Participant.objects.filter(
                user=request.user, conversation=existing
            ).first()

            if participant and participant.left_at:
                participant.left_at = None
                participant.save()
                
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
                context={"request": request, "conversation": conversation}
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
                context={
                    "request": request,
                    "conversation": conversation,
                    "user": partner_user,
                }
            )

            is_valid = partner_participant_serializer.is_valid(raise_exception=True)
            partner_participant_serializer.save()


# --- conversationとinvitationを結合した一覧取得 ---
class ConversationListAPIView(ListAPIView):
    serializer_class = ConversationWrapperSerializer
    permission_classes = [IsCompanyMember,]

    def list(self, request, *args, **kwargs):
        user = request.user
        company = user.company

        # --- 最新メッセージの定義 ---
        latest_message = (
            Message.objects
            .filter(conversation=OuterRef('pk'))
            .order_by('-created_at')
        )

        # --- 自分が参加している会話 ---
        conversations = (
            Conversation.objects
                .filter(company=company, participants__user=user, participants__left_at__isnull=True)
                .select_related('company')
                .prefetch_related('participants__user')
                .annotate(
                    last_message_content=Subquery(latest_message.values('body')[:1]),
                    last_message_created_at=Subquery(latest_message.values('created_at')[:1]),
                )
        )

        # 招待されているグループチャット
        invitations = (
            InvitationConversation.objects
                .filter(invitee=user, is_participated=False)
                .select_related('conversation', 'invited_by')
        )

        result = []

        for conv in conversations:
            result.append({
                'conversation': conv,
                'is_invited': False,
                'invited_by': None,
            })

        for invite in invitations:
            result.append({
                'conversation': invite.conversation,
                'is_invited': True,
                'invited_by': invite.invited_by,
            })

        result.sort(
            key=lambda item: (
                getattr(item["conversation"], 'last_message_created_at', None)
                or item["conversation"].updated_at
            ),
            reverse=True
        )

        serializer = ConversationWrapperSerializer(result, many=True, context={'request':request})
        return Response(serializer.data)
    

# conversation退出API
class LeaveConversationAPIView(APIView):
    permission_classes = [IsCompanyMember]

    def patch(self, request, *args, **kwargs):
        user = request.user
        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        try:
            participant = Participant.objects.get(
                user=user,
                conversation=conversation,
                left_at__isnull=True
            )
        except Participant.DoesNotExist:
            return Response({"detail": "会話に参加していません"}, status=status.HTTP_404_NOT_FOUND)
        
        participant.left_at = timezone.now()
        participant.save()

        return Response({"detail": "会話を退出しました"}, status=status.HTTP_200_OK)


# グループ招待から参加するためのparticipant作成API
class ParticipantAPIView(GenericAPIView):
    serializer_class = ParticipantSerializer
    permission_classes = [IsCompanyMember,]

    def get(self, request, *args, **kwargs):
        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        participants = conversation.participants.select_related('user').all()
        users = [p.user for p in participants]

        # request.user を一番前に並び替える
        users.sort(key=lambda u: 0 if u.id == request.user.id else 1)

        serializer = SimpleUserSerializer(users, many=True)
        return Response(serializer.data)

    def post(self, request, *args, **kwargs):
        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        serializer = self.get_serializer(
            data=request.data,
            context={
                'request': request,
                'conversation': conversation,
            }
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        Message.objects.create(
            conversation=conversation,
            sender=request.user,
            kind='system',
            body = {"text": f"{request.user.username}さんが参加しました"}
        )

        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    def delete(self, request, *args, **kwargs):
        user = request.user
        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        participant = get_object_or_404(
            Participant,
            conversation=conversation,
            user=user,
        )

        participant.delete()

        # システムメッセージとしてログに残す（任意）
        Message.objects.create(
            conversation=conversation,
            sender=user,
            kind='system',
            body={'text': f"{user.username}さんがグループを退会しました"}
        )

        # 参加者がいないくなればconversationも削除
        if not conversation.participants.exists():
            conversation.delete()

        return Response(
            {"detail": "グループを退会しました"},
            status=status.HTTP_204_NO_CONTENT
        )

        


class MessageListCreateAPIView(ListCreateAPIView):

    serializer_class = MessageSerializer
    permission_classes = [IsCompanyMember,]

    def get_queryset(self):
        conversation_id = self.kwargs.get("conversation_id")
        user = self.request.user

        participant = Participant.objects.filter(
            user=user,
            conversation_id=conversation_id,
        ).first()

        if not participant:
            return Message.objects.none()

        return (
            Message.objects
            .filter(
                conversation_id=conversation_id,
                created_at__gte=participant.joined_at  # ← ここがポイント
            )
            .select_related('sender')
            .order_by('created_at')
        )

    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['conversation_id'] = self.kwargs['conversation_id']
        return context
    
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        conversation_id = self.kwargs.get('conversation_id')
        user = request.user

        conversation = Conversation.objects.get(id=conversation_id)
        partner = conversation.participants.exclude(user=user).first()

        # --- WebSocket ---
        if partner:
            for message in queryset:
                if message.sender == user:
                    continue

                is_read = MessageRead.objects.filter(message=message, user=user).exists()
                if not is_read:
                    MessageRead.objects.get_or_create(
                        message=message,
                        user=user,
                    )
                
                partner_online = is_user_online(partner.user.id, str(conversation.id))
                if partner_online:
                    channel_layer = get_channel_layer()
                    async_to_sync(channel_layer.group_send)(
                        f"chat_{conversation.id}",
                        {
                            "type": "chat.read",
                            "message_id": str(message.id),
                            "reader_id": user.id,
                        }
                    )

        serializer = self.get_serializer(
            queryset,
            many=True,
            context={'request': request, 'conversation_id': self.kwargs['conversation_id']},
        )
        return Response(serializer.data)

        
    def perform_create(self, serializer):
        user = self.request.user
        conversation_id = self.kwargs['conversation_id']
        conversation = get_object_or_404(Conversation, id=conversation_id)

        # グループチャット
        if conversation.is_group:
            group_partners = conversation.participants.exclude(user=user)
            for group_partner in group_partners:
                # チャットを削除しているユーザーがいれば復帰させる
                if group_partner.left_at:
                    group_partner.left_at = None
                    group_partner.joined_at = timezone.now()
                    group_partner.save()

            message = serializer.save()

            if group_partners:
                user_ids = []
                for group_partner in group_partners:
                    partner_id = group_partner.user.id
                    user_ids.append(partner_id)
                    partner_online = is_user_online(partner_id, str(conversation.id))

                    if partner_online:
                        MessageRead.objects.get_or_create(
                            message=message,
                            user=partner.user,
                        )

                # グループチャットのオンラインユーザーリスト(ID)
                users_online = get_online_users_in_conversation(user_ids, conversation_id)
                # 一人でもオンラインのユーザーがいればWebSocketでメッセージを通知
                if users_online:
                    channel_layer = get_channel_layer()
                    safe_message = json.loads(
                        json.dumps(MessageSerializer(message, context={"request": self.request}).data, default=str)
                    )
                    async_to_sync(channel_layer.group_send)(
                        f"chat_{conversation.id}",
                        {
                            "type": "chat.message",  # Consumer 内で定義されているメソッド名に対応
                            "message": safe_message # 送るメッセージ内容（シリアライズされた辞書）
                        }
                    )
                    
        # DM
        else:
            partner = conversation.participants.exclude(user=user).first()

            # DM相手がチャットを削除していたら再度復帰させる
            if partner and partner.left_at:
                partner.left_at = None
                partner.joined_at = timezone.now()
                partner.save()

            message = serializer.save()

            if partner:
                partner_id = partner.user.id
                partner_online = is_user_online(partner_id, str(conversation.id))

                if partner_online:
                    MessageRead.objects.get_or_create(
                        message=message,
                        user=partner.user,
                    )

                    channel_layer = get_channel_layer()
                    safe_message = json.loads(
                        json.dumps(MessageSerializer(message, context={"request": self.request}).data, default=str)
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



# --- グループチャット招待処理 ---
class InvitationConversationAPIView(UpdateModelMixin, GenericAPIView):

    permission_classes = [IsCompanyMember]
    def get_serializer_class(self):
        if self.request.method == 'PATCH':
            return InvitationUpdateSerializer
        return InvitationConversationSerializer
    
    # グループに参加していないユーザー一覧取得
    def get(self, request, *args, **kwargs):
        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        # 会社内の全ユーザー
        company_users = User.objects.filter(company=request.user.company)

        # すでに参加済みのユーザー
        joined_user_ids = conversation.participants.values_list('user_id', flat=True)

        # この会話にすでに招待済みのユーザーIDを取得
        invited_user_ids = InvitationConversation.objects.filter(
            conversation=conversation
        ).values_list('invitee_id', flat=True)

        # 未参加のユーザーのみ返す
        candidates = company_users.exclude(id__in=joined_user_ids).order_by('username')

        context = {
            'invited_user_ids': set(invited_user_ids)
        }

        serializer = CandidateUserSerializer(candidates, many=True, context=context)
        return Response(serializer.data)

    # 将来WebSocketに対応させる
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        conversation_id = self.kwargs.get('conversation_id')
        conversation = get_object_or_404(Conversation, id=conversation_id)

        invited_by = request.user
        partner_ids = serializer.validated_data["partners"]

        created = []
        already_invited = []

        for partner_id in partner_ids:
            if InvitationConversation.objects.filter(conversation=conversation, invitee__id=partner_id).exists():
                already_invited.append(partner_id)
                continue

            try:
                invitee = User.objects.get(id=partner_id)
            except User.DoesNotExist:
                #後々ログを追加してください
                continue

            if invitee.company != request.user.company:
                raise ValidationError('会社が違います')

            InvitationConversation.objects.create(
                conversation=conversation,
                invited_by=invited_by,
                invitee=invitee,
            )
            created.append(partner_id)

            if created:
                Message.objects.create(
                    conversation=conversation,
                    sender=invited_by,
                    kind='system',
                    body={'text': f"{invited_by.username}さんが{invitee.username}さんを招待しました"}
                )

        return Response({
            "created": created,
            "already_invited": already_invited
        }, status=status.HTTP_201_CREATED)
    

    def patch(self, request, *args, **kwargs):
        conversation_id = self.kwargs.get('conversation_id')
        invitation = get_object_or_404(
            InvitationConversation,
            conversation__id=conversation_id,
            invitee=request.user
        )

        serializer = self.get_serializer(invitation, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, *args, **kwargs):
        conversation_id = self.kwargs.get('conversation_id')
        user = request.user
        conversation = get_object_or_404(Conversation, id=conversation_id)

        #対象となるユーザーが存在するか確認
        invitation = get_object_or_404(
            InvitationConversation,
            conversation=conversation,
            invitee=user
        )

        invitation.delete()

        Message.objects.create(
            conversation=conversation,
            sender=user,
            kind='system',
            body={'text': f"{user.username}さんが招待を辞退しました"}
        )

        # 参加者がいないくなればconversationも削除
        if not conversation.participants.exists():
            conversation.delete()
        

        return Response(
            {"detail": "招待を辞退しました。"},
            status=status.HTTP_204_NO_CONTENT
        )