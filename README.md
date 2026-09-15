# wtool

把一堆零散的个人配置和工具——shell、终端、编辑器、主题——用一条命令装到一台新机器上。

这不是一个软件，是一套**管理方式**：所有配置以独立的小项目形式存在，各自放在自己的 Git 仓库里，由一个叫 `wtool` 的小引擎统一安装。

---

## 1. 项目总览

### 1.1 它是怎么工作的

在新机器上重建开发环境，麻烦的从来不是"装"这个动作本身，而是四个副作用：**装过什么记不住、装在哪儿说不清、装错了撤不掉、换台机器得重来一遍**。

`wtool` 的做法是把这件事拆成三个互不混淆的动作，每一个都边界清晰：

| 动作 | 做什么 | 可逆吗 |
|---|---|---|
| `install` | 把配置铺到位：建软链接、往 shell 配置里写一段托管块 | **完全可逆**，一条命令原样撤回 |
| `provision` | 装系统软件包、编译源码、改系统文件 | **不可逆**，所以单独分开，不混进 install |
| `publish` | 把项目打包发到 GitHub Release | —— |

把前两个分得这么清楚，是因为它们混在一起就会毁掉"可逆"这个承诺：`apt install` 装进去的东西没法干净地拿回来，一旦和软链接混在同一个命令里，"撤销"就成了一句空话。

**配置住在仓库里，系统里只留软链接。** 这是整套设计的核心。一个项目不管有多少文件，装到系统里可能只是：

- 一个软链接，从 `~/.config/某工具/配置` 指向仓库里的文件；
- 一段被标记出来的 shell 配置块，里面只有一行 `source`。

所以卸载 = 删掉链接和那段块，系统回到原样。仓库可以随便搬到别的地方，把链接重新指一遍就行。

**项目只需要声明，不需要写安装逻辑。** 每个项目里有一个 `wtool.xml`，用几行 XML 说清楚"我有哪些文件要被 source""哪些文件要软链到哪里"。剩下的——建链接、写 shell 块、保证顺序、记录状态、支持卸载——全部由 `wtool` 负责。

只有通用机制表达不了的事情，项目才需要额外提供一个脚本：

| 脚本 | 什么时候需要 | 对应的命令 |
|---|---|---|
| `build.sh` | 这个项目需要编译或下载（比如从源码编译一个编辑器） | `wtool build <项目>` |
| `install.sh` | 装它需要通用机制做不到的步骤 | `wtool install <项目>` |
| `publish.sh` | 发布时不能只打一个源码包（比如产物在容器里） | `wtool publish <项目>` |

**这三个脚本在不在，就代表这个项目有没有这三项能力。** `wtool` 不带参数跑一下，会看到一张表，哪一项亮着绿灯就说明这个项目能做什么：

```
项目                           prio  build  install  publish
----------------------------------------------------------------
bootstrap                      5     ·      ●        ●
os/ubuntu                      5     ·      ●        ●
shell/zsh                      20    ·      ●        ●
editor/astronvim_v5            70    ●      ●        ●
terminal/tmux                  50    ·      ●        ●
```

- 亮绿色的 ● ：项目提供了对应的脚本，能力由脚本定义
- 绿色的 ● ：`wtool` 的通用机制就能办到（大多数纯配置项目都是这种）
- 灰色的 · ：这个项目没这项能力

【图片占位】![wtool 能力总览](.pic/table.png)

<!-- TODO: 在装好 wtool 的机器上执行下面这条命令，把输出截图保存为 .pic/table.png
     wtool
     建议终端宽度 100 列以上，保留颜色，这样"亮绿/绿/灰"的区别看得出来。
-->

### 1.2 现在有哪些项目

