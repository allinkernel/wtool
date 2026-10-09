# 下载 wtool

**这是 wtool 唯一的下载页。** 不装 `git`、只在一台能上网的机器上点几下，也能把
`wtool` 和它的项目拿到手。想长期跟着改、一条命令更新全部仓库，走 `git` 那条路 ——
见 [README 的「安装」](README.md#2-安装)。

工作区一共只由两种东西拼成，对应下面两节：

| 要拿的东西 | 在哪 | 说明 |
|---|---|---|
| **引擎**（`wtool` 这条命令） | 第 1 节 | 只装它一个就能开张：`wtool` 能用，项目以后再补 |
| **各个项目** | 第 2 节（下面那张自动生成的表） | 想要哪个下哪个；全下完就是一个完整工作区 |

---

## 1. 先拿引擎（`wtool` 自己）

`wtool` 这条命令住在 **`bootstrap`** 这个项目里 —— **不在你现在看的这个文档仓库里**
（这个仓库是 `wtool-base`，里面只有文档）。引擎的仓库和发布页是：

| 是什么 | 地址 |
|---|---|
| 仓库 | <https://github.com/allinkernel/wtool-bootstrap> |
| 发布页（从这里下包） | <https://github.com/allinkernel/wtool-bootstrap/releases> |

**只有浏览器**：打开上面那个发布页，下最新那一版里的 **`source.zip`**，解开。
包里的第一层固定是 `wtool/`（和你的工作区目录叫什么无关），所以解开之后就有
`wtool/bootstrap/`。

**有 `git` 的机器**（更省事，以后更新一条命令）：

```bash
mkdir -p ~/self/wtool
git clone https://github.com/allinkernel/wtool-bootstrap.git ~/self/wtool/bootstrap
```

只下这一个也够开张：解开或克隆之后跑包里那个安装器，`wtool` 就能用了 ——
**怎么跑见第 4 节**。别的项目按需再下（第 2 节）。

---

## 2. 再拿各个项目

下面这张表是**引擎查到有发布包的项目** —— 点版本号去 Release 页，点文件名直接下载。

**表里没有的项目 = 引擎这次没查到它的包**（还没发过，或者 tag 对不上）。想找某个项目的
包，最稳的是直接点开那个项目的 Release 页（每个项目的地址在第 5 节）；
只想要源码就干脆走 `git` 那条路（[README](README.md#2-安装)）。

> **下载这条路拿到的是"上一次发布那一刻"的工作区，不一定是最新源码。**
> 要最新的源码，走 `git`。

**这张表由 `wtool docs refresh` 重写，不要手改。** 它拿 `gh`（GitHub CLI）去 GitHub
查每个项目**真实存在**的 release，照查到的结果重写整块（`wtool publish-release`
发布成功之后也会自动跑一遍）；查不到东西时它**宁可不动这张表，也不拿空表覆盖**。
所以表里的链接都是线上真实存在的地址，版本号就是**最后一次刷表时线上那一版**。

<!-- >>> wtool:downloads >>> -->
<!-- 这一块由 `wtool publish-release` 自动重写，不要手改。 -->

每个项目的最新发布包都在它自己的 release 页面上。
全部下载并解开之后，你会得到一个完整的工作区目录。

| 项目 | 版本 | 包 | 大小 |
|---|---|---|---|
| `bootstrap` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-bootstrap/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/dist.json) | 859B |
| `bootstrap` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-bootstrap/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `bootstrap` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-bootstrap/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source.zip) | 353.2K |
| `os/ubuntu` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-os-ubuntu/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/dist.json) | 827B |
| `os/ubuntu` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-os-ubuntu/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `os/ubuntu` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-os-ubuntu/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source.zip) | 18.2K |
| `shell/oh-my-zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-ohmyzsh/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/dist.json) | 846B |
| `shell/oh-my-zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-ohmyzsh/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `shell/oh-my-zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-ohmyzsh/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source.zip) | 3.3M |
| `shell/zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-zsh/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/dist.json) | 847B |
| `shell/zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-zsh/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `shell/zsh` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-zsh/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source.zip) | 118.1K |
| `terminal/fzf` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-fzf-binary/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/dist.json) | 865B |
| `terminal/fzf` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-fzf-binary/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `terminal/fzf` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-fzf-binary/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source.zip) | 1.7M |
| `terminal/tmux` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-tmux-config/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/dist.json) | 866B |
| `terminal/tmux` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-tmux-config/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `terminal/tmux` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-tmux-config/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source.zip) | 19.6K |
| `tools/android_repack` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-android_repack/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/dist.json) | 849B |
| `tools/android_repack` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-android_repack/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `tools/android_repack` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-android_repack/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source.zip) | 180.9K |
| `tools/dsh-remote` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-dsh-remote/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/dist.json) | 868B |
| `tools/dsh-remote` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-dsh-remote/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `tools/dsh-remote` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-dsh-remote/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source.zip) | 281.2K |
| `tools/git-repo-sh-tools` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-repo/releases/tag/ds_dev-2026-10-09) | [dist.json](https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/dist.json) | 862B |
| `tools/git-repo-sh-tools` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-repo/releases/tag/ds_dev-2026-10-09) | [source-hash.txt](https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source-hash.txt) | 77B |
| `tools/git-repo-sh-tools` | [ds_dev-2026-10-09](https://github.com/allinkernel/wtool-repo/releases/tag/ds_dev-2026-10-09) | [source.zip](https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source.zip) | 91.4K |

### bash（Linux / macOS / WSL）

```bash
mkdir -p ~/self && cd ~/self
curl -fL -o bootstrap-dist.json https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o bootstrap-source-hash.txt https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o bootstrap-source.zip https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o os-ubuntu-dist.json https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o os-ubuntu-source-hash.txt https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o os-ubuntu-source.zip https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o shell-oh-my-zsh-dist.json https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o shell-oh-my-zsh-source-hash.txt https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o shell-oh-my-zsh-source.zip https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o shell-zsh-dist.json https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o shell-zsh-source-hash.txt https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o shell-zsh-source.zip https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o terminal-fzf-dist.json https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o terminal-fzf-source-hash.txt https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o terminal-fzf-source.zip https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o terminal-tmux-dist.json https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o terminal-tmux-source-hash.txt https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o terminal-tmux-source.zip https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o tools-android_repack-dist.json https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o tools-android_repack-source-hash.txt https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o tools-android_repack-source.zip https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o tools-dsh-remote-dist.json https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o tools-dsh-remote-source-hash.txt https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o tools-dsh-remote-source.zip https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source.zip
curl -fL -o tools-git-repo-sh-tools-dist.json https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/dist.json
curl -fL -o tools-git-repo-sh-tools-source-hash.txt https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source-hash.txt
curl -fL -o tools-git-repo-sh-tools-source.zip https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source.zip
unzip -o bootstrap-source.zip

