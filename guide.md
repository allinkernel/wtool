# wtool 使用指南

这份文档讲三件事：**这套东西是怎么组织的**、**每个命令具体做什么**、**现在有哪些项目**。

如果你还没装上，先看 [README.md](README.md)。这里假设你已经有一个能用的 `wtool` 命令了。

---

## 1. 项目是怎么组织的

### 1.1 一个项目长什么样

整个集合放在一个目录里（默认 `~/self/wtool`，叫什么名字都行），下面按用途分层：

```
wtool/                          整个集合的根目录
├── bootstrap/                  引擎自己也是一个项目
├── os/ubuntu/                  按系统分的项目
├── shell/zsh/
├── terminal/tmux/
├── editor/astronvim_v5/        可以嵌套：这个目录下面还有两个独立项目
│   ├── astronvim_v5_config/
│   └── nvim/
└── themes/typora/lightmind/
```

每个**项目**是一个独立的 Git 仓库，目录层次就是它的身份（`terminal/tmux` 这个名字既是路径也是 ID）。

一个项目最少只需要两部分：

```
terminal/tmux/
├── wtool.xml      声明：这个项目有哪些东西要装、装到哪
├── tmux.conf      实际的配置文件
├── env.zsh        需要在 shell 里生效的环境变量（可选）
└── build.sh       需要编译/下载时才有（可选）
    install.sh     通用机制装不了时才有（可选）
    publish.sh     发布要特殊处理时才有（可选）
```

`wtool.xml` 是最小的一份声明，长这样：

```xml
<wtool schema="1" id="terminal/tmux" priority="50">

  <!-- 把本目录的 tmux.conf 软链到 ~/.tmux.conf -->
  <link src="tmux.conf" dest=".tmux.conf"/>

  <!-- 这段环境变量会被写进 shell 配置里 source 掉 -->
  <env src="env.zsh" shells="zsh,bash"/>

  <!-- 需要装系统包时（不可逆，和上面两条分开） -->
  <provision src="provision/packages.yaml" marker="tmux-deps"/>

</wtool>
```

四类元素，认得这些就够了：

| 元素 | 作用 | 可逆 |
|---|---|---|
| `<link src dest>` | 把项目里的文件软链到 `$HOME` 下 | 是 |
| `<env src shells>` | 在 shell 配置里插入一段托管块，`source` 这个文件 | 是 |
| `<provision src>` | 装系统包 / 跑脚本（不可逆） | 否 |
| `<publish kind>` | 怎么发布到 GitHub Release | —— |

`priority` 决定处理顺序，数字小的先来。`bootstrap` 是 5，因为它要最早把环境变量准备好；纯配置项目一般 100 也无所谓。

### 1.2 `wtool` 负责什么，项目负责什么

这是整套设计的重点，值得单独说清楚：

**项目只提供 `wtool.xml`、自己需要的脚本、和自己的源码。剩下全部交给 `wtool`。**

具体来说，`wtool` 负责：

- 找到项目、按优先级排序
- 建软链接，并且保证**重复安装不会出问题**（跑一百遍和跑一遍结果一样）
- 往 shell 配置里写托管块，并保证块的位置由优先级决定、不会重复堆积
- 记录"做过什么"，这样 `uninstall` 能逆着来，一字不差地还原
- 检查项目目录干不干净（有未提交改动就拒绝安装，免得装进去的东西说不清版本）
- 解析 `wtool.xml`、报错、校验

项目负责：

- 说清楚自己有什么（`wtool.xml`）
- 通用机制表达不了的部分，写进 `build.sh` / `install.sh` / `publish.sh`

**一条不能破的规矩：项目里的脚本不要再回头调 `wtool`。** 因为 `wtool install` 本来就会去跑项目的 `install.sh`，如果 `install.sh` 又调 `wtool install`，就是一个死循环。脚本只管做自己的事，`wtool` 会在合适的时机调用它。

### 1.3 新建一个项目

```bash
wtool init ./terminal/ripgrep
```

它会生成一个目录、一份 `wtool.xml` 骨架、一个 `env.zsh`，然后提示你往下填。

如果这个项目还需要脚本，加上对应的开关：

```bash
wtool init ./editor/foo --with-build              # 需要编译
wtool init ./editor/foo --with-install            # 有自定义安装步骤
wtool init ./editor/foo --with-publish            # 发布要特殊处理
wtool init ./editor/foo --all                     # 三个都要
```

**不需要的脚本就别要。** `wtool` 的表格里那三列是靠脚本在不在点亮的，放一个空壳进去，等于在表格里撒谎——别人看到绿灯，照着做却发现什么都没发生。

生成之后，把 `wtool.xml` 填好，然后校验一下：

```bash
wtool validate ./terminal/ripgrep
```

选项和元素写错了它都会指出来，不用等到安装的时候才发现。

最后，把这个项目登记到清单里（清单是 `repo` 工具管的那个 `default.xml`），别人 `repo sync` 的时候才会拉到它。

### 1.4 目录之外的东西放在哪

