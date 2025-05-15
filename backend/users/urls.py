from django.urls import path
from .views import CustomTokenObtainPairView
from rest_framework_simplejwt.views import TokenRefreshView
from .views import CustomTokenObtainPairView, UserRegisterView
from .views import GetCurrentUser, CustomTokenRefreshView, UpdateCurrentUser

urlpatterns = [
    path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('register/', UserRegisterView.as_view(), name='user_register'),
    path('token/refresh/', CustomTokenRefreshView.as_view(), name='token_refresh'),
    path('current/', GetCurrentUser.as_view(), name='get-current-user'),
    path('current/update/', UpdateCurrentUser.as_view(), name='update-current-user'),
]