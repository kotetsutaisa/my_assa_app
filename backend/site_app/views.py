from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from rest_framework.response import Response

from .serializers import SiteSerializer
from .models import Site
from timeline.permissions import IsCompanyMember

from django.shortcuts import get_object_or_404
from utils.geocode import geocode_address


# 一覧 & 作成
class SiteListCreateAPIView(ListCreateAPIView):
    serializer_class = SiteSerializer
    permission_classes = [IsCompanyMember]

    def get_queryset(self):
        company = self.request.user.company
        return Site.objects.filter(company=company)
    
    def perform_create(self, serializer):
        company = self.request.user.company
        site = serializer.save(company=company)

        if site.address and (not site.latitude or not site.longitude):
            try:
                lat, lng = geocode_address(site.address)
                site.latitude = lat
                site.longitude = lng
                site.save()
            except Exception as e:
                print(f"ジオコーディング失敗: {e}")

# 詳細 & 更新 & 削除
class SiteDetailAPIView(RetrieveUpdateDestroyAPIView):
    serializer_class = SiteSerializer
    permission_classes = [IsCompanyMember]
    lookup_field = 'id'  # UUIDの主キー

    def get_queryset(self):
        return Site.objects.filter(company=self.request.user.company)