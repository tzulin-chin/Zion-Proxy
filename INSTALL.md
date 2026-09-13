# 給 Agent 的 Zion Proxy 安裝 prompt

將下面內容交給能操作本機終端的 Agent；補上 OPC server、runtime 與史密斯 token 檔案位置。不要把 API key 放在聊天或命令列參數。

---

請在這台機器安裝 Zion Proxy，讓我的 OPC 史密斯上線，並配置自動更新。

輸入：

- OPC server：`<https://你的 OPC server>`
- 史密斯 token 檔案：`<絕對路徑>`（如果還沒有，請引導我建立只限本人讀取的檔案，不要回顯 token）
- Runtime：`<codex | claude | openclaw | openai | gemini | anthropic | openrouter>`
- API runtime 才需要：API key 檔案 `<絕對路徑>`，模型 `<模型 ID 或 auto>`
- 安裝目錄：`~/.local/bin`；設定檔：`~/.config/zion-proxy/<史密斯名稱>/config.json`
- 自動更新：啟用；執行工具權限：沿用 runtime 的安全預設，不自行加 `--yolo`。

官方來源只有 `https://github.com/tzulin-chin/Zion-Proxy`。完成以下工作：

1. 偵測 macOS/Linux 與 arm64/x64。確認 server 與 token 檔案資訊齊全；Linux 需 glibc。若已有 `opc`，先讀 `opc --version` 與現有設定，不重設憑證、人格或服務。
2. 從官方 GitHub API `https://api.github.com/repos/tzulin-chin/Zion-Proxy/releases/latest` 取得目前穩定版 tag。下載該 tag 的 `install.sh` 和 `SHA256SUMS`，驗證 installer 的 SHA-256，閱讀腳本，再用 `sh install.sh --version <該 tag> --bin-dir "$HOME/.local/bin"` 安裝。腳本會再次驗證 binary 壓縮檔 checksum。全程不需 sudo，不下載其他來源的可執行檔。
3. 確保 token/key 檔案為 `chmod 600`，設定目錄為 `chmod 700`。不要印出內容，也不要存進 Git。API key 檔案保留在本機；CLI 使用各 CLI 自己的登入。
4. 設定不存在才執行 setup。CLI 範例：

   ```bash
   "$HOME/.local/bin/opc" setup --config "$HOME/.config/zion-proxy/neo/config.json" --server '<OPC server>' --token-file '<token 絕對路徑>' --driver codex --auto-update
   ```

   API 範例：

   ```bash
   "$HOME/.local/bin/opc" setup --config "$HOME/.config/zion-proxy/neo/config.json" --server '<OPC server>' --token-file '<token 絕對路徑>' --provider anthropic --api-key-file '<key 絕對路徑>' --model '<模型 ID>' --auto-update
   ```

   路徑與 neo 名稱依我的輸入替換，用正確 shell quoting。已存在設定先保留；有必要修改時只改這次要求的欄位。
5. 跑 `opc doctor --config <設定路徑> --json`，確認 server、token、runtime 預檢通過。再跑 `opc doctor --config <設定路徑> --live --json`，驗證一次真實模型回覆（我授權這一次小額連線測試）。CLI 尚未登入就提供它自己的登入步驟，不能假裝安裝成功。
6. 跑 `opc service install --config <設定路徑>`，再 `opc service start --config <設定路徑>`。macOS 用 LaunchAgent，Linux 用 user systemd。服務沿用安裝時 PATH/HOME。Linux 若沒有 user systemd session，說明環境缺少什麼，不自行改成 root 服務。
7. 檢查 `opc service status --config <設定路徑>`，以及本機管理頁 `/api/admin/status`，確認 `supervisor.state=running`、`proxy.connected=true` 且是預期史密斯；不能只看 PID。管理 port 從服務 log 取得，預設從 8080 往上找。不要把管理介面開到公開網路。
8. 執行 `opc update --check --json`，驗證可讀取官方更新。自動更新僅在 managed service 閒置時進行：校驗、試跑版本、原子替換、服務重新啟動。手動更新用 `opc update`，之後 `opc service restart --config <設定路徑>`；回復前一版用 `opc update --rollback` 後重啟。回復前先將設定 `autoUpdate` 設為 false，避免再次自動升級。
9. 回報：實際安裝版本、設定路徑、runtime、服務是否 ready、管理頁 URL、更新狀態、停止與移除命令。不要包含 token/key。

OpenClaw 使用支援 `openclaw agent exec --message-file -` 的版本，借用其 runtime、provider 設定與工具政策；不會讓既有 OpenClaw session 原生加入 OPC。Claude CLI 是否能寫檔/執行工具依自身權限，不能為了通過安裝就關閉所有權限限制。

停止：`opc service stop --config <設定路徑>`。
移除服務：`opc service uninstall --config <設定路徑>`（保留設定、token、工作檔）。
