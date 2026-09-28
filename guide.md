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
└── scripts/       通用机制表达不了的动作，**只有两种**（可选）
    ├── build.sh     需要自己产出时（产物写进 output/）
    └── install.sh   有自定义安装步骤时
```

下载别人的包、打包上传都不用写脚本 —— 那是引擎自带的命令（`download-release` /
`unpack-release` / `pack-release` / `publish-release`），每个项目走同一条路。

`wtool.xml` 是最小的一份声明，长这样：

```xml
<wtool schema="1" id="terminal/tmux" priority="50">

  <!-- 把本目录的 tmux.conf 软链到 ~/.tmux.conf -->
  <link src="tmux.conf" dest=".tmux.conf"/>

  <!-- 环境变量/命令：zsh 和 bash 各一份（内容等价） -->
  <env src="env.zsh"  shells="zsh"/>
  <env src="env.bash" shells="bash"/>

  <!-- 需要装系统包时（不可逆，和上面两条分开） -->
  <provision src="provision/packages.yaml" marker="tmux-deps"/>

</wtool>
```

四类最常用的元素，认得这些就够了：

| 元素 | 作用 | 可逆 |
|---|---|---|
| `<link src dest>` | 把项目里的文件软链到 `$HOME` 下 | 是 |
| `<env src shells>` | 在 shell 配置里插入一段托管块，`source` 这个文件 | 是 |
| `<provision src>` | 装系统包 / 跑脚本（不可逆） | 否 |
| `<publish kind>` | 怎么发布到 GitHub Release | —— |

另外还有两类，用到时再看对应项目的 `wtool.xml`：`<system-file>`（写 `$HOME` 之外的系统文件，比如换 apt 源；写前备份，卸载时还原）和 `<source>`（源码编译型项目）。

> **`<env>` 要两个 shell 各写一份**（`env.zsh` + `env.bash`，内容等价）。
> 有人机器上没有 zsh，只写一份的话另一个 shell 的用户敲命令是 `command not found`，
> 而 shell 配置里看起来明明装过了 —— 这种半装状态最难查。
> 如果内容两个 shell 都认（只 export 变量、不做 zsh/bash 特有的事），
> 也可以一份 `env.sh` 配 `shells="zsh,bash"`，`tools/android_repack` 就是这么写的。

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
- 通用机制表达不了的部分，写进 `scripts/` 下的 `build.sh` / `install.sh`（**只有这两种**）

**一条不能破的规矩：项目里的脚本不要再回头调 `wtool`。** 因为 `wtool install` 本来就会去跑项目的 `install.sh`，如果 `install.sh` 又调 `wtool install`，就是一个死循环。脚本只管做自己的事，`wtool` 会在合适的时机调用它。

### 1.3 新建一个项目

```bash
wtool init ./terminal/ripgrep
```

它会生成一个目录、一份 `wtool.xml` 骨架、一个 `env.zsh`，然后提示你往下填。

如果这个项目还需要脚本，加上对应的开关：

```bash
wtool init ./editor/foo --with-build              # 需要自己编译 / 要产出东西
wtool init ./editor/foo --with-install            # 有自定义安装步骤
wtool init ./editor/foo --all                     # 两个都要
```

（`--with-download` / `--with-publish` **已经取消**：下载和发布不用项目写脚本，
敲了会报错告诉你现在该用什么。项目脚本只剩 `build.sh` / `install.sh` 两种。）

**不需要的脚本就别要。** `wtool` 的表格里那几列是靠脚本在不在点亮的，放一个空壳进去，等于在表格里撒谎——别人看到那格写着「可执行」，照着做却发现什么都没发生。

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
| `$WTOOL_PREFIX`（默认 `~/.wtool/usr`） | 项目产出的实体文件：编译出来的程序、下载下来的二进制 |
| `~/.wtool/wtool-work-dir/links/<项目 ID>` | 指向项目目录的稳定地址，配置文件里引用它就永远不怕仓库搬家 |
| `~/.wtool/.zshrc` 等 | wtool 生成的汇总文件：各项目的 env 块按优先级拼在这里 |
| `~/.local/state/wtool/` | 状态：谁装过、软链登记、每个项目的操作记录 |
| `~/.zshrc` / `~/.bashrc` | 只有**一段** loader 块（注释标出边界），负责 source 上面那个汇总文件 |

`$HOME` 里除了这一小段 loader 和几个软链接（比如 `~/.tmux.conf`），不放别的东西；大件都住在工作区或 `~/.wtool/` 下面，所以卸载能撤干净。

---

## 2. 命令

### 总览

| 命令 | 作用 |
|---|---|
| `wtool` | 不带参数：打印项目总览表 |
| `wtool doctor` | 总览表 + 环境诊断（`--quiet` 只输出环境变量的 export 行） |
| `wtool init <目录>` | 新建项目，生成模板 |
| `wtool build [<项目>…]` | 跑项目的 `build.sh`，产物写进 `output/` |
| `wtool download-release [<项目>…]` | 照项目里提交的 `scripts/release.json`，从发布页把包下到 `release/`（**只下载**） |
| `wtool unpack-release <项目>…` | 校验 + 解开 `release/` 里的包，写进 `output/` |
| `wtool install <项目目录\|项目 id\|all>` | 安装（软链接 + shell 块 + 项目的 `install.sh`）；`all` = 装所有不需要你决策的项目（和 `wtool bootstrap` 同一条路） |
| `wtool uninstall <项目目录>` / `--id <项目>` | 卸载，完全还原 |
| `wtool sudo-install <项目目录>` | 装系统包 / 改系统文件（不可逆，和 `install` 严格分开） |
| `wtool sudo-uninstall <项目目录>` | 撤销 `sudo-install` |
| `wtool pack-release <项目>…` | 打包写进项目的 `release/`（不联网） |
| `wtool publish-release [<项目>…]` | 把 `release/` 里的东西传到 GitHub Release（**只上传**） |
| `wtool bootstrap` | 把所有项目 `install` 一遍（不做系统层），需要先产出的会跳过 |
| `wtool sudo-bootstrap` | 所有项目的 `sudo-install` |
| `wtool status` | 登记表 + 检查登记的软链接是否都还在 |
| `wtool validate <项目目录>` | 校验 `wtool.xml` |
| `wtool version` | 版本 |

### `wtool`（裸跑）

```
┌──────────────────────┬──────┬────────┬─────────┐
│ 项目                 │ prio │ build  │ install │
├──────────────────────┼──────┼────────┼─────────┤
│ bootstrap            │ 5    │ 不支持 │ 可执行  │
│ os/ubuntu            │ 5    │ 不支持 │ 不支持  │
│ shell/oh-my-zsh      │ 10   │ 不支持 │ 可执行  │
│ shell/zsh            │ 20   │ 不支持 │ 可执行  │
│ tools/repo           │ 40   │ 不支持 │ 可执行  │
│ tools/android_repack │ 45   │ 不支持 │ 可执行  │
│ tools/gerrit-gate    │ 46   │ 不支持 │ 可执行  │
│ harness/dsh-conf     │ 48   │ 不支持 │ 可执行  │
│ terminal/tmux        │ 50   │ 不支持 │ 可执行  │
│ terminal/fzf         │ 60   │ 不支持 │ 可执行  │
│ editor/astronvim_v5  │ 70   │ 可执行 │ 待产出  │
│ lightmind            │ 100  │ 不支持 │ 不支持  │
└──────────────────────┴──────┴────────┴─────────┘
```

**只有两列能力**：`build` 和 `install`。发布和下载是全项目一样的引擎命令
（`pack-release` / `publish-release` / `download-release` / `unpack-release`），
不是某个项目的能力，所以不占表格的列。`wtool table` 这个名字已经删掉，敲它只会告诉你裸跑 `wtool`。

每格是四种状态之一（终端里带颜色）：`不支持` 红、`可执行` 黄、`待产出` 蓝、`已完成` 绿。
`待产出` 的意思是"能力有，但项目的 `output/` 里还是空的" —— 先 `wtool build`，
或者 `download-release` + `unpack-release`。`build` / `install` 是**你这台机器上的进度**，
跑过才会变绿（本地发布历史不打在表里，`--verbose` 会列出来）。

加 `--verbose` 会在表下面列出每个项目的细节（装过没有、provision 跑过没有、发布过什么版本），`--summary` 只多一行汇总。不带参数的 `wtool` 是 `--verbose --summary`。

### `wtool build` / `wtool download-release` / `wtool unpack-release`

```bash
wtool build                       # 列出哪些项目有 build.sh
wtool build editor/astronvim_v5
wtool build astronvim_v5 --dry-run

