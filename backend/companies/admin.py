from django.contrib import admin
from .models import Company
from django.utils.html import format_html

@admin.register(Company)
class CompanyAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'name', 'plan_name', 'user_limit_display', 'is_approved', 'requested_by_display', 'created_at'
    )
    list_filter = ('plan', 'is_approved',)
    search_fields = ('name', 'address', 'phone', 'requested_by__email')
    ordering = ('-created_at',)

    fieldsets = (
        (None, {
            'fields': ('name', 'plan', 'custom_user_limit', 'address', 'phone')
        }),
        ('申請情報', {
            'fields': ('is_approved', 'requested_by'),
        }),
        ('メタ情報', {
            'fields': ('created_at',),
        }),
    )
    readonly_fields = ('created_at',)

    def plan_name(self, obj):
        return obj.plan.name if obj.plan else '-'
    plan_name.short_description = 'プラン'

    def user_limit_display(self, obj):
        return obj.user_limit or '未設定'
    user_limit_display.short_description = 'ユーザー上限'

    def requested_by_display(self, obj):
        if obj.requested_by:
            return format_html(
                '<a href="/admin/users/customuser/{}/change/">{}</a>',
                obj.requested_by.id,
                obj.requested_by.email
            )
        return '―'
    requested_by_display.short_description = '申請者'

