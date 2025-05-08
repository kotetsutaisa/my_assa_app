from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser

    # 一覧表示フィールド
    list_display = (
        'id', 'email', 'username', 'account_id',
        'role', 'company', 'is_active', 'is_staff',
        'icon_preview',
    )
    list_select_related = ('company',)  # companyでクエリ効率化
    list_filter = ('role', 'is_active', 'is_staff')
    search_fields = ('email', 'username', 'account_id')

    # フィールド構成（編集画面）
    fieldsets = (
        (None, {
            'fields': ('email', 'password')
        }),
        ('基本情報', {
            'fields': ('username', 'account_id', 'bio', 'iconimg', 'role', 'company')
        }),
        ('権限', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('ログイン履歴', {
            'fields': ('last_login', 'date_joined')
        }),
    )

    # ユーザー追加フォーム用
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'email', 'password1', 'password2',
                'username', 'account_id', 'role', 'company',
                'is_active', 'is_staff'
            ),
        }),
    )

    # 読み取り専用フィールド
    readonly_fields = ('icon_preview',)

    # サムネイル表示（アイコン画像）
    def icon_preview(self, obj):
        if obj.iconimg:
            return format_html('<img src="{}" width="40" style="border-radius:50%;" />', obj.iconimg.url)
        return '（なし）'

    icon_preview.short_description = 'アイコン'


