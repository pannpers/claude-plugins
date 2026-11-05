---
tags: [skill-creator]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

README.md に、注文の後処理の流れを Mermaid で図にして追加して。GitHub で表示する。流れ: API サーバーが注文を Cloud SQL (PostgreSQL) に保存 → Pub/Sub の order-created トピックに publish → worker が受け取って在庫を減らし、メール送信 API を呼ぶ。失敗したら dead-letter キューに入る。図は diagram.md というファイルにも保存して。