装的痕迹只落在这几个地方，其他一概不动：

| 位置 | 放什么 |
|---|---|
| `~/self/wtool/`（或你选的工作区目录） | 项目本体，都是 Git 仓库 |
| `~/.local/state/wtool/` | 状态：谁装过、软链登记、每个项目的操作记录 |
| `~/.wtool/links/<项目 ID>` | 指向项目目录的稳定地址，配置文件里引用它就永远不怕仓库搬家 |
| `~/.zshrc` / `~/.bashrc` | 每个项目一段托管块，用注释标记出边界 |

除了第四项会动你的 shell 配置（而且只动标记之间的那几行），别的都在自己的地盘里。

---

## 2. 命令

### 总览

| 命令 | 作用 |
|---|---|
| `wtool` | 不带参数：打印项目总览表 |
| `wtool doctor` | 总览表 + 环境诊断 |
| `wtool init <目录>` | 新建项目，生成模板 |
| `wtool build [<项目>…]` | 跑项目的 `build.sh` |
| `wtool install <项目>` | 安装（软链接 + shell 块 + 项目的 `install.sh`） |
| `wtool uninstall <项目>` | 卸载，完全还原 |
| `wtool provision <项目>` | 装系统包 / 编译源码 / 改系统文件（不可逆） |
| `wtool publish [<项目>…]` | 打包发到 GitHub Release |
| `wtool bootstrap` | 一次装好所有项目 |
| `wtool table` | 项目总览表（`--verbose` 看细节，`--summary` 看汇总） |
| `wtool list` | 已登记的软链接列表 |
| `wtool status` | 检查登记的软链接是否都还在 |
| `wtool validate <项目>` | 校验 `wtool.xml` |
| `wtool env` | 输出环境变量（`--quiet` / `--json`） |
| `wtool version` | 版本 |

### `wtool` / `wtool table`

```
项目                           prio  build  install  publish
----------------------------------------------------------------
bootstrap                      5     ·      ●        ●
editor/astronvim_v5            70    ●      ●        ●
```

- **亮绿 ●** — 项目提供了对应的脚本，这项能力由脚本自己定义
- **绿 ●** — `wtool` 的通用机制就能办到
- **灰 ·** — 没这项能力

加 `--verbose` 会在表下面列出每个项目的细节：装过没有、provision 跑过没有、发布过什么版本。

### `wtool build`

```bash
wtool build                       # 列出哪些项目有 build.sh
wtool build editor/astronvim_v5
wtool build astronvim_v5 --dry-run
```

`build` 只做一件事：找到项目的 `build.sh` 然后跑它。`wtool` 不对"构建"做任何假设——编什么、要不要起容器、产物放哪，全由脚本决定。

约定有几条：

- 脚本要**能重复跑**（中断了重来不会坏）
- 脚本要支持 `--dry-run`，这样 `--dry-run` 能一层层透传下去
- 脚本拿到的 stdin 是 `/dev/null`——不要写交互式提问，没人应答

构建是很慢的一步，但只有需要的项目才有。

### `wtool install`

```bash
wtool install terminal/tmux
wtool install ./terminal/tmux
wtool install terminal/tmux --dry-run
wtool install terminal/tmux --force      # 目录有未提交改动也照装
wtool install terminal/tmux --no-script  # 只做通用机制，不跑项目的 install.sh
```

顺序是固定的：

1. 检查项目目录是不是干净的（这是为了记清楚"装的是哪个版本"）
2. 按 `wtool.xml` 建软链接、写 shell 托管块
3. 如果项目有 `install.sh`，跑它

第 3 步放在最后，是因为这时候 `~/.wtool/links/<项目 ID>` 已经建好了，脚本可以直接引用这个稳定地址，而不用关心仓库实际在哪。

**这个命令可以在任何机器上跑，跑一百遍结果都一样。**

### `wtool uninstall`

```bash
wtool uninstall terminal/tmux
wtool uninstall --id terminal/tmux
```

逆着 `install` 的记录来，把链接删掉、shell 块抹掉、文件还原。如果某个软链接被换成了真实文件（你自己改过），它会保留不动，不会误删你的东西。

### `wtool provision`

```bash
wtool provision os/ubuntu --with-system
```

装系统软件包、换 apt 源、编译源码。**这是唯一不可逆的命令**，所以它和 `install` 严格分开，绝不会被 `install` 顺手调用。

加 `--with-system` 才会动 `$HOME` 之外的文件（比如 `/etc/apt/sources.list`），而且动之前会备份，`uninstall` 的时候还原。

### `wtool publish`

```bash
wtool publish                       # 发布所有项目
wtool publish terminal/tmux         # 只发一个
wtool publish tmux                  # 项目 ID 的末段也行
wtool publish --dry-run
wtool publish --tag=v1.0            # 指定 tag（默认按日期）
wtool publish terminal/tmux --out=/tmp/pkg   # 产物留在本地，先看看再传
```

默认把项目源码打成一个包传到它自己的 GitHub Release：

```
wtool/terminal/tmux/tmux.conf
wtool/terminal/tmux/wtool.xml
...
```

