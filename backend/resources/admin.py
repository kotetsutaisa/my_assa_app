from django.contrib import admin
from .models import ResourceCategory, Resource

# モデルを管理画面に登録
admin.site.register(ResourceCategory)
admin.site.register(Resource)