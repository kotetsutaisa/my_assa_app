from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser  # ← モデル名が違う場合は合わせてね

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser

    # 管理画面で表示されるフィールド
    list_display = ('id', 'email', 'username', 'account_id', 'is_active', 'is_staff')

    # 検索対象
    search_fields = ('email', 'username', 'account_id')

    # フォームで表示されるフィールドグループ
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('個人情報', {'fields': ('username', 'account_id', 'bio', 'iconimg', 'company')}),
        ('パーミッション', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('ログイン履歴', {'fields': ('last_login', 'date_joined')}),
    )

    # ユーザー追加時のフィールド設定
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'username', 'account_id', 'is_staff', 'is_active'),
        }),
    )

