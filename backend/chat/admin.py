from django.contrib import admin
from .models import Conversation, Participant, Message, MessageRead

admin.site.register(Conversation)
admin.site.register(Participant)
admin.site.register(Message)
admin.site.register(MessageRead)
