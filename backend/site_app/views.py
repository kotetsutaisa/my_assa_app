from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from rest_framework.response import Response

from .serializers import SiteSerializer
from .models import Site
from timeline.permissions import IsCompanyMember

from django.shortcuts import get_object_or_404


# 一覧 & 作成
class SiteListCreateAPIView(ListCreateAPIView):
    serializer_class = SiteSerializer
    permission_classes = [IsCompanyMember]

    def get_queryset(self):
        company = self.request.user.company
        return Site.objects.filter(company=company)
    
    def perform_create(self, serializer):
        company = self.request.user.company
        serializer.save(company=company)

# 詳細 & 更新 & 削除
class SiteDetailAPIView(RetrieveUpdateDestroyAPIView):
    serializer_class = SiteSerializer
    permission_classes = [IsCompanyMember]
    lookup_field = 'id'  # UUIDの主キー

    def get_queryset(self):
        return Site.objects.filter(company=self.request.user.company)