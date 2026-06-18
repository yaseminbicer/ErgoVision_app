#!/bin/bash
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:$PATH"

AI_DIR="$HOME/ErgoVision_app/ai"
PID_FILE="$AI_DIR/.backend.pid"
LOG_FILE="$AI_DIR/.backend.log"

# Port 8000 zaten açıksa backend çalışıyordur, çık
if lsof -ti:8000 > /dev/null 2>&1; then
    exit 0
fi

# Eski PID dosyasını temizle
rm -f "$PID_FILE"

# Backend'i arka planda başlat
cd "$AI_DIR"
nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