**包里的第一层固定是 `wtool/`**，所以不管你的工作区目录叫什么名字，解压出来的路径结构都是一样的——下载、解开、就得到一个能直接用的工作区。这就是 [README](README.md) 第 2 节那个"没有 git clone 时怎么装"能成立的原因。

带编译产物的项目（比如 Neovim 那套）走自己的 `publish.sh`，可以在里面起容器、编译、分卷，最后把产物丢给 `wtool` 上传。

发布结束后，本文档所在仓库 README 里的下载链接会自动重写成最新的——那一段是脚本生成的，不用手动维护。

### `wtool bootstrap`

```bash
wtool bootstrap
wtool bootstrap --install-only     # 不装系统包、不编译，只做软链接和 shell 块
```

按 `priority` 顺序把所有项目过一遍：provision → build → install。

**第一次装一台新机器，用这条命令就够了。**

【图片占位】![wtool bootstrap 的输出](.pic/bootstrap.png)

<!-- TODO: 在干净环境里执行，把输出截图保存为 .pic/bootstrap.png
     wtool bootstrap --install-only
     建议截到"按项目逐个处理"的那几行，能看出顺序和分节。
-->

### 其它

```bash
wtool list                 # 已登记的软链接
wtool status               # 检查它们是否都还在
wtool validate ./terminal/tmux
wtool env                  # eval "$(wtool env)" 可以立刻在当前 shell 生效
wtool env --json           # 给脚本用
```

---

## 3. 子项目

| 项目 | 仓库 | 简介 |
|---|---|---|
| `wtool-base` | [allinkernel/wtool](https://github.com/allinkernel/wtool) | 文档。你正在看的这份 |
| `bootstrap` | [allinkernel/wtool-bootstrap](https://github.com/allinkernel/wtool-bootstrap) | 引擎本体 |
| `harness` | [allinkernel/wtool-harness](https://github.com/allinkernel/wtool-harness) | 给 AI 助手用的工作笔记 |
| `os/ubuntu` | [allinkernel/wtool-os-ubuntu](https://github.com/allinkernel/wtool-os-ubuntu) | Ubuntu 系统包与 apt 镜像 |
| `shell/zsh` | [allinkernel/wtool-zsh](https://github.com/allinkernel/wtool-zsh) | zsh 配置 |
| `shell/oh-my-zsh` | [allinkernel/wtool-ohmyzsh](https://github.com/allinkernel/wtool-ohmyzsh) | oh-my-zsh 本体 |
| `terminal/tmux` | [allinkernel/wtool-tmux-config](https://github.com/allinkernel/wtool-tmux-config) | tmux 配置与状态脚本 |
| `terminal/fzf` | [allinkernel/wtool-fzf-binary](https://github.com/allinkernel/wtool-fzf-binary) | fzf 预编译二进制 |
| `tools/repo` | [allinkernel/wtool-repo](https://github.com/allinkernel/wtool-repo) | repo 工具 |
| `editor/astronvim_v5` | [allinkernel/wtool-astronvim_v5](https://github.com/allinkernel/wtool-astronvim_v5) | Neovim 环境的构建与发布 |
| `editor/astronvim_v5/astronvim_v5_config` | [allinkernel/wtool-astronvim_v5_config](https://github.com/allinkernel/wtool-astronvim_v5_config) | 上面那套的具体配置 |
| `editor/astronvim_v5/nvim` | [neovim/neovim](https://github.com/neovim/neovim) | 上游 Neovim 源码（不是我们的项目） |
| `themes/typora/lightmind` | [allinkernel/typora-LightMindTheme](https://github.com/allinkernel/typora-LightMindTheme) | Typora 主题 |

每个项目的详细说明（它装了什么、有哪些脚本、怎么改）由**项目自己**的 README 维护，点仓库名进去看。

新增项目后，这份表不会自动更新——它是写在文档里的。要加一个项目，就在 `default.xml` 里登记它，然后把上面这张表补一行。

---

## 4. 出问题了怎么办

**`wtool` 报"不是 git 仓库"或"有未提交改动"**

这是故意的：安装前要能确定"装的是哪个版本"。先提交，或者确实不在乎版本就加 `--force`。

**装完发现某个链接不对**

```bash
wtool status                       # 看哪些登记的链接不见了
wtool install <项目> --force       # 重新装一遍
```

`install` 是幂等的，重装不会出问题。

**想彻底退回去**

```bash
wtool uninstall <项目>              # 一个项目
./uninstall.sh                     # 整个工作区（在工作区根目录跑）
```

**shell 里 `wtool` 命令找不到**

引擎挂在 `~/.wtool/bootstrap`，靠 shell 托管块加进 `PATH`。重开一个终端，或者：

```bash
exec zsh
```

**想看看 `wtool` 到底把东西放哪了**

```bash
wtool doctor                       # 环境、路径、状态目录
wtool list                         # 每条软链接的目标
cat ~/.local/state/wtool/<项目 ID>/journal.tsv   # 这个项目做过什么
```
