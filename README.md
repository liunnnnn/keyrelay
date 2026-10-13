# KeyRelay

[English](#english) | [中文说明](#中文说明)

## English

A **macOS keyboard input tool with adapters for remote desktop clients and VM consoles**. KeyRelay sends local text through the keyboard channel of your existing remote connection, with a native Mac app, CLI and AI skill.

**Version 0.1.0 is a prerelease.** The sender runs on Apple Silicon Macs with macOS 13+. The remote destination may be Windows, Linux or macOS; compatibility depends on the client, keyboard layout and target application.

### Why use it?

Customer environments often disable remote clipboard synchronization, or a remote console may have no paste channel. Manual keyboard input still works, but typing long commands, configurations and scripts by hand is slow and error-prone.

KeyRelay selects a remote-client adapter, then converts reviewed local text into physical key events. Your existing remote connection carries those events to the focused destination. No receiver needs to be installed on the customer's computer, and the tool does not create a separate SSH or file-transfer connection.

Typical uses:

- RDP / Windows App sessions where local clipboard content cannot be pasted.
- ESXi / vSphere browser consoles without a usable clipboard channel.
- Linux Bash here-doc / tee commands for writing long configurations or scripts.
- AI-assisted entry of a prepared local text file, followed by target-side verification.

Use it for keyboard input permitted in the target environment.

### Remote-client adapters

Choose the **remote software**, rather than a Vim mode or the remote operating system. A Windows App connection can contain Windows software or a Linux shell; the client adapter handles keyboard delivery, while your text remains unchanged apart from documented Tab/newline normalization.

| Client ID | Remote software | Current evidence |
| --- | --- | --- |
| `esxi` | ESXi browser console / shell | Previous Bash temporary-file test passed; new session retest needed |
| `winapp` | Windows App | Existing physical Shift/Ctrl handling retained; complete remote retest pending |
| `sunlogin` | Sunlogin / 向日葵 | Experimental preset, awaiting testing with the user |
| `todesk` | ToDesk | Experimental preset, awaiting testing with the user |
| `uu` | UU Remote / UU 远程 | Experimental preset, awaiting testing with the user |
| `generic` | Other client / manual selection | Original sender; compatibility depends on the chosen client |

The last three entries are **not verified compatibility claims**. They currently use the same physical US keyboard sender with a slower default interval. Add client-specific behavior only after observing a reproducible difference in that remote software. See [adapter development](docs/ADAPTERS.md) and [compatibility records](docs/COMPATIBILITY.md).

### Download and run

Open [Releases](https://github.com/liunnnnn/keyrelay/releases):

| Asset | Purpose |
| --- | --- |
| `keyrelay-0.1.0-macos-arm64.zip` | Apple Silicon app and CLI |
| `text-to-keyboard-input-0.1.0.zip` | Standalone AI skill |
| `SHA256SUMS.txt` | Download checksums |
| GitHub Source code archives | Source at the release tag |

Keep `keyrelay`, `vmtype` and `KeyRelay.app` in the same directory. `vmtype` remains a compatibility alias. Open the app and enable **KeyRelay** in System Settings > Privacy & Security > Accessibility. The bundle id is `io.github.liunnnnn.keyrelay`; KeyWeaver users must authorize this separate app. Existing local builds remain available until you switch your tool path.

The download is ad-hoc signed, without Developer ID signing or Apple notarization. macOS may show a first-launch prompt. Review it yourself, or build from source.

### GUI

Select **Remote client**, copy text, click **Capture Clipboard**, review it, then click **Start Typing**. The selected adapter and its validation status are always visible. Focus the destination field during the countdown and keep it focused. Verify the actual received text afterward.

In **Settings**, configure countdown, delay and **Spaces per Tab**. Each Tab becomes a fixed number of spaces, default **4**, range **1-32**; this is not tab-stop alignment. Settings persist, but content and permission to send line breaks do not. Allow line breaks explicitly for multiline input: Enter may execute terminal commands.

Use **Stop** or Esc to cancel. Command+Return starts typing only inside the app. There are no Vim modes or destination-file fields; put your own tee command, path and options in the input text.

### CLI

From the unpacked directory, or using the full path:

```sh
./keyrelay --list-clients
./keyrelay --client esxi --text 'docker ps' --countdown 5 --delay-ms 100
./vmtype --file commands.sh --allow-enter --tab-spaces 4 --dry-run
./vmtype --file commands.sh --allow-enter --tab-spaces 4 --countdown 5 --delay-ms 100
printf 'name: example\n\tport: 8080\n' | ./vmtype --stdin --allow-enter
```

`--file` is local input, not a remote destination. `--target BUNDLE_ID` activates an outer Mac application only; it does not choose a remote connection, tab or input field. Windows App is `com.microsoft.rdc.macos`. CLI defaults are 5 seconds and 4 spaces per Tab, independent of GUI preferences. With no `--client`, the original `generic` behavior stays at 45 ms. Remote presets use 100 ms; `--delay-ms` overrides it in any argument order. Windows App defaults to its known bundle ID; other clients require manual focus or an explicit `--target`.

`--check-permission` checks authorization. `--self-test` and `--dry-run` never type. Run `./vmtype --help` for options.

### Write files with your own tee command

At a target Linux Bash prompt, type a complete command such as:

```sh
tee /tmp/example.conf > /dev/null <<'EOF'
name: example
port: 8080
EOF
```

Include a newline after the final `EOF`. Quote the delimiter to prevent expansion. It must occupy its own line and not collide with a content line. Relative paths use the remote shell's working directory. `tee` overwrites; `tee -a` appends. Choose `sudo tee` yourself when elevated write permission is needed, and finish authentication before sending.

Non-ASCII text has no universal physical key mapping. For Linux file contents, prepare an ASCII Base64 decoder/tee command. This example writes Chinese test text and a trailing newline:

```sh
base64 -d <<'EOF' | tee /tmp/example.txt > /dev/null
5Lit5paH5rWL6K+VCg==
EOF
```

The AI skill describes preparing commands from original UTF-8 bytes: replace content Tabs before encoding, preserve other bytes, and verify the resulting file hash. The tool does not decode or rewrite Base64 in your commands.

### AI skill

The AI should use its own keyboard tools first. KeyRelay is a fallback only when those tools are unavailable or have a confirmed input failure; paste failure alone is not enough. Use the current repository's Skill for the latest invocation policy; release archives contain the snapshot from that release.

[SKILL.md](SKILL.md) provides the `text-to-keyboard-input` skill. Download the separate skill archive, or install from the source directory (review differences before replacing an existing skill):

```sh
mkdir -p ~/.codex/skills/text-to-keyboard-input/agents
cp SKILL.md ~/.codex/skills/text-to-keyboard-input/SKILL.md
cp openai.yaml ~/.codex/skills/text-to-keyboard-input/agents/openai.yaml
```

Tell the AI the actual `keyrelay` / `vmtype` path or provide `VMTYPE_BIN`, plus the intended `--client`. No maintainer paths or customer addresses are embedded.

### Build and package

Requires Xcode Command Line Tools / Swift on macOS. The current target is Apple Silicon, macOS 13+:

```sh
git clone https://github.com/liunnnnn/keyrelay.git
cd keyrelay
zsh build.sh
./dist/vmtype --self-test
open dist/KeyRelay.app
zsh release.sh
```

No third-party runtime dependencies. The source is organized by responsibility:

```text
Sources/KeyRelay/
  Adapters/   Client registry, compatibility status, target and keyboard behavior
  Core/       Text validation, Tab expansion and US key mapping
  Platform/   Accessibility, focus checks and physical event sending
  CLI/        Argument parsing, execution and self-checks
  App/        App lifecycle, window layout and user interaction
  main.swift  GUI / CLI entry point
Tests/        Regression checks and pre-refactor planning fixtures
```

`vmtype` uses LaunchServices for app authorization; `build.sh` creates `dist/`; `release.sh` generates app, skill and checksum assets in `releases/`.

Run regression checks with Command Line Tools alone:

```sh
zsh test.sh
```

The checks cover original planning fixtures, every Tab width, line breaks, limits, CLI/UTF-8 input, adapter defaults and target conflicts. GitHub Actions runs the same checks and builds the app on an Apple Silicon macOS runner. They do not send keyboard events. `Package.swift` also supports `swift build` for development; use `build.sh` to create the authorized app bundle. Browser-uploaded source scripts may lack executable bits; invoke build scripts with `zsh`, and the build restores execution permission on `dist/vmtype`.

### Validation and limitations

- ASCII mapping, modifier events, Tab expansion, CRLF/CR, size limits and Enter permission have self-check coverage.
- An ESXi Bash workflow wrote a temporary file containing ASCII, symbols and Chinese, with a matching SHA-256. This does not establish compatibility with every client. The 1.2.1 Tab settings and conversion were checked separately.
- Local AppKit / TextEdit repeated characters in legacy 1.2.0 and 1.2.1. This adapter refactor does not claim to solve that limitation; KeyRelay remains a prerelease for remote-client testing.
- Current Windows App remote regression remains pending. No native Windows or Linux sender binary is included.
- Use matching US layouts and an English input source. Arbitrary non-ASCII input fields are not supported.
- Focus checks stop on app changes, but cannot detect same-app tab/connection/field changes. A switch before countdown completion can change the selected destination.
- Original and expanded text are limited to 64 KB. Slow remote clients need a larger delay.
- Interruptions may leave a partial command or here-doc continuation. Inspect before retrying; never blindly resubmit an append operation.

The GUI does not persist input content. The CLI cleans private temporary files on normal completion/cancellation; forced termination can leave files. No telemetry or network requests are implemented, but typed content travels through the remote client you use. Prefer files/stdin for sensitive content over process arguments.

Report reproducible issues with OS, client, keyboard layout, harmless example text and actual target results. Do not include customer configurations, credentials or private addresses. Source and skill use the [MIT License](LICENSE). Release organization references [ArbenP/TypeClipboard](https://github.com/ArbenP/TypeClipboard).

---

# 中文说明

**在 Mac 上运行的远程软件键盘输入适配工具。** 把本地文字转换成按键，通过现有远程连接送到客户电脑或虚拟机控制台；提供 Mac 应用、CLI 和 AI Skill。

**当前发布：0.1.0 预发布版。** 运行端为 macOS 13+ / Apple Silicon；目标机器可以是 Windows、Linux 或 macOS，但兼容性取决于远程客户端、键盘布局和目标程序。

## 应用场景

客户环境经常禁止远程剪贴板同步，或者远程工具不能把本机复制的内容粘贴过去。此时虽然仍能用键盘输入，但手动敲一长段命令、配置或代码很慢，也容易打错。

KeyRelay 的用法是：选择远程软件 → 本机复制文字 → 在工具里检查 → 开始输入 → 切到客户电脑的输入位置。它模拟真实按键，由现有远程连接把按键传给目标机器。

适合这些场景：

- **远程客户电脑无法粘贴**：RDP / Windows App 中的命令行、远程终端或其他接受键盘输入的程序。
- **虚拟机浏览器控制台**：ESXi / vSphere 等没有可用剪贴板通道的控制台。
- **长配置和脚本**：在 Linux Bash 中键入自己写的 `tee` / here-doc 命令，将文本写入指定文件。
- **AI 辅助输入**：AI 准备文本文件，通过 `vmtype` 命令行输入，再核对目标实际结果。

工具用于目标环境允许的键盘输入。不需要在客户电脑安装接收端；它也不会建立 SSH 连接或另外开启文件传输通道。

## 远程软件适配

选择的是**使用哪种远程软件**，无需区分 Vim 与普通模式，也不用只按远端 Windows / Linux / macOS 分类。比如 Windows App 中可能打开 PuTTY 连接 Linux：适配对象仍然是 Windows App，正文按照实际目标 Shell 的语法准备。

| ID | 远程软件 | 当前状态 |
| --- | --- | --- |
| `esxi` | ESXi 浏览器控制台 / Shell | 旧版 Bash 临时文件测试通过；新会话仍需回读验证 |
| `winapp` | Windows App | 已保留修饰键处理；完整远程回归待完成 |
| `sunlogin` | 向日葵 | 已提供实验预设，待你提供环境共同适配 |
| `todesk` | ToDesk | 已提供实验预设，待共同适配 |
| `uu` | UU 远程 | 已提供实验预设，待共同适配 |
| `generic` | 其他软件 / 手动选择 | 保留原有发送方式，需按实际客户端验证 |

后三种尚未实测，**不能据预设名称判断已兼容**。当前先复用真实 US 键盘发送方式和较慢间隔，后续遇到差异再在独立适配层调整，不修改正文处理或其他客户端。查看 [适配开发说明](docs/ADAPTERS.md) 和 [兼容性记录](docs/COMPATIBILITY.md)。

## 下载和首次运行

从 [Releases](https://github.com/liunnnnn/keyrelay/releases) 下载：

| 文件 | 用途 |
| --- | --- |
| `keyrelay-0.1.0-macos-arm64.zip` | Apple Silicon Mac 应用和 CLI |
| `text-to-keyboard-input-0.1.0.zip` | 单独安装 AI Skill |
| `SHA256SUMS.txt` | 下载文件校验值 |
| GitHub 自动生成的 Source code | 当前标签的全部源码 |

解压后保留 `keyrelay`、兼容入口 `vmtype` 与 `KeyRelay.app` 在同一目录。双击 `KeyRelay.app` 打开英文界面。公开版使用独立标识 `io.github.liunnnnn.keyrelay`；从 KeyWeaver 切换时需单独为 KeyRelay 授权，旧的本地构建仍保留。

在 macOS「系统设置 → 隐私与安全性 → 辅助功能」中启用该应用，才能模拟按键。下载包采用 ad-hoc 签名，没有 Developer ID 签名或 Apple 公证；首次打开可能出现系统提示，需由使用者自行决定授权，也可以从源码构建。

## 图形界面

1. 在「Remote client」选远程软件，界面会展示适配验证状态；再复制文本，点「Capture Clipboard」或粘贴。
2. 如有换行，在「Settings」允许发送换行键；终端中的回车可能执行命令。
3. 点「Start Typing」，在倒计时内点击目标窗口中的输入位置。
4. 发送期间保持目标窗口在前台，完成后检查目标实际内容。

设置可调整等待时间、每键间隔，以及每个 Tab 替换的空格数。**Tab 默认替换为 4 个空格**，支持 1–32；每个 Tab 固定替换，不按列计算。设置会记住，输入文本和换行许可不持久保存。

Esc 或「Stop」取消。助手内 Command+Return 开始输入。没有 Vim 模式，也没有目标文件框；`tee`、路径、sudo、覆盖/追加等由你自己写在文字中。

## 命令行

在解压目录运行，或使用 `vmtype` 的完整路径：

```sh
./vmtype --text 'docker ps' --countdown 5 --delay-ms 100
./vmtype --file commands.sh --allow-enter --tab-spaces 4 --dry-run
./vmtype --file commands.sh --allow-enter --tab-spaces 4 --countdown 5 --delay-ms 100
```

也支持标准输入：

```sh
printf 'name: example\n\tport: 8080\n' | ./vmtype --stdin --allow-enter --tab-spaces 4
```

`--file` 指本地待输入文件，不是远端目标文件。`--target BUNDLE_ID` 可激活指定 Mac 应用；例如 Windows App 为 `com.microsoft.rdc.macos`。它不能自动选择应用内部的远程连接、标签页或输入框。

`--list-clients` 查看适配列表；`--client esxi`、`--client winapp` 等选适配。Windows App 预设绑定已知的 Mac 应用标识，其余预设通过倒计时手动选目标，或显式提供 `--target`；Windows App 预设与冲突的 `--target` 会被拒绝。

`--check-permission` 检查权限；`--self-test` 检查键位和转换规则，不发送按键。CLI 默认 5 秒、Tab 转 4 空格，不受 GUI 偏好影响。不传 `--client` 保留原来 45 ms 的行为；远程预设使用 100 ms，`--delay-ms` 可自行覆盖。运行 `./vmtype --help` 查看全部参数。

## 用 tee 写文件

在目标 **Linux Bash 提示符**处，可以直接键入这样的完整文本：

```sh
tee /tmp/example.conf > /dev/null <<'EOF'
name: example
port: 8080
EOF
```

最后 `EOF` 后必须还有换行才能提交。`<<'EOF'` 的单引号使正文中的变量和反引号保持原样；结束分隔符独占一行且不能与正文的独立行冲突。相对路径由远端当前目录解释。

`tee` 覆盖，`tee -a` 追加；需要提升写权限时自己改成 `sudo tee`，先完成 sudo 认证，确认回到 Shell 提示符再发送。工具不会额外补回车、创建目录或应用业务配置。

### 中文与精确正文

中文没有通用的单个物理键位，当前**不能保证向任意输入框直接敲中文**。向 Linux 文件写中文时，可以先把 UTF-8 正文编码为 Base64，再键入全 ASCII 的解码/tee 命令：

```sh
base64 -d <<'EOF' | tee /tmp/example.txt > /dev/null
5Lit5paH5rWL6K+VCg==
EOF
```

该例写入「中文测试」及末尾换行。AI Skill 包含从原始正文生成完整命令的步骤：在编码前按设置替换 Tab，保留其余字节，然后核对转换后正文的 SHA-256。工具不会解码和重写你提供的 Base64。

## AI Skill

AI 优先使用自身的键盘操作能力，能可靠完成就直接输入；只有能力不可用或已确认无法完成输入时才调用 KeyRelay，不能仅因粘贴失败就调用工具。最新调用规则以当前仓库的 Skill 为准，Release 压缩包保留对应发布时的版本快照。

仓库中的 [SKILL.md](SKILL.md) 为 `text-to-keyboard-input` Skill；包含 CLI、here-doc、长文本和中文文件输入流程。Skill 包与应用包分开下载。

从源码目录安装示例（已有同名 Skill 时先自行检查差异）：

```sh
mkdir -p ~/.codex/skills/text-to-keyboard-input/agents
cp SKILL.md ~/.codex/skills/text-to-keyboard-input/SKILL.md
cp openai.yaml ~/.codex/skills/text-to-keyboard-input/agents/openai.yaml
```

告知 AI 本机 `keyrelay` / `vmtype` 的实际位置及远程客户端，或者通过 `VMTYPE_BIN` 提供路径。Skill 不包含维护者本机路径或客户环境地址。

## 从源码构建

需要 macOS 的 Xcode Command Line Tools / Swift 编译器，当前构建目标为 Apple Silicon、macOS 13+：

```sh
git clone https://github.com/liunnnnn/keyrelay.git
cd keyrelay
zsh build.sh
./dist/vmtype --self-test
open dist/KeyRelay.app
```

没有第三方运行时依赖。源码按职责拆成 `Adapters`（远程软件预设、验证状态与键盘行为）、`Core`（输入校验、Tab 转换与键位）、`Platform`（权限、焦点、真实事件发送）、`CLI`（参数解析与执行）和 `App`（生命周期、布局与交互）；入口为 `Sources/KeyRelay/main.swift`。

`vmtype` 包装脚本通过 LaunchServices 复用应用授权，`build.sh` 构建应用，`release.sh` 打包应用、Skill 和校验文件。用 `zsh test.sh` 运行不依赖完整 Xcode 的回归检查，覆盖重构前的规划记录、1–32 个空格缩进、换行、大小限制、CLI 参数和 UTF-8 文件读取，不发送按键。开发时也可用 `swift build`；需要应用包时使用 `build.sh`。

```sh
zsh release.sh
```

生成的下载文件位于 `releases/`，不提交构建产物到源码仓库。通过浏览器上传源码获取的 shell 脚本可能没有可执行位；用 `zsh build.sh` / `zsh release.sh` 构建，生成的 `dist/vmtype` 会恢复执行权限。

## 已验证范围和已知限制

- 已验证 95 个可打印 ASCII 键位、修饰键、Tab 替换、CRLF/CR、输入大小和回车许可检查。
- ESXi Bash 曾实际写入含英文、符号、中文及 Tab 的临时文件，并核对 SHA-256 一致。1.2.1 的 Tab 设置和转换检查通过，未据此声明所有远程客户端均已验收。
- 本地 AppKit / TextEdit 输入框测试发现重复字符；旧版 1.2.0 和 1.2.1 对照均复现，原因尚未确认。KeyRelay 保留该限制并作为预发布，不能当作任意本机输入框的通用工具。
- Windows App 当前版本的远程回归仍待完成。当前发布不含 Windows 或 Linux 本机可执行程序。
- 源端与目标需使用匹配的 US 键盘布局及英文输入法；非 ASCII 文字不能直接通用键入。
- 切换应用会停止输入，但倒计时结束时选中的前台窗口可能已变化；同一应用内切换标签页、连接或输入框无法识别。不要只凭“发送完成”判断输入正确。
- 原文及 Tab 展开后的文字单次最多 64 KB。慢速远程连接需增加每键间隔。
- 中断可能留下半条命令或 here-doc 续行。先检查目标状态，不盲目重发全文或补 EOF，尤其避免重复追加。

GUI 不持久保存正文；CLI 正常结束或取消后清理私有临时目录，强制终止可能留下文件。应用没有网络请求或遥测；键入的文字会通过你正在使用的远程连接到达目标。敏感内容优先用 `--file` / `--stdin`，不放进进程参数。

## 反馈和许可证

欢迎提交 [Issues](https://github.com/liunnnnn/keyrelay/issues)：注明系统、远程客户端、键盘布局、最小复现文本和目标实际结果。不要上传真实客户配置、密码、内部地址或私人剪贴板内容。

源码和 Skill 使用 [MIT License](LICENSE)。发布组织参考了 [ArbenP/TypeClipboard](https://github.com/ArbenP/TypeClipboard) 的源码、应用包及校验文件分离方式。
