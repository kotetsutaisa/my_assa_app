from django.contrib import admin
from .models import ClosingPeriod, TeamReport, TeamReportEntry, PersonalReport, PersonalReportEntry

# モデルを管理画面に登録
admin.site.register(ClosingPeriod)
admin.site.register(TeamReport)
admin.site.register(TeamReportEntry)
admin.site.register(PersonalReport)
admin.site.register(PersonalReportEntry)
