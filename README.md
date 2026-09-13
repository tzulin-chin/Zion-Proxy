# Zion Proxy

OPC 史密斯的本機 runtime。這是公開發佈倉庫，提供 macOS/Linux（glibc）× arm64/x64 的獨立 binary，不包含 OPC monorepo 原始碼。

- [下載穩定版](https://github.com/tzulin-chin/Zion-Proxy/releases/latest)
- [給 Agent 的安裝 prompt](INSTALL.md)

Runtime：Codex CLI、Claude CLI、OpenClaw agent exec、Cursor CLI，以及 OpenAI、Gemini、Anthropic、OpenRouter API。CLI 與登入需另行準備，API key 可留在本機檔案。OpenClaw 是 runtime 相容模式，不是原生 channel plugin。

下載 Release 的 install.sh 與 SHA256SUMS，核對 installer checksum 後：

```sh
sh install.sh --version <release-tag>
~/.local/bin/opc --help
```

Proxy 支援 config/token-file、doctor JSON、launchd/user-systemd 服務、更新檢查、閒置自動更新與上一版 rollback。

`opc update --check --json` 檢查官方穩定版；`opc update` 安裝新版本後需重啟服務。設定 autoUpdate=true 的 managed service 會自行更新重啟。

SHA256SUMS 涵蓋每次 Release 的平台壓縮檔、manifest、installer 與安裝文件。releases/ 保存發佈來源 commit 與 manifest hash 的對賬記錄。macOS binary 尚未 Developer ID 簽章/notarization；Windows 與 musl 尚未支援。