| 项目 | 一句话简介 |
|---|---|
| [wtool-base](https://github.com/allinkernel/wtool) | 你现在看的这份文档。只有文档，没有工具 |
| [wtool-bootstrap](https://github.com/allinkernel/wtool-bootstrap) | 引擎本体：`wtool` 命令、安装/卸载机制、清单解析、发布逻辑。其他项目都靠它 |
| [wtool-harness](https://github.com/allinkernel/wtool-harness) | 给 AI 编码助手用的工作笔记和约定，不是给人看的 |
| [wtool-os-ubuntu](https://github.com/allinkernel/wtool-os-ubuntu) | Ubuntu 上要装的系统软件包清单，以及把 apt 源换成国内镜像 |
| [wtool-zsh](https://github.com/allinkernel/wtool-zsh) | zsh 自身的配置和补全别名 |
| [wtool-ohmyzsh](https://github.com/allinkernel/wtool-ohmyzsh) | oh-my-zsh 本体，带自己的定制和插件选择 |
| [wtool-tmux-config](https://github.com/allinkernel/wtool-tmux-config) | tmux 配置，外加一组显示 CPU/内存/磁盘/网络的小脚本 |
| [wtool-fzf-binary](https://github.com/allinkernel/wtool-fzf-binary) | fzf 的预编译二进制，省得每台机器重编 |
| [wtool-repo](https://github.com/allinkernel/wtool-repo) | `repo` 工具（管理多仓库的那个）和它的快捷命令 |
| [wtool-astronvim_v5](https://github.com/allinkernel/wtool-astronvim_v5) | 一整套 Neovim 环境：编译 nvim、装插件、装语言服务器、打成发布包 |
| [wtool-astronvim_v5_config](https://github.com/allinkernel/wtool-astronvim_v5_config) | 上面那套环境的具体配置（快捷键、主题、插件选择） |
| [typora-LightMindTheme](https://github.com/allinkernel/typora-LightMindTheme) | Typora 的一个自制主题 |

每个项目的细节看它自己的 README（点上面的名字）。

---

## 2. 没有 `git clone` 的时候怎么装

有些机器（比如公司内网）访问不了 GitHub 的命令行，或者干脆只让用浏览器下载。这种情况下不用 `git`，直接从网页把打包好的文件下下来就行。

每个项目的最新版本都在它自己的 Release 页面里，包已经按正确目录结构打好，**全部下载、解开，得到的就是一个完整的工作区**。

<!-- >>> wtool:downloads >>> -->
<!-- 这一块由 `wtool publish` 自动重写，不要手改。 -->

每个项目的最新发布包都在它自己的 release 页面上。
全部下载并解开之后，你会得到一个完整的工作区目录。

| 项目 | 版本 | 包 | 大小 |
|---|---|---|---|
| `bootstrap` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-bootstrap/releases/tag/snapshot-2026-09-15) | [bootstrap-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-bootstrap/releases/download/snapshot-2026-09-15/bootstrap-2026-09-15.tar.gz) | 86.4K |
| `harness` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-harness/releases/tag/snapshot-2026-09-15) | [harness-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-harness/releases/download/snapshot-2026-09-15/harness-2026-09-15.tar.gz) | 30.4K |
| `lightmind` | [snapshot-2026-09-15](https://github.com/allinkernel/typora-LightMindTheme/releases/tag/snapshot-2026-09-15) | [themes-typora-lightmind-2026-09-15.tar.gz](https://github.com/allinkernel/typora-LightMindTheme/releases/download/snapshot-2026-09-15/themes-typora-lightmind-2026-09-15.tar.gz) | 1.2M |
| `os/ubuntu` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-os-ubuntu/releases/tag/snapshot-2026-09-15) | [os-ubuntu-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-os-ubuntu/releases/download/snapshot-2026-09-15/os-ubuntu-2026-09-15.tar.gz) | 4.0K |
| `shell/oh-my-zsh` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-ohmyzsh/releases/tag/snapshot-2026-09-15) | [shell-oh-my-zsh-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-ohmyzsh/releases/download/snapshot-2026-09-15/shell-oh-my-zsh-2026-09-15.tar.gz) | 3.0M |
| `shell/zsh` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-zsh/releases/tag/snapshot-2026-09-15) | [shell-zsh-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-zsh/releases/download/snapshot-2026-09-15/shell-zsh-2026-09-15.tar.gz) | 2.2K |
| `terminal/fzf` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-fzf-binary/releases/tag/snapshot-2026-09-15) | [terminal-fzf-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-fzf-binary/releases/download/snapshot-2026-09-15/terminal-fzf-2026-09-15.tar.gz) | 1.7M |
| `terminal/tmux` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-tmux-config/releases/tag/snapshot-2026-09-15) | [terminal-tmux-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-tmux-config/releases/download/snapshot-2026-09-15/terminal-tmux-2026-09-15.tar.gz) | 4.5K |
| `tools/repo` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool-repo/releases/tag/snapshot-2026-09-15) | [tools-repo-2026-09-15.tar.gz](https://github.com/allinkernel/wtool-repo/releases/download/snapshot-2026-09-15/tools-repo-2026-09-15.tar.gz) | 5.4K |
| `wtool-base` | [snapshot-2026-09-15](https://github.com/allinkernel/wtool/releases/tag/snapshot-2026-09-15) | [wtool-base-2026-09-15.tar.gz](https://github.com/allinkernel/wtool/releases/download/snapshot-2026-09-15/wtool-base-2026-09-15.tar.gz) | 23.0K |

### bash（Linux / macOS / WSL）

```bash
mkdir -p ~/self && cd ~/self
curl -fL -o bootstrap-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-bootstrap/releases/download/snapshot-2026-09-15/bootstrap-2026-09-15.tar.gz
curl -fL -o harness-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-harness/releases/download/snapshot-2026-09-15/harness-2026-09-15.tar.gz
curl -fL -o themes-typora-lightmind-2026-09-15.tar.gz \
  https://github.com/allinkernel/typora-LightMindTheme/releases/download/snapshot-2026-09-15/themes-typora-lightmind-2026-09-15.tar.gz
curl -fL -o os-ubuntu-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-os-ubuntu/releases/download/snapshot-2026-09-15/os-ubuntu-2026-09-15.tar.gz
curl -fL -o shell-oh-my-zsh-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-ohmyzsh/releases/download/snapshot-2026-09-15/shell-oh-my-zsh-2026-09-15.tar.gz
curl -fL -o shell-zsh-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-zsh/releases/download/snapshot-2026-09-15/shell-zsh-2026-09-15.tar.gz
curl -fL -o terminal-fzf-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-fzf-binary/releases/download/snapshot-2026-09-15/terminal-fzf-2026-09-15.tar.gz
curl -fL -o terminal-tmux-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-tmux-config/releases/download/snapshot-2026-09-15/terminal-tmux-2026-09-15.tar.gz
curl -fL -o tools-repo-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool-repo/releases/download/snapshot-2026-09-15/tools-repo-2026-09-15.tar.gz
curl -fL -o wtool-base-2026-09-15.tar.gz \
  https://github.com/allinkernel/wtool/releases/download/snapshot-2026-09-15/wtool-base-2026-09-15.tar.gz
tar -xf bootstrap-2026-09-15.tar.gz
tar -xf harness-2026-09-15.tar.gz
tar -xf themes-typora-lightmind-2026-09-15.tar.gz
tar -xf os-ubuntu-2026-09-15.tar.gz
tar -xf shell-oh-my-zsh-2026-09-15.tar.gz
tar -xf shell-zsh-2026-09-15.tar.gz
tar -xf terminal-fzf-2026-09-15.tar.gz
tar -xf terminal-tmux-2026-09-15.tar.gz
tar -xf tools-repo-2026-09-15.tar.gz
tar -xf wtool-base-2026-09-15.tar.gz
```

跑完 `~/self/wtool/` 就是一个完整的工作区。
接着 `cd ~/self/wtool && ./bootstrap/install.sh`（第一次要用完整路径，
它会把根目录的 `./install.sh` 等入口补齐，之后就能直接用短的了）。

### PowerShell（Windows 10 及以上自带 tar）

```powershell
$d = "$HOME\self"; New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Location $d
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-bootstrap/releases/download/snapshot-2026-09-15/bootstrap-2026-09-15.tar.gz" -OutFile "bootstrap-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-harness/releases/download/snapshot-2026-09-15/harness-2026-09-15.tar.gz" -OutFile "harness-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/typora-LightMindTheme/releases/download/snapshot-2026-09-15/themes-typora-lightmind-2026-09-15.tar.gz" -OutFile "themes-typora-lightmind-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-os-ubuntu/releases/download/snapshot-2026-09-15/os-ubuntu-2026-09-15.tar.gz" -OutFile "os-ubuntu-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-ohmyzsh/releases/download/snapshot-2026-09-15/shell-oh-my-zsh-2026-09-15.tar.gz" -OutFile "shell-oh-my-zsh-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-zsh/releases/download/snapshot-2026-09-15/shell-zsh-2026-09-15.tar.gz" -OutFile "shell-zsh-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-fzf-binary/releases/download/snapshot-2026-09-15/terminal-fzf-2026-09-15.tar.gz" -OutFile "terminal-fzf-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-tmux-config/releases/download/snapshot-2026-09-15/terminal-tmux-2026-09-15.tar.gz" -OutFile "terminal-tmux-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-repo/releases/download/snapshot-2026-09-15/tools-repo-2026-09-15.tar.gz" -OutFile "tools-repo-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool/releases/download/snapshot-2026-09-15/wtool-base-2026-09-15.tar.gz" -OutFile "wtool-base-2026-09-15.tar.gz"
tar -xf bootstrap-2026-09-15.tar.gz
tar -xf harness-2026-09-15.tar.gz
tar -xf themes-typora-lightmind-2026-09-15.tar.gz
tar -xf os-ubuntu-2026-09-15.tar.gz
tar -xf shell-oh-my-zsh-2026-09-15.tar.gz
tar -xf shell-zsh-2026-09-15.tar.gz
tar -xf terminal-fzf-2026-09-15.tar.gz
tar -xf terminal-tmux-2026-09-15.tar.gz
tar -xf tools-repo-2026-09-15.tar.gz
tar -xf wtool-base-2026-09-15.tar.gz
```

跑完 `$HOME\self\wtool` 就是一个完整的工作区。
<!-- <<< wtool:downloads <<< -->

下载解压完成之后，你会得到一个 `~/self/wtool` 目录。进去，跑 `bootstrap/` 下面那个：

```bash
cd ~/self/wtool
./bootstrap/install.sh
```

这一次要用完整路径——解压出来的工作区还没有根目录那几个入口（`./install.sh`、`./README.md` 之类）。那些是 `repo` 工具在 `repo sync` 时按清单建的，而你是手动解压的。第一次跑 `bootstrap/install.sh` 会顺手把它们补齐：

```
wtool-bootstrap: 工作区入口（/home/you/self/wtool）
wtool-bootstrap:   install.sh -> bootstrap/install.sh
wtool-bootstrap:   README.md -> wtool-base/README.md
...
```

之后 `./install.sh` 就能直接用了，和 `repo sync` 出来的工作区完全一样。

它会先把引擎挂到 `~/.wtool/bootstrap`，然后按顺序处理每个项目（装系统包、编译、建软链、写 shell 配置）。中途要改系统文件时会问你确认，照着提示走即可。

---

## 3. 怎么用

装完之后，`wtool` 命令就可以在任何目录下直接用了。

### 3.1 看总览

```bash
wtool
```

不带参数跑一下，就是第 1 节里那张表：哪些项目、各自能做什么、装过没有、发布过没有。

```bash
wtool doctor     # 表格 + 环境诊断（版本、系统、状态目录、缺什么）
```

### 3.2 装

```bash
wtool install terminal/tmux       # 装一个项目
wtool install ./terminal/tmux     # 也可以用目录路径
wtool uninstall terminal/tmux     # 撤销，系统回到装之前
```

`install` 是完全可逆的。想先看看它会做什么：

```bash
wtool install terminal/tmux --dry-run
```

它会打印出计划（要建哪些链接、要写哪几段 shell 块），但不真的动系统。

一次装好所有项目：

```bash
wtool bootstrap
```

【图片占位】![wtool install 的输出](.pic/install.png)

<!-- TODO: 在一台干净机器（或容器）上执行，把输出截图保存为 .pic/install.png
     wtool bootstrap
     截图建议包含开始几行和结束几行，能看出"按项目逐个处理"的结构。
-->

### 3.3 构建

有些项目需要编译或下载才能用（比如那套 Neovim 环境要从源码编编辑器）：

```bash
wtool build                      # 列出哪些项目可以构建
wtool build editor/astronvim_v5  # 构建其中一个
```

构建这一步是可以反复跑的，中断了重来也不会坏。它慢，但只在需要的时候才需要跑——纯配置类的项目都没有这一步。

### 3.4 发布

把你改动过的项目打包发到它自己的 GitHub Release 页面：

```bash
wtool publish                    # 发布所有项目
wtool publish terminal/tmux      # 只发一个
wtool publish --dry-run          # 先看计划
```

默认行为是把项目的源码打成一个包（解压后目录结构和 `git clone` 出来的一模一样）传上去。需要编译产物的项目会走自己的 `publish.sh`，比如 Neovim 那套会在容器里完成构建再打包。

发布完成后，本文档第 2 节的下载链接会自动更新成最新的 —— 那一段是 `wtool publish` 重写的，不用手动维护。

### 3.5 其他命令

```bash
wtool list                       # 看已登记的软链接
wtool status                     # 检查登记的链接是不是都还在
wtool validate <项目目录>         # 检查某个项目的 wtool.xml 写得对不对
wtool env                        # 输出可用的环境变量
wtool init <目录>                 # 新建一个项目（生成模板）
wtool provision <项目目录>         # 装系统包 / 编译源码（不可逆，单独一条命令）
wtool version
```

---

以上只是速查。**完整的说明——项目结构、每个命令的细节、所有子项目的索引——在 [guide.md](guide.md)。**
