from django.contrib import admin
from .models import CompanyPayrollPolicy, WageContract


@admin.register(CompanyPayrollPolicy)
class CompanyPayrollPolicyAdmin(admin.ModelAdmin):
    list_display = ("company", "time_granularity_minutes", "rounding_mode", "overtime_starts_at", "night_starts_at", "updated_at")
    search_fields = ("company__name",)


@admin.register(WageContract)
class WageContractAdmin(admin.ModelAdmin):
    list_display = ("id", "company", "user", "pay_type", "effective_from", "effective_to", "updated_at")
    list_filter  = ("pay_type", "company")
    search_fields = ("user__email", "user__username")

