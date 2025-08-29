# reports/urls.py
from django.urls import path
from .views import (
    PersonalReportListCreateAPIView,
    PersonalReportDetailAPIView,
    TeamReportListCreateAPIView,
    TeamReportDetailAPIView,
    TeamReportGeneratePersonalAPIView,
    PersonalReportApproveAPIView,
    PersonalReportRejectAPIView,
    ClosingPreviewAPIView,
    ClosingRunAPIView
)

urlpatterns = [
    # 個人日報
    path("personal/", PersonalReportListCreateAPIView.as_view(), name="personal-report-list-create"),
    path("personal/<uuid:pk>/", PersonalReportDetailAPIView.as_view(), name="personal-report-detail"),
    path("reports/personal/<uuid:pk>/approve/", PersonalReportApproveAPIView.as_view()),
    path("reports/personal/<uuid:pk>/reject/",  PersonalReportRejectAPIView.as_view()),

    # チーム日報
    path("team/", TeamReportListCreateAPIView.as_view(), name="team-report-list-create"),
    path("team/<uuid:pk>/", TeamReportDetailAPIView.as_view(), name="team-report-detail"),

    # チーム日報 → 個人日報の下書き一括生成
    path("team/generate-personal/", TeamReportGeneratePersonalAPIView.as_view(),
         name="team-report-generate-personal"),

    path("closing/preview/", ClosingPreviewAPIView.as_view(), name="reports-closing-preview"),
    path("closing/run/",     ClosingRunAPIView.as_view(),     name="reports-closing-run"),
]


