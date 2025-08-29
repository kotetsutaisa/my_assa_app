from rest_framework.permissions import BasePermission


class IsAdminOrClerk(BasePermission):
    """
    事務モードAPIは admin / clerk（+superuser/staff）だけ許可
    """
    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated):
            return False
        role = getattr(user, "role", None)
        if getattr(user, "is_superuser", False) or getattr(user, "is_staff", False):
            return True
        return str(role) in ("admin", "clerk")
