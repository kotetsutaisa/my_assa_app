import uuid
from django_ulid.models import ULIDField
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.conf import settings
from .fields import ULIDField 

# チャット内での役割
class ParticipantRole(models.TextChoices):
    OWNER  = "owner",  _("オーナー")
    MEMBER = "member", _("メンバー")
    BOT    = "bot",    _("ボット")


class Conversation(models.Model):

    id = models.UUIDField(
        # 主キー
        primary_key=True,
        # ランダムなUUIDを生成
        default=uuid.uuid4,
        # 人間が手動でIDを入れることを防ぐ
        editable=False,
        help_text=_("URL セーフ & シャーディングしやすい主キー"),
    )

    company = models.ForeignKey(
        "companies.Company",
        # 親が削除されたら全部削除
        on_delete=models.CASCADE,
        related_name="conversations",
        verbose_name=_("会社 (テナント)"),
    )

    title = models.CharField(
        _("タイトル"),
        max_length=50,
        blank=True,
        null=True, #DMでは空にする
    )

    is_group = models.BooleanField(
        _("グループチャット"),
        default=False,
        db_index=True,
    )

    icon = models.ImageField(
        verbose_name=_("アイコン画像"),
        upload_to="chat_icons/",
        null=True,
        blank=True,
        help_text=_("グループチャットのアイコン画像。DMでは通常使わない"),
    )


    created_at = models.DateTimeField(_("作成日時"), auto_now_add=True)
    updated_at = models.DateTimeField(_("更新日時"), auto_now=True)

    def is_dm(self) -> bool:
        return not self.is_group

    def __str__(self) -> str:
        return self.title or ("グループ" if self.is_group else "DM")

    class Meta:
        # 管理画面表示名
        verbose_name = _("チャットルーム")
        verbose_name_plural = _("チャットルーム")
        # ORMの並び順統一
        ordering = ("-updated_at",)
        indexes = [
            # 会社内で最近更新の会話を引くクエリに効く
            models.Index(fields=("company", "-updated_at"), name="chat_recent_idx"),
        ]


# conversationに所属する参加者を表すモデル
class Participant(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_participations",
        verbose_name=_("ユーザー"),
    )

    conversation = models.ForeignKey(
        "chat.Conversation",
        on_delete=models.CASCADE,
        related_name="participants",
        verbose_name=_("会話"),
    )

    role = models.CharField(
        _("役割"),
        max_length=10,
        choices=ParticipantRole.choices,
        default=ParticipantRole.MEMBER,
    )


    joined_at = models.DateTimeField(_("参加日時"), auto_now_add=True)
    left_at   = models.DateTimeField(_("退出日時"), null=True, blank=True)

    # ---------------------------------------------------------------------

    class Meta:
        verbose_name = _("参加者")
        verbose_name_plural = _("参加者")
        ordering = ("conversation", "joined_at")
        
        # DM/グループともに「同じ会話に同じユーザーを重複登録させない」
        constraints = [
            models.UniqueConstraint(
                fields=["conversation", "user"],
                name="unique_participant"
            )
        ]

        indexes = [
            models.Index(fields=("conversation", "user"), name="participant_conv_user_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.user} in {self.conversation}"


# メッセージの中身
class Message(models.Model):

    id = ULIDField(primary_key=True)

    conversation = models.ForeignKey(
        "chat.Conversation",
        on_delete=models.CASCADE,
        related_name="messages",
        verbose_name=_("会話"),
    )

    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,           # Bot 送信時は NULL を許容
        blank=True,
        related_name="sent_messages",
        verbose_name=_("送信者"),
    )

    replied_to = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="replies",
        verbose_name=_("返信先メッセージ"),
    )

    class Kind(models.TextChoices):
        TEXT   = "text",   _("テキスト")
        FILE   = "file",   _("ファイル")
        SYSTEM = "system", _("システム通知")

    kind = models.CharField(
        _("種別"),
        max_length=10,
        choices=Kind.choices,
        default=Kind.TEXT,
        db_index=True,
    )

    body = models.JSONField(
        _("本文／メタ情報"),
        help_text=_("テキスト本体やファイルメタを JSON で保持"),
    )

    created_at = models.DateTimeField(_("作成日時"), auto_now_add=True)
    edited_at  = models.DateTimeField(_("編集日時"), null=True, blank=True)
    deleted_at = models.DateTimeField(_("削除日時"), null=True, blank=True)

    class Meta:
        verbose_name = _("メッセージ")
        verbose_name_plural = _("メッセージ")
        ordering = ("-created_at",)                       # 新しい順
        indexes = [
            models.Index(fields=("conversation", "-created_at"), name="msg_conv_time_idx"),
        ]

    def __str__(self) -> str:
        preview = (self.body or "")[:30] if isinstance(self.body, str) else str(self.body)[:30]
        return f"{self.get_kind_display()}: {preview}"



# 既読未読テーブル
class MessageRead(models.Model):
    message = models.ForeignKey(
        "chat.Message",
        on_delete=models.CASCADE,
        related_name="read_by",
        verbose_name=_("メッセージ"),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="message_reads",
        verbose_name=_("ユーザー"),
    )

    read_at = models.DateTimeField(
        _("既読時刻"),
        auto_now_add=True,       # 最初に読んだ瞬間を自動で記録
    )

    class Meta:
        verbose_name = _("既読情報")
        verbose_name_plural = _("既読情報")
        ordering = ("-read_at",)

        constraints = [
            models.UniqueConstraint(
                fields=["message", "user"],
                name="unique_read_per_user"
            )
        ]

        indexes = [
            models.Index(fields=("message", "user"), name="msgread_msg_user_idx"),
            models.Index(fields=("user", "message"), name="msgread_user_msg_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.user} read {self.message} at {self.read_at:%Y-%m-%d %H:%M:%S}"
    

# --- グループチャット招待テーブル ---
class InvitationConversation(models.Model):
    conversation = models.ForeignKey(
        "chat.Conversation",
        on_delete=models.CASCADE,
        related_name="invitations",
        verbose_name=_("会話"),
    )

    invited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_invitations",
        verbose_name=_("招待したユーザー"),
    )

    invitee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="group_chat_invitations",
        verbose_name=_("招待されたユーザー"),
    )

    invited_at = models.DateTimeField(
        _("招待時刻"),
        auto_now_add=True
    )

    is_participated = models.BooleanField(
        _("参加済み"),
        default=False
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["conversation", "invitee"],
                name="unique_invitation_per_conversation"
            )
        ]

    def __str__(self):
        return f"{self.invited_by.username} → {self.invitee.username} @ {self.conversation.title or 'DM'}"
