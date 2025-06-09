<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=0,2,2,5,30&height=150&section=header&animation=twinkling" />
</div>

<h1 align="center">🏗️ 建設業の“ムダ”を減らす 社内SaaS（Flutter × Django）</h1>

<div align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=24&duration=3000&pause=1200&color=0EF7F1&center=true&vCenter=true&width=800&lines=現場と事務をもっとスマートに;自分で作る+使うSaaSを目指して;仲間も募集中%EF%B8%8F%E2%9C%A8" />
</div>

---

## 💡 背景と目的

> **現場はもっとシンプルに動けるべきだ。**  
> 自社の建設業で感じた「非効率なやり取り」に限界を感じ、  
> **"紙と口頭" を "スマホとチャット" に置き換える社内ツールを**個人で開発しています。

---

## 🧰 技術スタック

<div align="center">
  <img src="https://skillicons.dev/icons?i=flutter,dart,django,python,postgresql,redis,git,github" />
</div>

| カテゴリ       | 使用技術                         |
|----------------|----------------------------------|
| フロントエンド | Flutter, Riverpod, Material UI   |
| バックエンド   | Django REST Framework, Channels |
| 通信           | WebSocket + Redis               |
| DB             | PostgreSQL                      |
| 認証           | JWT（SimpleJWT）                |

---

## 🚀 主な機能

- 💬 チャット（DM / グループ、既読管理、招待機能）
- 📆 スケジュール共有（週単位、タスク表示予定）
- 📝 タイムライン（日報・情報共有）
- 🤖 AIアシスタント（GPT-4連携：予定）
- 👥 グループ作成・メンバー招待・権限管理

---

## 📸 UI（開発中）

| ホーム画面 | スケジュール画面 |
|--------------|------------------|
| <p align="center">
  <img src="./screenshots/home_ui.png" width="350" />
</p> 
| ![schedule_ui](./screenshots/schedule_ui.png) |

※ UIはFlutterで構築中。直感的に使えるUXを追求中です。

---

## 🧪 ローカル開発・セットアップ

```bash
# フロントエンド
cd frontend
flutter pub get
flutter run

# バックエンド
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py runserver
