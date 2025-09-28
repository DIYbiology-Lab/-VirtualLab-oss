# VirtualLab-oss — Offline stack for Virtual Lab × gpt-oss@vLLM

ローカル GPU（例: RTX 4080 SUPER 16 GB）で **gpt-oss** を **vLLM の OpenAI 互換 API** として提供し、**Virtual Lab** から利用するための Docker 構成です。  
- プロファイル切替: **runtime**（初回DL） / **bundled**（重み同梱・完全オフライン）  
- モデル: `openai/gpt-oss-20b`（既定）/ `openai/gpt-oss-120b`（高VRAM向け）

> 参考: README/Markdown 基本作法（見出し・目次生成などは GitHub が自動対応）。  
> See: GitHub Docs “About READMEs” / “Basic writing and formatting”. 

## Requirements
- Windows 11 + WSL2 (Ubuntu 24.04) + Docker Desktop (WSL2 backend, GPU 有効)
- VRAM: 16 GB 以上（20B 想定）

## Quickstart
```bash
# 初回: 依存確認・ビルド～起動まで対話
chmod +x bootstrap.sh
./bootstrap.sh
