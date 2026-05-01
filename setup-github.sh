#!/usr/bin/env bash
# 一鍵部署到 GitHub + 啟用 GitHub Pages
set -e
cd "$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "=========================================="
echo " 台股全景儀表板 → GitHub 部署"
echo "=========================================="
echo ""

REPO_NAME="taiwan-stock-dashboard"

# ---- Step 1: Git init / 清理半成品 ----
# 若 .git 存在但沒有任何 commit（例：先前失敗的 init），先清掉重來
if [ -d .git ] && [ -z "$(git log --oneline 2>/dev/null)" ]; then
  echo "→ 偵測到不完整的 .git（無 commit），清理重建..."
  rm -rf .git
fi

if [ ! -d .git ]; then
  echo "→ 初始化 git repo..."
  git init -b main >/dev/null
  git config user.email "roger.cf.liu@gmail.com"
  git config user.name "Roger Liu"
  git add .
  git commit -m "Initial commit: 台股全景儀表板（280 家公司、31 產業、176 連結）" >/dev/null
  echo "  ✓ 完成"
else
  echo "→ git repo 已存在，跳過 init"
fi

# ---- Step 2: 檢查並使用 gh CLI ----
if command -v gh >/dev/null 2>&1; then
  echo ""
  echo "→ 偵測到 gh CLI"

  # 檢查登入
  if ! gh auth status >/dev/null 2>&1; then
    echo "  ⚠ 尚未登入 GitHub，啟動 gh auth login..."
    gh auth login
  fi

  GH_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
  if [ -z "$GH_USER" ]; then
    echo "  ⚠ 無法取得 GitHub 帳號，請確認登入狀態"
    exit 1
  fi
  echo "  ✓ 帳號：$GH_USER"

  # 建立 repo（如果已存在則跳過）
  if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
    echo "→ Repo 已存在於 $GH_USER/$REPO_NAME，跳過建立"
    # 確保 remote 設好
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
    git push -u origin main
  else
    echo "→ 建立 GitHub repo 並推送..."
    gh repo create "$REPO_NAME" --public \
      --source=. --remote=origin --push \
      --description "台股全景儀表板：280 家上市櫃公司、31 個產業、176 條連結（供應鏈/集團/相關性）"
    echo "  ✓ Repo 建立 + 推送完成"
  fi

  # 啟用 GitHub Pages
  echo ""
  echo "→ 啟用 GitHub Pages..."
  if gh api "repos/$GH_USER/$REPO_NAME/pages" >/dev/null 2>&1; then
    echo "  ✓ Pages 已啟用"
  else
    if gh api -X POST "repos/$GH_USER/$REPO_NAME/pages" \
        -f "source[branch]=main" -f "source[path]=/" >/dev/null 2>&1; then
      echo "  ✓ Pages 啟用成功"
    else
      echo "  ⚠ 無法自動啟用 Pages，請手動前往："
      echo "    https://github.com/$GH_USER/$REPO_NAME/settings/pages"
      echo "    選 Source: Deploy from a branch / Branch: main / Folder: /(root)"
    fi
  fi

  echo ""
  echo "=========================================="
  echo " ✅ 部署完成！"
  echo "=========================================="
  echo ""
  echo "📦 Repo:        https://github.com/$GH_USER/$REPO_NAME"
  echo "🌐 線上儀表板:  https://$GH_USER.github.io/$REPO_NAME/"
  echo "                （Pages 首次部署約需 1-2 分鐘）"
  echo ""

else
  echo ""
  echo "⚠️  未偵測到 gh CLI"
  echo ""
  echo "請選擇一種方式："
  echo ""
  echo "【方式 A】 安裝 gh CLI（推薦，最快）："
  echo "  brew install gh"
  echo "  然後重跑此腳本：bash setup-github.sh"
  echo ""
  echo "【方式 B】 手動建立 repo："
  echo "  1. 到 https://github.com/new 建立公開 repo（名稱：$REPO_NAME）"
  echo "     ⚠ 不要勾選 Add README / .gitignore / LICENSE（這邊已建好）"
  echo "  2. 回到 Terminal 執行（替換 <你的帳號>）："
  echo ""
  echo "     git remote add origin https://github.com/<你的帳號>/$REPO_NAME.git"
  echo "     git push -u origin main"
  echo ""
  echo "  3. 啟用 GitHub Pages："
  echo "     到 Settings → Pages → Source: Deploy from a branch → main / (root) → Save"
  echo ""
fi
