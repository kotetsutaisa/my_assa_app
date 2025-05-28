# chat/fields.py
from django.db import models
from chat.utils import generate_ulid


class ULIDField(models.CharField):
    def __init__(self, *args, **kwargs):
        kwargs['max_length'] = 26  # ULIDは26文字
        kwargs['editable'] = False
        kwargs['unique'] = True
        kwargs.setdefault('default', generate_ulid)
        super().__init__(*args, **kwargs)
