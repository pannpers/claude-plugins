---
tags: [skill-creator]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

PR の説明に貼るので、ログインの流れを Mermaid の sequenceDiagram で書いて sequence.md に保存して。登場するのはユーザー (ブラウザ)、フロントエンド、Zitadel、API サーバー、PostgreSQL。ブラウザで Zitadel にリダイレクト → 認可コードを受け取る → フロントエンドがトークンと交換 → API にトークン付きでリクエスト → API が JWKS で検証して users テーブルを読む。
