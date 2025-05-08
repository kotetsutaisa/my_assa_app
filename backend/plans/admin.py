from django.contrib import admin
from .models import Plan

@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'price_display', 'user_limit', 'created_at')
    search_fields = ('name',)
    ordering = ('price',)
    readonly_fields = ('created_at',)

    fieldsets = (
        (None, {
            'fields': ('name', 'price', 'user_limit', 'description')
        }),
        ('メタ情報', {
            'fields': ('created_at',),
        }),
    )

    def price_display(self, obj):
        return f"¥{obj.price:,}"  # 例: ¥10,000
    price_display.short_description = '月額料金'