unzip -o os-ubuntu-source.zip

unzip -o shell-oh-my-zsh-source.zip

unzip -o shell-zsh-source.zip

unzip -o terminal-fzf-source.zip

unzip -o terminal-tmux-source.zip

unzip -o tools-android_repack-source.zip

unzip -o tools-dsh-remote-source.zip

unzip -o tools-git-repo-sh-tools-source.zip
```

跑完 `~/self/wtool/` 就是一个完整的工作区。
接着 `cd ~/self/wtool && ./bootstrap/scripts/install.sh`（第一次要用完整路径，
它会把根目录的 `./install.sh` 等入口补齐，之后就能直接用短的了）。

### PowerShell（Windows 10 及以上自带 tar）

```powershell
$d = "$HOME\self"; New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Location $d
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "bootstrap-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "bootstrap-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-bootstrap/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "bootstrap-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "os-ubuntu-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "os-ubuntu-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-os-ubuntu/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "os-ubuntu-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "shell-oh-my-zsh-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "shell-oh-my-zsh-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-ohmyzsh/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "shell-oh-my-zsh-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "shell-zsh-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "shell-zsh-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-zsh/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "shell-zsh-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "terminal-fzf-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "terminal-fzf-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-fzf-binary/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "terminal-fzf-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "terminal-tmux-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "terminal-tmux-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-tmux-config/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "terminal-tmux-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "tools-android_repack-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "tools-android_repack-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-android_repack/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "tools-android_repack-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "tools-dsh-remote-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "tools-dsh-remote-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-dsh-remote/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "tools-dsh-remote-source.zip"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/dist.json" -OutFile "tools-git-repo-sh-tools-dist.json"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source-hash.txt" -OutFile "tools-git-repo-sh-tools-source-hash.txt"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-repo/releases/download/ds_dev-2026-10-09/source.zip" -OutFile "tools-git-repo-sh-tools-source.zip"
Expand-Archive -Force -Path "bootstrap-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "os-ubuntu-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "shell-oh-my-zsh-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "shell-zsh-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "terminal-fzf-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "terminal-tmux-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "tools-android_repack-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "tools-dsh-remote-source.zip" -DestinationPath "."

