from rest_framework import serializers
from .models import Conversation, Participant, Message, MessageRead, InvitationConversation
from users.serializers import SimpleUserSerializer


class ConversationSerializer(serializers.ModelSerializer):
    icon = serializers.ImageField(required=False, allow_null=True)
    partner_user = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ('id', 'company', 'title', 'is_group', 'icon','created_at', 'updated_at', 'partner_user', 'last_message')
        read_only_fields = ('id', 'company', 'created_at', 'updated_at')

    # ----------------- バリデーション -----------------

    def validate(self, data):
        # グループならtitle必須、DMならtitleは無視してOK
        is_group = data.get(
            "is_group",
            self.instance.is_group if self.instance else False
        )

        title = data.get("title") or (self.instance.title if self.instance else None)

        if is_group and not title:
            raise serializers.ValidationError({"title": "グループチャットではタイトルを入力してください"})

        return data


    def validate_title(self, value):
        if value and len(value) > 50:
            raise serializers.ValidationError("タイトルは50文字以内で入力してください")
        return value

    # ----------------- create / update -----------------

    def create(self, validated_data):

        request = self.context["request"]
        validated_data["company"] = request.user.company

        return super().create(validated_data)

    def update(self, instance, validated_data):
        if not instance.is_group and validated_data.get("is_group", False):
            raise serializers.ValidationError("DM をグループチャットに変更することはできません。")

        return super().update(instance, validated_data)
    
    def get_partner_user(self, obj):
        is_group = obj.get('is_group') if isinstance(obj, dict) else obj.is_group
        # グループなら相手ユーザーは不要
        if is_group:
            return None
        
        request = self.context.get('request')
        me = request.user if request else None

        if isinstance(obj, dict):
            return None

        # 自分以外の参加者を取得
        partner = obj.participants.exclude(user=me).first()
        if partner:
            return SimpleUserSerializer(partner.user, context=self.context).data
        return None
    
    def get_last_message(self, obj):
        body = getattr(obj, 'last_message_content', None)
        if isinstance(body, dict):
            body = body.get("text")  # ✅ 'text' フィールドを抽出
        return {
            "content": body,
            "created_at": getattr(obj, 'last_message_created_at', None),
        }

    

# --- 招待と通常ルームを結合 ---
class ConversationWrapperSerializer(serializers.Serializer):
    conversation = ConversationSerializer()
    is_invited = serializers.BooleanField()
    invited_by = SimpleUserSerializer(required=False)

    class Meta:
        fields = ['conversation', 'is_invited', 'invited_by']



class ParticipantSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    conversation = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Participant
        fields = ('user', 'conversation', 'role')

    def validate(self, data):

        request_user = self.context['request'].user
        user = self.context.get('user', request_user)
        conversation = self.context['conversation']
        
        # 同じユーザーがすでに参加していないか
        if Participant.objects.filter(user=user, conversation=conversation, left_at__isnull=True).exists():
            raise serializers.ValidationError({"user": "このチャットにすでに参加しています"})

        # 会社とユーザーの会社が一致しているか
        if user.company != conversation.company:
            raise serializers.ValidationError({"user": "会社が一致していません"})
        
        # DMの場合は2人まで
        member_count = Participant.objects.filter(conversation=conversation, left_at__isnull=True).count()
        if not conversation.is_group and member_count >= 2:
            raise serializers.ValidationError({"conversation": "DMには2人しか参加できません"})
    
        return data
    
    def create(self, validated_data):
        request = self.context['request']
        conversation = self.context['conversation']

        validated_data['conversation'] = conversation
        validated_data['user'] = self.context.get('user', request.user)
        return super().create(validated_data)
    

    

class MessageSerializer(serializers.ModelSerializer):

    sender = SimpleUserSerializer(read_only=True)
    is_read = serializers.SerializerMethodField()
    read_users = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ('id', 'conversation', 'sender', 'kind', 'body', 'created_at', 'is_read', 'read_users')
        read_only_fields = ('id', 'sender', 'created_at')

    def get_is_read(self, obj):
        user = self.context['request'].user
        partner = obj.conversation.participants.exclude(user=user).first()
        if partner is None:
            return False
        return MessageRead.objects.filter(message=obj, user=partner.user).exists()
        
    def get_read_users(self, obj):
        if obj is None:
            return []
        
        return list(
            MessageRead.objects.filter(message=obj).values_list('user__id', flat=True)
        )

    def create(self, validated_data):
        request = self.context['request']
        conversation_id = self.context.get('conversation_id')

        if not conversation_id:
            raise serializers.ValidationError({"conversation": "conversation_id が context にありません"})
        
        try:
            conversation = Conversation.objects.get(id=conversation_id)
        except Conversation.DoesNotExist:
            raise serializers.ValidationError({"conversation": "指定された会話が存在しません"})

        validated_data['conversation'] = conversation
        validated_data["sender"] = request.user

        return super().create(validated_data)
    


class MessageReadSirializer(serializers.ModelSerializer):

    class Meta:
        model = MessageRead
        fields = ('message', 'user', 'read_at')
        read_only_fields = ('message', 'user', 'read_at',)
        

# post用
class InvitationConversationSerializer(serializers.Serializer):
    partners = serializers.ListField(
        child=serializers.IntegerField(),
        allow_empty=False
    )

# patch用
class InvitationUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvitationConversation
        fields = ['is_participated']