wtool download-release            # 列出哪些项目有现成的包可下（提交了 scripts/release.json）
wtool download-release editor/astronvim_v5   # 下到项目的 release/（只下载，逐个校验）
wtool unpack-release editor/astronvim_v5     # 校验分卷 + 拼接 + 解到 output/
```

`build` 只做一件事：找到项目的 `build.sh` 然后跑它 —— 编什么全由脚本决定，
**产物要落在项目的 `output/` 里**。

不过"要不要起容器"这件事是**声明**的，不是脚本里偷偷判断的：项目在 `wtool.xml` 里写
`<build kind="docker"/>`（每个发行版一个容器分层编）或 `<build kind="local"/>`
（本地直接编，默认）。好处是 `wtool` 能在**动手之前**告诉你这台机器行不行：

- 项目声明要容器，而这台机器上**没有 docker** → `wtool build` 直接拒绝
  （脚本一行都不跑），并给你三条命令：`download-release` → `unpack-release` → `install`。
  这正是"机器太弱就下现成的包"那条路 —— 不用你自己先判断。
- 项目声明了机器门槛（几个核、多少内存、多少磁盘），不够也一样拒绝；
  确定要硬上就加 `--force`（**没有 docker 是 `--force` 也编不了的**）。
- 同一个 `<build kind>` 还决定 `output/` 里有没有"每个发行版一格"那一层，
  所以同一个项目的两种装法（自己编 / 下现成的）产出的目录形状一定对得上。

拒绝时 `wtool build` 的退出码**不是 0** —— 什么也没干却报成功，最容易骗过自动化的调用方。

**要容器的那种项目，容器是 `wtool` 起的**：项目只写"哪个发行版用哪个基础镜像"和
"每一层装什么"，起容器、提交镜像、把每一层导出成安装产物都由引擎做。好处是
**可以断点续跑** —— 重跑 `wtool build` 不会重编已经编好的层，连 docker 里的镜像被清掉了
也能从项目自己的 `layer/` 目录装回来。只想编一个发行版就加 `--target=ubuntu_22.04`，
只想看它打算干什么就加 `--dry-run`。层之间会**按依赖并行**：父层编完，挂在它下面的层
就可以同时开工（默认同时 2 个，`--jobs=N` 调；`$WTOOL_LAYER_JOBS` 也行）。

`download-release` 只做一件事：照项目里**提交在仓库里**的 `scripts/release.json`
把该下的文件下到 `release/`，逐个校验校验值；已经下好的（校验值对得上）会跳过，
所以中断了重跑不会重下。`unpack-release` 再照包自带的 `dist.json` 校验每一卷、
按顺序拼起来、解到 `output/`。**这两条都不需要项目写脚本。**

**两条路（自己编 / 下载解开）产出落在完全相同的路径**，所以 `build + install` 和
`download-release + unpack-release + install` 结果一样，装的时候不需要知道东西是哪来的。
编一次几十分钟到几小时，下载几分钟——能下载就下载。

约定有几条：

- 项目脚本要**能重复跑**（中断了重来不会坏）
- 项目脚本要支持 `--dry-run`，这样 `--dry-run` 能一层层透传下去
- 项目脚本拿到的 stdin 是 `/dev/null`——不要写交互式提问，没人应答

构建是很慢的一步，但只有需要的项目才有。

### `wtool install`

```bash
cd <工作区目录>                            # install 认的是项目目录
wtool install terminal/tmux
wtool install ./terminal/tmux
wtool install terminal/tmux --dry-run
wtool install terminal/tmux --force      # 目录有未提交改动也照装
wtool install terminal/tmux --no-script  # 只做通用机制，不跑项目的 install.sh
```

`install` 要的是一个**项目目录**：在工作区根目录下写相对路径 `terminal/tmux`，
在别的地方就写全路径。（`build` / `download-release` / `unpack-release` / `publish-release`
不一样，它们认项目名，在哪个目录跑都行。）

顺序是固定的：

1. 检查项目目录是不是干净的（这是为了记清楚"装的是哪个版本"）
2. **引擎基建**：建中转链接（`~/.wtool/wtool-work-dir/links/<项目 ID>`）+ 写这个项目的 env 块
3. 如果项目有 `install.sh`，**跑它** —— 它把 `output/` 里的东西铺进 `~/.wtool/`
4. 按 `wtool.xml` 在 `$HOME` 里建软链，最后把各项目的 env 块汇总成一个文件

⚠️ **第 3 步在第 4 步之前，不能反**：第 4 步建的软链指向的正是第 3 步刚铺下的实体，
反了就是先建一堆悬空链接。而第 3 步排在第 2 步之后，是因为那时候中转链接已经建好了，
脚本可以直接引用这个稳定地址，不用关心仓库实际在哪。

**这个命令可以在任何机器上跑，跑一百遍结果都一样。**

### `wtool uninstall`

```bash
cd <工作区目录>
wtool uninstall terminal/tmux       # 给项目目录
wtool uninstall --id terminal/tmux  # 给项目名：在哪个目录跑都行
```

逆着 `install` 的记录来，把链接删掉、shell 块抹掉、文件还原。如果某个软链接被换成了真实文件（你自己改过），它会保留不动，不会误删你的东西。

**如果项目自带 `install.sh`，会先跑一次 `install.sh --uninstall`**，让项目自己把它装的大件（编译产物、下载的包）收走，然后再由 `wtool` 撤链接和状态。顺序不能反：链接先没了，脚本可能就找不到自己装的东西了。

### `wtool sudo-install` / `wtool sudo-uninstall` / `wtool sudo-bootstrap`

```bash
cd <工作区目录>
wtool sudo-install os/ubuntu      # 一个项目：装系统软件包、换 apt 源
wtool sudo-uninstall os/ubuntu    # 撤销：卸掉这次装的包、还原 /etc 下的文件
wtool sudo-bootstrap              # 所有项目的系统层
```

装系统软件包、改 `/etc` 下的文件（换 apt 源之类）。**这是可能要 sudo、要联网的一层**，
所以它和 `install` 严格分开、永不互相调用：`install` 永不要 sudo、永不联网，
`sudo-*` 永不碰你 `$HOME` 里的软链。

动 `/etc` 之前会备份，`sudo-uninstall` 的时候按记录还原；apt 包按"跑前跑后的差集"记账，
只卸这次装进来的。（旧名字 `provision` 已经删掉，敲它会报错指路。）

### `wtool pack-release` / `wtool publish-release`

**打包**（不联网，产出落在项目自己的 `release/` 目录里）：

```bash
wtool pack-release editor/astronvim_v5
```

出来的是一对包——**源码包**（整个项目）和**产物包**（`output/` 里的东西），
各配一个校验文件；大项目的产物包会切成若干分卷，外加一份 `dist.json` 说明每一卷。
同时写一份给人看的下载页 `docs/download.md`。

**上传**：

```bash
wtool publish-release                       # 发布所有项目
wtool publish-release terminal/tmux         # 只发一个
wtool publish-release tmux                  # 项目 ID 的末段也行
wtool publish-release --dry-run
wtool publish-release --tag=v1.0            # 指定 tag（默认按日期）
wtool publish-release terminal/tmux --out=/tmp/pkg   # 发布完把 release/ 里的产物另拷一份到 /tmp/pkg
```

它**只上传 `release/` 里已有的东西**：不打包、也不再调项目脚本 ——
要发新版本就先 `wtool pack-release`。传完之后写一份 `scripts/release.json`
（这一版发了什么、每个文件的校验值是多少），**记得把它提交进仓库**：
别人 `wtool download-release` 时就是照它下的。

**包里的第一层固定是 `wtool/`**：

```
wtool/terminal/tmux/tmux.conf
wtool/terminal/tmux/wtool.xml
...
```

所以不管你的工作区目录叫什么名字，解压出来的路径结构都是一样的——下载、解开、就得到一个能直接用的工作区。这就是 [README](README.md) 第 2 节那个"没有 git clone 时怎么装"能成立的原因。

带编译产物的项目（比如 Neovim 那套）先 `wtool build` 把产物编出来、再 `pack-release` ——
编译逻辑在它自己的 `scripts/build.sh` 里，打包上传是引擎的事。

发布结束后，本文档所在仓库 README 里的下载链接会自动重写成最新的——那一段是脚本生成的，不用手动维护。

### `wtool bootstrap`

```bash
wtool bootstrap
wtool bootstrap --dry-run          # 先看计划，不真的动
wtool bootstrap --force            # 目录有未提交改动也照装
```

按 `priority` 顺序把所有项目过一遍，**只做 `install` 那一层**（系统层是另一条命令：
`wtool sudo-bootstrap`）。

**它不替你决定"自己编还是下现成的"。** 需要先产出东西的项目（有 `build.sh` 而
`output/` 还是空的）会被跳过，并在最后把该跑的命令列出来：
`wtool build <项目>`，或者 `wtool download-release <项目>` + `wtool unpack-release <项目>`。

**第一次装一台新机器，用这条命令就够了。**

【图片占位】![wtool bootstrap 的输出](.pic/bootstrap.png)

<!-- TODO: 在干净环境里执行，把输出截图保存为 .pic/bootstrap.png
     wtool bootstrap
     建议截到"按项目逐个处理"的那几行，能看出顺序和分节。
-->

### 其它

```bash
wtool status               # 登记表 + 检查那些软链接是否都还在
wtool validate ./terminal/tmux
wtool doctor --quiet       # 只输出环境变量；eval "$(wtool doctor --quiet)" 立刻在当前 shell 生效
```

---

## 3. 子项目

| 项目 | 仓库 | 简介 |
|---|---|---|
| `wtool-base` | [allinkernel/wtool](https://github.com/allinkernel/wtool) | 文档。你正在看的这份 |
| `bootstrap` | [allinkernel/wtool-bootstrap](https://github.com/allinkernel/wtool-bootstrap) | 引擎本体 |
| `os/ubuntu` | [allinkernel/wtool-os-ubuntu](https://github.com/allinkernel/wtool-os-ubuntu) | Ubuntu 系统包与 apt 镜像 |
| `shell/zsh` | [allinkernel/wtool-zsh](https://github.com/allinkernel/wtool-zsh) | zsh 配置 |
| `shell/oh-my-zsh` | [allinkernel/wtool-ohmyzsh](https://github.com/allinkernel/wtool-ohmyzsh) | oh-my-zsh 本体 |
| `terminal/tmux` | [allinkernel/wtool-tmux-config](https://github.com/allinkernel/wtool-tmux-config) | tmux 配置与状态脚本 |
| `terminal/fzf` | [allinkernel/wtool-fzf-binary](https://github.com/allinkernel/wtool-fzf-binary) | fzf 预编译二进制 |
| `tools/repo` | [allinkernel/wtool-repo](https://github.com/allinkernel/wtool-repo) | repo 工具 |
| `tools/android_repack` | [allinkernel/wtool-android_repack](https://github.com/allinkernel/wtool-android_repack) | Android 镜像解包 / 改包 / 重签 |
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
cd <工作区目录>
wtool status                       # 看哪些登记的链接不见了
wtool install <项目目录> --force    # 重新装一遍
```

`install` 是幂等的，重装不会出问题。

**想彻底退回去**

```bash
cd <工作区目录>
wtool uninstall <项目目录>          # 一个项目
./uninstall.sh                     # 整个工作区（在工作区根目录跑）
```

**shell 里 `wtool` 命令找不到**

引擎挂在 `~/.wtool/bootstrap`，靠 shell 托管块加进 `PATH`。重开一个终端，或者：

```bash
exec zsh
```

**想看看 `wtool` 到底把东西放哪了**

```bash
wtool doctor                       # 环境、路径、状态目录、编译安装前缀
wtool status                       # 登记的东西是不是都还在（含每条软链的目标）
```
