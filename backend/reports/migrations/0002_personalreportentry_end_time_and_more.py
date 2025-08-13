# reports/migrations/0002_personalreportentry_end_time_and_more.py
from django.db import migrations, models
import datetime  # ← これを追加

class Migration(migrations.Migration):

    dependencies = [
        ('reports', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='personalreportentry',
            name='start_time',
            field=models.TimeField(default=datetime.time(0, 0), verbose_name='開始時刻'),
            preserve_default=False,  # ← 既存埋めのみ。モデルのデフォルトには残さない
        ),
        migrations.AddField(
            model_name='personalreportentry',
            name='end_time',
            field=models.TimeField(default=datetime.time(0, 0), verbose_name='終了時刻'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='teamreportentry',
            name='start_time',
            field=models.TimeField(default=datetime.time(0, 0), verbose_name='開始時刻'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='teamreportentry',
            name='end_time',
            field=models.TimeField(default=datetime.time(0, 0), verbose_name='終了時刻'),
            preserve_default=False,
        ),
    ]