Expand-Archive -Force -Path "tools-git-repo-sh-tools-source.zip" -DestinationPath "."
```

跑完 `$HOME\self\wtool` 就是一个完整的工作区。
<!-- <<< wtool:downloads <<< -->

### 表外要交代的四件事

**① 文件名带项目前缀。** 命令里的 `bootstrap-source.zip` 这种名字是**加过前缀的** ——
线上的资产名本身不带项目名（每个项目的源码包都叫 `source.zip`），几十个文件下到同一个
目录里不加前缀就会互相覆盖。前缀规则：项目路径里的 `/` 换成 `-`（`tools/dsh-remote`
→ `tools-dsh-remote-source.zip`）。

**② 一个项目的包放进一个目录。** 尤其是产物包：**不能改名** —— `dist.json` 是按名字
校验每一卷的。走下面第 3 节的 `wtool download-release` 就完全不用管这件事。

**③ `tools/android_repack` 那个仓是私有的。** 它的直链只有有权限的账号点得开
（没权限会得到 404，但那不是链接写错了）。私有仓统一走 `gh`，见第 3 节末尾。

**④ 表里为什么只有 `source.zip`。** 没有构建能力的项目（没有 `scripts/build.sh`、
也没有 `build/layers.tsv`）**只发源码包** —— 那种项目没有"产物"，产物包里只剩几个
声明文件，而源码包里本来就有。所以表里看到的大多是三个文件：
`source.zip`（源码）、`source-hash.txt`（它的校验值）、`dist.json`（这一版有哪些文件、
每个的校验值）。**有**构建产物的项目（今天只有 Neovim 那套）会多一个产物包
`release.zip`，大的还会切成 `-vol01`、`-vol02`… 分卷。

---

## 3. 下下来怎么用

### 3.1 装了 `wtool` 的机器：三条命令

**能联网的机器推荐这条 —— 下什么、校验、拼分卷它自己算，你不用记文件名。**

```bash
wtool download-release <项目>   # 照项目里提交的 scripts/release.json 下到 <项目>/__release/
wtool unpack-release   <项目>   # 校验 + 拼分卷 + 解开，写进 <项目>/__output/
wtool install          <项目>   # 装到本机（登记、软链、shell 集成）
```

- `<项目>` 写项目路径（`terminal/tmux`），末段（`tmux`）也认。
- `wtool download-release` 不带参数敲：列出**哪些项目有现成的包**可下；
  一次全下用 `wtool download-release all`。
- **前提是项目里提交了 `scripts/release.json`**（发布方发完一版会把它提交进仓库 ——
  它就是"这一版该下哪些文件"的清单）。没提交的项目敲了会明说
  「没有 `scripts/release.json`」，那就走 3.2，或者自己编：`wtool build <项目>`
  （要编译器和网络，几十分钟到几小时）。
- 已经下好的文件（校验值对得上）会跳过，不会重下几百兆；中断了重跑一遍就行。

### 3.2 只有浏览器的机器：手动下 + 传过去

1. 在第 2 节的表里（或各项目自己的 Release 页）把要的项目**全部文件**下下来 ——
   `source.zip`、`source-hash.txt`、`dist.json` 缺一个都不行（`unpack-release`
   要 `dist.json` 才拼得了分卷）。
2. 把下下来的文件放进**那台装了 `wtool` 的机器上**对应项目的 `__release/` 目录
   （文件名保持原样，别改名）。
3. 在那台机器上跑后两条命令：

```bash
wtool unpack-release <项目>   # 校验 + 拼分卷 + 解开
wtool install        <项目>   # 装
```

> 一个项目的包放进一个目录 —— 别把几个项目的包混在一起（第 2 节 ① 有原因）。

### 3.3 私有仓：用 `gh`

`tools/android_repack` 那个仓是私有的，直链匿名下不了：

```bash
gh release download <tag> --repo allinkernel/wtool-android_repack --dir .
```

（`<tag>` 用第 2 节表里那个版本号，例如 `ds_dev-2026-10-09`。先 `gh auth login` 一次。）
没装 `gh` 的话走 API 的**资产端点**（那条路认 token）：

```bash
TOKEN=<你的 token>
id=$(curl -s -H "Authorization: token $TOKEN" \
  https://api.github.com/repos/allinkernel/wtool-android_repack/releases/tags/<tag> \
  | python3 -c 'import json,sys;print(next(a["id"] for a in json.load(sys.stdin)["assets"] if a["name"]=="source.zip"))')
curl -fL -H "Authorization: token $TOKEN" -H "Accept: application/octet-stream" \
  -o tools-android_repack-source.zip \
  https://api.github.com/repos/allinkernel/wtool-android_repack/releases/assets/$id
```

---

## 4. 解开之后：跑包里那个安装器

```bash
cd <工作区目录>                    # 比如 ~/self/wtool
./bootstrap/scripts/install.sh     # 第一次要用完整路径
exec $SHELL                        # 让当前 shell 认识 wtool（或者重开一个终端）

wtool sudo-bootstrap               # 系统层：apt 包、/etc 下的文件。要 root；没有 sudo 就跳过
wtool bootstrap                    # 用户层：文件、软链、shell 集成（重复跑没有副作用）
```

安装器只做让它自己能用的事 —— 准备运行环境 → 自举引擎 → 补工作区入口
（根目录那几个 `./install.sh`、`README.md` 软链）→ 让 `wtool` 进 `PATH`，
**做完就停，不装任何项目**。屏幕最后会把接下来该敲的命令直接打给你。
（第一次必须用完整路径：解压出来的工作区还没有根目录那几个入口，它会顺手补齐；
之后 `./install.sh` 就能直接用了。）

> **安装说明只有这一处权威：[README](README.md)。** 子项目自己的 README 只讲
> 「这个项目是什么、有哪些脚本」，不另写一套安装步骤。**项目里的 `scripts/install.sh`
> 也不要去自己敲** —— 那是 `wtool install` 的活。

---

## 5. 各项目的发布页

想知道某个项目**现在有哪些版本**、或者表里没查到它的包，直接点它的 Release 页：

| 项目 | 仓库 | Release 页 |
|---|---|---|
| `bootstrap` | `allinkernel/wtool-bootstrap` | <https://github.com/allinkernel/wtool-bootstrap/releases> |
| `os/ubuntu` | `allinkernel/wtool-os-ubuntu` | <https://github.com/allinkernel/wtool-os-ubuntu/releases> |
| `shell/oh-my-zsh` | `allinkernel/wtool-ohmyzsh` | <https://github.com/allinkernel/wtool-ohmyzsh/releases> |
| `shell/zsh` | `allinkernel/wtool-zsh` | <https://github.com/allinkernel/wtool-zsh/releases> |
| `terminal/tmux` | `allinkernel/wtool-tmux-config` | <https://github.com/allinkernel/wtool-tmux-config/releases> |
| `terminal/fzf` | `allinkernel/wtool-fzf-binary` | <https://github.com/allinkernel/wtool-fzf-binary/releases> |
| `tools/git-repo-sh-tools` | `allinkernel/wtool-repo` | <https://github.com/allinkernel/wtool-repo/releases> |
| `tools/android_repack` | `allinkernel/wtool-android_repack` | <https://github.com/allinkernel/wtool-android_repack/releases> （**私有**） |
| `tools/dsh-remote` | `allinkernel/wtool-dsh-remote` | <https://github.com/allinkernel/wtool-dsh-remote/releases> |
| `harness/dsh-conf` | `allinkernel/wtool-dsh-conf` | <https://github.com/allinkernel/wtool-dsh-conf/releases> |
| `editor/astronvim_v5` | `allinkernel/wtool-astronvim_v5` | <https://github.com/allinkernel/wtool-astronvim_v5/releases> |

（`docs/download.md` 那份**页**是每个项目自己仓库里的**同一份内容的另一种排版** ——
`wtool pack-release` 打的，跟项目的源码一起提交。项目 `README.md` 里会指向它。）

---

## 6. 这一页是怎么来的

- **带标记的那一半是引擎生成的**（`<!-- >>> wtool:downloads >>> -->` 与
  `<!-- <<< wtool:downloads <<< -->` 之间）：`wtool publish-release` 发成功之后
  会自动刷一遍，平时不用管。
- **其余的字是人写的。** 改这一页请改标记块**外面**的部分 —— 块里面的内容是重算出来的，
  手改一定会被下一次刷新冲掉。
- 想手动刷一次：`wtool docs refresh`（`wtool docs`、`wtool refresh-downloads`
  **三个入口同一条命令**）。跑之前要知道三件事：
  1. **它要 `gh` 且已登录**；没有 `gh` 就跳过并警告一句，不会硬失败。
  2. **它改的是文档** —— 改完就是普通的工作区改动，`git diff` 能看、`git checkout` 能退。
  3. **它拒绝用空表覆盖已有的表**：查到 0 个资产（`gh` 没登录、网络不通、release 被删
     都会这样）而文档里本来有表时，它警告并停手。确认确实要清空才加 `--force`。
- 它查的是**"这个项目实际发过的那个 tag"** —— 读项目里**提交在仓库中**的
  `scripts/release.json` 记的 `tag`；从没发布过的项目才退回按模板算
  （默认 `snapshot-%Y-%m-%d`）。所以不要求"今天正好发过"。
- **这一页只能有一份。** 工作区里带 `wtool:downloads` 标记的文档多于一个时，
  引擎会**拒绝刷新**并把候选列出来（下载页有两个真相源，比没有下载页更糟）——
  看到那条错误就去把多余的标记块删掉。
