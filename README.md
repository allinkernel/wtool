# wtool

把一堆零散的个人配置和工具 —— shell、终端、编辑器、主题 —— 用一条命令装到一台新机器上。

这不是一个软件，是一套**管理方式**：所有配置以独立的小项目形式存在，各自放在自己的 Git
仓库里，由一个叫 `wtool` 的小引擎统一安装、构建、发布。

> - **下载 / 安装入口 →** [`download.md`](download.md)。不装 `git`、只有浏览器也能用。
> - 这份文档讲**怎么用**；每条规则**为什么**这么定（软链、记账、三层产物、发布契约……）
>   在 [`原理.md`](原理.md)；每条命令的参数和细节在 [`guide.md`](guide.md)。

---

## 1. wtool 是什么

在新机器上重建开发环境，麻烦的从来不是"装"这个动作，而是四个副作用：
**装过什么记不住、装在哪儿说不清、装错了撤不掉、换台机器得重来一遍。**

`wtool` 就是冲这四条来的：

| 麻烦 | wtool 的答案 |
|---|---|
| 装过什么记不住 | 装之前先算出一份**计划**，装的过程**记账**；`wtool check` 拿"声明 / 账本 / 磁盘"三者对账 |
| 装在哪儿说不清 | 所有东西落在**影子家目录** `~/.wtool/` 里，路径和你的 `$HOME` 一模一样（见第 4 节）|
| 装错了撤不掉 | 不需要 root 的那一半**完全可逆**：一条 `wtool uninstall` 原样撤回 |
| 换台机器重来一遍 | 产物能**打包发布**，新机器上下载 + 装两条命令；或者照样自己编 |

### 四个概念

先记住这四个词，后面全都围着它们转：

| 词 | 是什么 |
|---|---|
| **引擎** | `wtool` 这条命令本身。它住在 `bootstrap` 这个项目里（**不在你现在看的这个文档仓库里**），管所有"装 / 编 / 发"的动作 |
| **项目** | 工作区里的一个目录，里面有一份 `wtool.xml`。**有它 = 这是个 wtool 项目**；没有 = 就是一堆文件，不参与 wtool。每个项目是一个独立的 Git 仓库 |
| **工作区** | 所有这些项目拼在一起的那个目录（比如 `~/self/wtool`）。**工作区根目录本身不是 Git 仓库**，它只是它们拼在一起的地方 |
| **影子家目录** | `~/.wtool/`。它按你的 `$HOME` 一一对应地放东西，你的 `$HOME` 里只留**软链**指过去 —— 所以卸载干净、来路清楚（第 4 节）|

### 三个阶段

```
  ① 产出 ── 需要网络；自己编还需要编译器
  ┌───────────────────────────┬──────────────────────────────────┐
  │ wtool build             自己编（编什么由项目说了算）         │
  │ wtool download-release  从发布页把包下到项目的 __release/    │
  │ wtool unpack-release    校验 + 解开，写进 __output/          │
  │ （后两条连起来 = 下别人编好的，结果和 build 一样）           │
  └───────────────────────────┬──────────────────────────────────┘
                             │ 写
                             ▼
  ┌──────────────────────────────────────────────────────────────┐
  │ __output/ —— 产物的中转站                                    │
  │ （不进 Git，可以整个目录拷到别的机器）                       │
  └───────────────────────────┬──────────────────────────────────┘
                             │ 读（install 是唯一的读者）
                             ▼
  ② 铺设 / ③ 打包发布
  ┌──────────────────────────────────────────────────────────────┐
  │ wtool install          铺进 ~/.wtool ← 断网也能跑            │
  │ wtool pack-release     __output/ → __release/                │
  │ wtool publish-release  __release/ → 发布页 ← 需要网络        │
  └──────────────────────────────────────────────────────────────┘
```

一句话记住：**「编」和「下」产出同一个东西，装只认那个东西。**

所以：

- 换台机器，只要有 `__output/`，**不用重编**；
- `install` 跑得再多次也不会产生新东西，**可以随便重跑**；
- 卸载 = 把 `install` 铺出去的东西收回来。

---

## 2. 安装

拿到工作区有两条路，**选一条就行** —— 两条路拿到的东西一样，后面的安装步骤完全一样。
不想用 `git`（只有浏览器、公司机器没网）走下载那条：

- **下载包** → [`download.md`](download.md)（下载入口、资产名、三条命令都在那一页）
- **用 `git`** → 下面这段（推荐给要长期跟着改的人）

### 2.1 用 `git` 拿全套

**先装 `wtool` 自己，再让它去装项目。** 一共五步：

```bash
# 0. 先有 git、python3，再拿到 repo 工具本身
#    （很多发行版直接有包：sudo apt install repo；没有就用下面这个 —— repo 就是一个 Python 脚本）
sudo apt install -y git python3 curl
mkdir -p ~/.local/bin
curl -fsSL -o ~/.local/bin/repo \
  https://raw.githubusercontent.com/allinkernel/wtool-git-repo/wsw/repo
chmod +x ~/.local/bin/repo
export PATH="$HOME/.local/bin:$PATH"      # 想长期生效就写进 shell 配置

# 1. 把仓库拿到本地（第一次）
repo init -u ssh://git@github.com/allinkernel/w_manifests.git -b wtool
repo sync

# 2. 装 wtool 自己 —— 会准备好运行环境（python3/git/…），然后停下
cd <工作区目录>
./install.sh

# 3. 让当前 shell 认识 wtool（PATH 是 shell 启动时定下的，所以要重读一次）
exec $SHELL
#    或者干脆重开一个终端

# 4. 装系统层的东西：apt 软件包、系统配置文件（换 apt 源之类）。这一步要 root
#    没有 sudo 的机器直接跳过它，前面几步照样成立（见下面「没有 sudo 的机器」）
wtool sudo-bootstrap

# 5. 装其余的项目：文件、软链、shell 集成。不需要 sudo，也不联网
wtool bootstrap
```

> **第 0 步为什么不能省**：`repo` 要用 `python3` 和 `git` 跑，而这两样正是第 2 步
> `./install.sh` 负责准备的东西 —— 先有鸡才有蛋，所以这一步得你自己来（就三条命令）。
> `repo` 官方也提供打包版本（Debian/Ubuntu 上是 `repo` 这个包），有就用系统的。

**第 4 步和第 5 步为什么分开？** 因为**要 sudo 的事和不要 sudo 的事不能混在一格里**。
第 4 步动的是整个系统（apt 包、`/etc` 下的文件），第 5 步动的只是你自己的家目录。
混在一条命令里，你看到一屏输出，分不清该修哪一头。

这条分工贯穿整套命令：**带 `sudo-` 前缀的才可能要 sudo，其余的命令永不要 sudo、
永不联网。** 所以 `wtool uninstall` 不会去动 `/etc` —— 那是 `wtool sudo-uninstall` 的事。

**第 2 步为什么到那里就停？** 因为它只负责「让 `wtool` 这条命令能用」，不装任何项目。
这样失败原因清清楚楚：`install.sh` 挂了 = 系统环境问题（缺依赖、源连不上）；
后面几条挂了 = 某个项目自己的问题。它跑完会把后面该做什么直接打在屏幕上。

### 2.2 没有 sudo 的机器（公司机器很常见）照样能装

跑第 2 步（`./install.sh`）时，它一上来先判断这台机器是哪种：本来就是 root /
`sudo` 免密 / 有 `sudo` 但要密码 / 根本没有 `sudo`。要密码时，**能确认你有 sudo**
它就会问一次（先把将要执行的命令打给你看）：输密码就继续，直接回车就跳过要 root 的那部分。

**装 wtool 自己（引擎 + `~/.wtool` + 软链）一个 root 都不需要** —— 没有 sudo 也能装完，
之后 `wtool install <项目>` / `wtool bootstrap` 装 tmux、zsh 这些照样能用。只有系统层
（`wtool sudo-bootstrap` / `wtool sudo-install`）要 root —— 那时候再找管理员，不耽误前面。

> wtool **不会为了判断去弹密码框**：它靠"你在不在 `sudo`/`wheel` 组"来判断
> （标准配置就是靠组给权限），所以"有 sudo、只是要密码"的机器它**认得出来**。
> 跳过也不影响 wtool 本体：自己敲一遍它打出来的 `sudo apt-get install ...` 就行。
>
> 如果连 `python3` / `git` 都没有、又装不上（没有 sudo），它会明确告诉你
> "让管理员装这两个包"，然后**停在准备运行环境这一步**（不会装作装好了）——
> 因为规划器要 `python3`、读仓库要 `git`，这两样确实绕不过去。

**装包时屏幕会动，不是卡死。** 它准备运行环境、用 apt 装东西时，每 5 秒打一行心跳：

```
wtool-install:     还在装…（30 秒）  · Get:3 http://… 45.2 MB/120 MB
```

以前下载几分钟屏幕上什么都没有，看起来像卡死。看到这行就说明它还活着；
apt 最后一行在做什么，它顺手贴出来了。

### 2.3 装完是什么样

装完 wtool 自己之后，重开一个 shell，`wtool` 就能在任何目录下直接用了。
它顺手把 **Tab 补全**也挂好了（bash / zsh 各一份、行为一致）：

```bash
wtool <TAB>            # 列子命令（install / bootstrap / pack-release …）
wtool install <TAB>    # 列项目路径，外加 all
wtool install --<TAB>  # 列这个命令认的开关（--dry-run / --force / --prune …）
```

给不出候选时（比如参数本来就是路径）会退回补文件名，所以没破坏原来的习惯。
内部命令（`_layer-save` 这种下划线开头的）不进候选，这台机器没有 sudo 时
`sudo-*` 那几个命令也不进候选。

### 2.4 不想在真机上试？用容器跑一遍

`--network=host` 不能省：容器里的 `127.0.0.1` 只有在这个网络模式下才是宿主自己，
脚本靠它自动接上宿主代理。

```bash
# 从头走一遍，每一步自己决定（等价于"刚 repo sync 完"）
docker run --rm -it --network=host -v "$PWD":/wtool:ro \
  ubuntu:24.04 bash /wtool/bootstrap/scripts/container-raw.sh

# 以一个普通用户进去（推荐：真机上你就是普通用户，sudo 才用得着）
docker run --rm -it --network=host -v "$PWD":/wtool:ro \
  ubuntu:24.04 bash /wtool/bootstrap/scripts/container-raw.sh --user mindul

# 或者一步到位，直接给一个装好的环境
docker run --rm -it --network=host -v "$PWD":/wtool:ro \
  ubuntu:24.04 bash /wtool/bootstrap/scripts/container-shell.sh
```

（`$PWD` 换成工作区目录。）两个脚本进入时都会**自动探测宿主机代理**并接上 ——
`docker run` 不会把你 shell 里的代理变量带进容器，不接的话容器里是"裸网"，
所有下载都失败，而人很容易把它误判成"网络坏了"。不想要自动探测就加
`-e WTOOL_NO_PROXY=1`。

`container-raw.sh` **什么都不装**，等价于"刚 `repo sync` 完"（连 `python3` 和 `git`
都没有，这是故意的 —— 装了它们 `wtool` 就能跑，可真机器刚同步完时本来就没有）。
`container-shell.sh` 替你装依赖、装引擎，再把你丢进 zsh，剩下两步自己敲。
两个脚本的差别见 [`guide.md`](guide.md)。

---

## 3. 常用命令

**每条命令都要能回答三个问题：要 sudo 吗、碰网络吗、能撤吗。** 命令后面写 `<路径>` 的，
指的是**项目目录**（比如 `terminal/tmux`）；写 `<项目>` 的，路径和末段都认
（`terminal/tmux` 和 `tmux` 都行）。

### 3.1 看总览

```bash
wtool                    # 不带参数 = 项目表（一行一个项目、一列一个能力），见第 5 节
wtool doctor             # 表格 + 环境诊断（版本、系统、状态目录、缺什么）
wtool status             # 登记表 + 软链检查：$HOME 里登记的软链还都在吗
wtool status <项目>       # 看板上某一格看不懂？逐列给你状态 + 对应命令 + 依据
```

### 3.2 装与卸（不要 root、不联网）

| 命令 | 做什么 | 可撤吗 |
|---|---|---|
| `wtool install <路径>` | 把 `__output/` 铺进 `~/.wtool/usr`，再在 `$HOME` 里建软链、加 shell 集成 | **完全可逆**，一条命令原样撤回 |
| `wtool uninstall <路径>` | 撤销 `install` | —— |
| `wtool bootstrap` | 所有项目 `install` 一遍 | 逐个 `uninstall` 即可 |
| `wtool move <旧路径> <新路径>` | 项目改名：卸旧的 → `mv` 目录 → 按新路径装回来 | 反向 `move` 回去 |

```bash
cd <工作区目录>                     # install / uninstall 认的是项目目录，在工作区根目录最省事
wtool install terminal/tmux         # 装一个项目
wtool uninstall terminal/tmux       # 撤销，系统回到装之前
wtool install terminal/tmux --dry-run   # 先看计划：要建哪些链接、要写哪几段 shell 块
```

**装一个项目实际发生两件事，顺序是有意的**（两件都是引擎替你做的，
**你不用自己去敲那个脚本**）：

```
① 先跑项目自己的 scripts/install.sh   —— 把 __output/ 里的东西铺进 ~/.wtool
② 再按 wtool.xml 建软链              —— 把 ~/.wtool 里的东西接到你的 $HOME
```

先①后②不能反：②建的软链**指向**①铺出来的东西，反了就是先建一堆悬空链接。

一次把不需要你先决策的项目都装上（`wtool install all` 和 `wtool bootstrap` 是同一条路）：

```bash
wtool sudo-bootstrap     # 系统层：apt 包、/etc 下的文件。要 root；没有 sudo 就跳过这条
wtool bootstrap          # 用户层：文件、软链、shell 集成。不需要 sudo、不联网
```

需要「编还是下」的项目它会跳过，并把该跑的命令列给你 —— 见 3.3。

**改项目目录要用 `wtool move`，别自己 `mv`。** 项目的身份就是它在工作区里的路径
（没有单独的"项目 id"），所以**把目录改个名 = 换了一个项目**：链接、环境变量块、
`wtool` 记的账都挂在旧路径上。自己 `mv` 的后果是链接变断的、环境变量静默失效、
下次 `install` 还会说落点被别人占着。**已经 `mv` 过**就跑一句 `wtool check`：
它会把这类"旧账"一条条列出来，照着提示 `wtool uninstall <旧路径> --no-script` 撤掉即可。

### 3.3 产出：自己编，或者下现成的

有些项目要产出东西才能用 —— 要么自己编，要么直接下别人编好的（比如那套 Neovim 环境）：

```bash
wtool build                      # 列出哪些项目可以构建
wtool build editor/astronvim_v5  # 自己编（小时级）

wtool download-release                     # 列出哪些项目有现成的包可下
wtool download-release editor/astronvim_v5 # 从发布页下到 __release/（分钟级，只下载）
wtool unpack-release   editor/astronvim_v5 # 校验 + 解开，写进 __output/
```

**两条路二选一，结果完全等价。** 两条路都产出到项目的 `__output/` 目录、放在同一个位置，
所以之后的 `wtool install` 根本不关心它是从哪来的。能下就下。

「下载」和「解开」是两条命令、各干一件事：`download-release` 只把包下到 `__release/`
（照项目里**提交在仓库里**的 `scripts/release.json` 下，逐个校验），`unpack-release`
才校验分卷、按顺序拼起来、解到 `__output/`。中断了重来也不会坏 —— 已经下好的文件
（校验值对得上）会跳过，不会重下几百兆。纯配置类的项目没有这一步。

> 只有浏览器、没有 `git` 的那条路（手动下包再解开）在 [`download.md`](download.md)。

### 3.4 打包与发布

**打包**（不联网，产出落在项目自己的 `__release/` 目录里）：

```bash
wtool pack-release editor/astronvim_v5
```

出来的是**源码包**（`source.zip`，整个项目）加一个校验文件；**有构建产物的项目**
再加一个**产物包**（`release.zip`，`__output/` 里的东西）。大项目的包会切成
`-vol01`、`-vol02`… 分卷，外加一份 `dist.json` 说明每一卷叫什么、按什么顺序拼。
同时写一份给人看的下载页 `docs/download.md`（提交进仓库，项目 `README.md` 指向它）。

> **包名一律是 ASCII**（`source.zip` / `release.zip`）：GitHub 不接受非 ASCII 的资产名，
> 中文名传上去会被它悄悄改写成 `default.zip`，那条下载直链就 404。所以**本地名和线上名
> 是同一个**，下下来不用改名。

**上传**（把 `__release/` 里的东西传到项目自己的 GitHub Release 页）：

```bash
wtool publish-release                 # 所有可发布的项目
wtool publish-release terminal/tmux   # 只发一个
wtool publish-release --dry-run       # 先看计划（连"线上会叫什么名字"都列出来）
```

它**只上传、不打包**（要发新版本就先 `pack-release`），传完之后写一份
`scripts/release.json`：这一版发了什么、每个文件的校验值是多少 ——
**记得把它提交进仓库**，那是别人 `download-release` 时的依据。

发布完成之后，[`download.md`](download.md) 里那张资产表会**自动更新**成最新一版 ——
不需要手动维护。要手动刷一次用 `wtool docs refresh`（什么时候需要刷、跑之前要知道
什么，都写在 [`download.md`](download.md) 里）。

### 3.5 层（只有容器构建的项目才有，比如 Neovim 那套）

| 命令 | 做什么 | 碰网络吗 |
|---|---|---|
| `wtool unpack-layer <路径>` | 把 `__layer/` 里的层镜像解成**安装产物**（写进 `__output/`，不需要 docker） | ❌ |
| `wtool push-layer <路径>` | 把 `__layer/` 里的层镜像推到镜像仓库（本机要 docker） | ✅ |
| `wtool pull-layer <路径>` | 从镜像仓库把层镜像拉到 `__layer/`（**目标机不需要 docker**） | ✅ |

**层是项目的资产**：`wtool build` 编出来的层镜像住在项目的 `__layer/` 里，
`unpack-layer` 把它变成能装的产物，`push-layer` / `pull-layer` 让层走镜像仓库到另一台机器。
另有两条 **`wtool _layer-save` / `wtool _layer-load`**（下划线开头 = 内部命令）：
引擎构建时自己调、排查时才有用，**不在速查表里，也不在看板上**。

### 3.6 检查与修复

```bash
wtool check              # 全部项目：声明（wtool.xml）/ 日志（装过什么）/ 磁盘（现在有什么）三者对比
wtool check terminal/tmux
wtool repair all         # 把安装计划重跑一遍（补链接、补软链、重写 shell 块）
```

`check` 回答的是"我以为装了的东西，真的还在吗"——三者对不上就报出来，**只看不动**。
`repair` 是**把安装计划重新算一遍再执行**（本来就是幂等的），**只重建、不删除**，
也不跑项目脚本 —— 它**不去读 `check` 的报告**，两份各干各的。

**老工作区的目录改名也由 `check` 提示**：`__output/` / `__release/` / `__layer/`
是后来的名字，老的 `output/` / `release/` / `layer/` 不会被自动搬（看板只会显示
「待产出」）。`wtool check` 认出旧目录时会把该敲的 `mv` 直接打出来 ——
**它只提示，绝不自动搬**（目录名是你的决定，而且可能有命令正在往里写）。

### 3.7 卸载：三条命令，别用 `rm -rf`

**`rm -rf ~/.wtool` 不是完整卸载。** 它只删掉了影子家目录里的实体，
你的 `$HOME` 里那些软链**还在**（全变成断链），`~/.zshrc` 里的 loader 块也还在。

正确的做法是三条命令，**管的东西不一样、权限也不一样**：

| 命令 | 管什么 | 要 sudo 吗 |
|---|---|---|
| `wtool uninstall all` | 撤销所有 `install`：`$HOME` 里的软链 + `~/.wtool` 里的实体 | ❌ |
| `wtool sudo-uninstall all` | 撤销所有 `sudo-install`：卸载 apt 包、还原 `/etc` 下的文件 | ⚠️ 可能要 |
| `wtool kill-self-forever` | 删掉 wtool 的一切痕迹，**含 `~/.local/state/wtool/` 里的状态记录** | ❌ |

`wtool uninstall` **不越权**：它不会去还原 `/etc`，因为那是 `sudo-uninstall` 的事。
反过来也一样。想只卸一个项目就把 `all` 换成项目目录。

**`kill-self-forever` 是第三条命令，因为它删的东西前两条都不碰**：状态记录
（谁装过、谁发布过）在 `~/.local/state/wtool/`，不在 `~/.wtool/` 里 ——
没有它，那本账永远留着。它会先列清**删什么、不删什么**，再要求你**逐字输入一句
全大写确认**，敲错一个字就什么都不做。

### 3.8 其他

```bash
wtool validate <项目目录>            # 检查某个项目的 wtool.xml 写得对不对
wtool init <目录> [--priority N] [--all]   # 新建一个 wtool 项目（第 6 节）
wtool docs refresh                  # 重刷 download.md 那张资产表
wtool version
```

**`--dry-run`**：`build` / `download-release` / `install` / `uninstall` / `sudo-install` /
`sudo-uninstall` / `pack-release` / `publish-release` / `unpack-layer` / `push-layer` /
`pull-layer` / `bootstrap` / `sudo-bootstrap` / `repair` / `kill-self-forever` 都支持 ——
先打印计划、不真的动系统。`--dry-run` 时**项目自己的 `scripts/install.sh` /
`scripts/build.sh` 根本不会被执行**：引擎只打印"真跑的话会跑哪条脚本、带什么参数、
在哪个目录、给什么环境变量"，所以哪怕脚本自己没写 dry-run 支持，也不会有任何副作用。
`status` / `doctor` / `validate` 这些只看不动的没有这个开关。

> ⚠️ **例外：`unpack-release` 不在上面那份名单里。** 它的 `--dry-run` 只拦住 `mkdir`，
> **分卷拼接与解包照做**，会真的写 `__output/`（2026-10-05 实测复现，代码待修）。
> 修好之前，**别把 `unpack-release --dry-run` 当"只读预演"**。

**写锁**：会改状态目录的命令（`install` / `uninstall` / `bootstrap` / `sudo-*` /
`repair` / `kill-self-forever`）共用一把写锁 `$WTOOL_STATE/.lock`。同一台机器上同时跑两个，
**后一个会等前一个**（默认最多等 300 秒，等不到就失败）；等待上限用
`WTOOL_LOCK_TIMEOUT=<秒>` 调，设 `0` = 一秒不等；`--dry-run` 不拿锁（它什么都不写）。

**"永不要 sudo、永不联网"不是口号，它是可逆性的实现方式。** 只要 `install`
不产生任何新的外部依赖，"撤销"就是把铺出去的东西删掉这么简单。
一旦它偷偷开始下载或编译，撤销就成了一句空话 —— 所以需要网络和编译器的活
全在 `build` / `download-release` 里，需要 root 的活全在 `sudo-*` 里。

> apt 装的系统包**没有记账**，所以严格来说撤不回来。`sudo-uninstall` 能做的：
> 把装的包卸掉、把改过的 `/etc` 文件从备份还原回去。这就是为什么它必须单独一条命令 ——
> 让"撤不干净"这件事有个明确的入口，而不是混在 `install` 里假装它可逆。

---

## 4. 东西装在哪：影子家目录

这是整套设计里最值得记住的一件事 —— **每一层只放一种东西**，
而且**每一层只由一条命令负责搬运**。

![三层路径：__output/ → ~/.wtool/ → $HOME](.pic/layers.png)

> 图源是 `.pic/layers.mmd`（Mermaid 文本），改了跑 `sh .pic/render.sh` 重新生成 PNG。
> 纯文本环境看下面这张对照表是一样的。

**`~/.wtool/` 是"影子家目录"**：它按 XDG 规范一一对应你的家目录，只是东西都住在里面。

```
你的 $HOME                      ~/.wtool/
~/.config/astronvim_v5     ←→   ~/.wtool/.config/astronvim_v5
~/usr                      ←→   ~/.wtool/usr
~/.tmux.conf               ←→   ~/.wtool/.tmux.conf
```

路径长得一模一样，所以"这个文件从哪来的、删了会少什么"一眼就能看出来。
**编译产物、下载产物统一放在 `~/.wtool/usr/` 这一格**，`~/usr` 就是它接回 `$HOME`
的那条软链 —— `~/usr/bin/nvim` 和 `~/.wtool/usr/bin/nvim` 是同一个东西。

**反过来也成立**：`~/.wtool/` 下面**不会出现你 `$HOME` 里没有的路径**。
引擎自己用的东西都关在 `~/.wtool/` 里，**分两处**：引擎本体（自举下来的那份）
在 `~/.wtool/bootstrap`，中转软链和临时文件在 `~/.wtool/wtool-work-dir/` ——
后者是唯一一个故意不像家目录的目录。**状态记录**（谁装过、谁发布过）在
`~/.local/state/wtool/`，这个位置是 XDG 标准给"状态"用的，你不会顺手把它当缓存删掉。

**你的家目录里不该多出一个实体文件。** 所以卸载是干净的：
`wtool uninstall <项目>` 把实体和软链一起撤掉，家目录回到装之前。

配置文件和 shell 集成也走这条路：每个项目贡献的环境变量收在 `~/.wtool/.zshrc` 里，
你的 `~/.zshrc` 里只会多出**一小段 loader** 指过去，而不是每个项目各插一段。
（用 bash 的人对应 `~/.wtool/.bashrc`，两个 shell 各有一份，行为一致。）

---

## 5. 产物目录：`__output/` / `__release/` / `__layer/`

这三个目录都是**跑出来的**，不是仓库自带的源码目录 —— 所以名字前面是两个下划线
（`__`），`ls` 一眼就能和源码分开。**它们永远不进 Git，删掉也能重新产出。**

```
<项目>/
├── wtool.xml            项目声明
├── scripts/             这个项目专属的动作脚本，只有两种
│   ├── build.sh         自己编：产物写进 __output/
│   ├── install.sh       通用机制铺不了的安装步骤
│   └── release.json     "这一版发布了什么"的下载声明（发布后生成，要进 Git）
├── docs/
│   └── download.md      给人看的下载页（打包时生成，要进 Git）
├── __output/            ← build / unpack-release / unpack-layer 的产物，不进 Git
│   └── ubuntu_22/       按"系统_版本"分目录
│       ├── main/        底座：主程序 + 基础配置
│       └── lang/        语言增量包，依赖 main
├── __release/           ← 包的中转站，不进 Git
│   ├── source.zip       整个项目（不含这三个目录；大项目切成 source.zip-vol01…）
│   ├── source-hash.txt
│   ├── release.zip      产物包：__output/ 里的东西（同样按 -vol01… 切分卷）
│   ├── release-hash.txt
│   ├── dist.json        这一份怎么拼：每一卷叫什么、多大、校验值是多少
│   └── .source          内部标记：这份包是"刚打的"还是"刚下的"
└── __layer/             ← 层镜像（只有容器构建的项目），不进 Git
    └── ubuntu_22/       一个目标系统一个目录，里面是标准的镜像布局
```

> **为什么带 `__` 前缀**：`output/`、`release/`、`layer/` 这样的名字，`ls` 时分不清
> 是"跑出来的"还是仓库里的源码目录（别的项目里 `release/` 常是源码的一部分）。
> 加上 `__` 就只有一种读法：**机器特定、可以随时删掉重建**。

**`__output/` 的四条规则**：

| 规则 | 为什么 |
|---|---|
| **`__output/` 不进 Git** | 它是机器特定的二进制产物，跟着仓库走只会把仓库撑爆 |
| **自己编、和下载解开，写到完全相同的路径** | 这是两条路等价的**唯一**实现方式 |
| **`install` 只读它，不写它** | 产物层和安装层分开，重装不用重建 |
| **整个目录可以搬走** | 拷到另一台机器 + `wtool install`，环境就复现了 |

**为什么按"系统_版本"分目录？** 编译出来的程序依赖系统的基础库（glibc）。
在 Ubuntu 22.04 上编的在 20.04 上跑不起来，反过来可以 —— 基础库只保证往前兼容。
所以每个目标系统单独出一份。**在最老的那个系统里编，一张包能通吃所有更新的系统。**

**`pack-release` 打几个包？** 看项目有没有"构建产物"：

- **没有构建能力的项目**（没有 `scripts/build.sh`、也没有 `build/layers.tsv`）——
  **只发一个源码包**。那种项目没有"产物"：产物包里只剩几个声明文件，
  而源码包里本来就有，两个包发的是同一批东西。
- **有构建产物的项目** —— 源码包 **+** 产物包：**源码包**给"要自己编"的机器或者存档；
  **产物包**给"只要用"的机器，它**自带编译好的程序**，解开就能用，
  不需要源码、不需要编译器。

装到别的机器上时，**有产物包就下产物包**（只有源码包的项目就下源码包）。
项目大到一个包传不完的时候，包会切成若干分卷，旁边配一份 `dist.json` 说明每一卷叫什么、
多大、校验值是多少 —— `wtool unpack-release` 照着它校验和拼接，不需要人记顺序。

**这几个动作拼起来是一条闭环**，而且可以当成一条断言来验：

```
pack-release → unpack-release   ≡   repo sync 之后 build 一遍
                                ≡   repo sync 之后 download-release + unpack-release
```

**每条命令跟这两个目录的关系**（图源 `.pic/commands.mmd`）：

![命令与 __output/、__release/ 的关系](.pic/commands.png)

一句话读法：**只有 `build` 和 `unpack-release` 往 `__output/` 里写；
`pack-release` 往 `__release/` 里写，`download-release` 把包下进 `__release/`；
`install` 只读 `__output/`，`publish-release` 只读 `__release/`。**

**发布方**（有源码、编得出来的那台机器）：

```bash
wtool build editor/astronvim_v5             # 源码 → __output/
wtool pack-release editor/astronvim_v5      # __output/ → __release/（打成包）
wtool publish-release editor/astronvim_v5   # __release/ → GitHub Release（**只上传**）
```

**使用方**（只想用、不想编的那台机器）：

```bash
wtool download-release editor/astronvim_v5  # 读提交在项目里的下载声明 → 包下到 __release/
wtool unpack-release   editor/astronvim_v5  # 校验 + 解开 → __output/
wtool install editor/astronvim_v5           # 装
```

**为什么下载声明要提交进仓库？** 一是刚 `repo sync` 下来就知道"这个项目有没有现成的包"，
不用先联网去问发布页；二是**校验值的可信来源**：校验值只能证明"我下到的文件没坏、
和清单里写的一致"，**不能证明"这是作者发的"** —— 发布页和清单一起被换掉是防不住的。
清单放在仓库里（要改就得改提交历史，看得见）才挡住了这一层。
再往上（有人连你的 GitHub 账号一起换掉）今天**没有**防 —— 那要靠签名，现在没做。

`publish-release` 跑完会把该提交的东西打出来提醒你，但**不替你 commit**。

---

## 6. 项目

### 6.1 现在有哪些项目

**判据只有一个：目录里有 `wtool.xml`**（第 1 节）。有它 = 这是个 wtool 项目。
顺序和裸跑 `wtool` 得到的那张表一致（按 `prio` 排，越小越先加载）。

要准确的清单，**以运行结果为准**：

```bash
wtool                                                   # 裸跑：一行一个项目、一列一个能力
python3 bootstrap/lib/wtool_plan.py publish-list --root .
```

| 项目 | `prio` | 仓库 | 一句话简介 |
|---|---|---|---|
| `bootstrap` | 5 | [wtool-bootstrap](https://github.com/allinkernel/wtool-bootstrap) | 引擎本体：`wtool` 命令、安装/卸载机制、清单解析、发布逻辑。其他项目都靠它 |
| `os/ubuntu` | 5 | [wtool-os-ubuntu](https://github.com/allinkernel/wtool-os-ubuntu) | Ubuntu 上要装的系统软件包清单，以及把 apt 源换成国内镜像 |
| `shell/oh-my-zsh` | 10 | [wtool-ohmyzsh](https://github.com/allinkernel/wtool-ohmyzsh) | oh-my-zsh 本体，带自己的定制和插件选择 |
| `shell/zsh` | 20 | [wtool-zsh](https://github.com/allinkernel/wtool-zsh) | zsh 自身的配置和补全别名 |
| `tools/git-repo-sh-tools` | 40 | [wtool-repo](https://github.com/allinkernel/wtool-repo) | `repo` 工具（管理多仓库的那个）和它的快捷命令 |
| `tools/android_repack` | 45 | [wtool-android_repack](https://github.com/allinkernel/wtool-android_repack) | Android 镜像"解包 → 改 → 重新打包"的流水线（**私有仓**） |
| `tools/dsh-remote` | 47 | [wtool-dsh-remote](https://github.com/allinkernel/wtool-dsh-remote) | 不在电脑前时用手机接管会话 |
| `harness/dsh-conf` | 48 | [wtool-dsh-conf](https://github.com/allinkernel/wtool-dsh-conf) | 助手自己的配置：提示词、技能、profile |
| `terminal/tmux` | 50 | [wtool-tmux-config](https://github.com/allinkernel/wtool-tmux-config) | tmux 配置，外加一组显示 CPU/内存/磁盘/网络的小脚本 |
| `terminal/fzf` | 60 | [wtool-fzf-binary](https://github.com/allinkernel/wtool-fzf-binary) | fzf 的预编译二进制，省得每台机器重编 |
| `editor/astronvim_v5` | 70 | [wtool-astronvim_v5](https://github.com/allinkernel/wtool-astronvim_v5) | 一整套 Neovim 环境：编译 nvim、装插件、装语言服务器、打成发布包 |

> 某一行不在你机器上的表里，通常是因为那个项目的 `wtool.xml` 不在
> （被临时改名停用、或者清单里没有它）—— **以命令输出为准**。

**下面这些也在工作区里、也是独立的仓库，但不是 wtool 项目** —— 目录里没有 `wtool.xml`，
所以 `wtool install` / `wtool bootstrap` 不会碰它们：

| 仓库 | 为什么不是 |
|---|---|
| [`wtool`](https://github.com/allinkernel/wtool) —— 你现在看的这份文档 | 纯文档，没有任何"装上去"的东西 |
| [`wtool-astronvim_v5_config`](https://github.com/allinkernel/wtool-astronvim_v5_config) | 它是 `editor/astronvim_v5` 那套环境的一部分，跟着那套一起发 |
| [`neovim`](https://github.com/neovim/neovim) | 上游仓库，我们既没权限推、也不能往里塞文件 |
| [`typora-LightMindTheme`](https://github.com/allinkernel/typora-LightMindTheme) | Typora 主题，只有素材和样式文件 |

### 6.2 能力总览：那张表

裸跑 `wtool` 打出来的就是它：**一行一个项目、一列一个能力**。
`build` / `install` 那几列的能力，由项目里有没有对应的脚本决定
（**文件存在即能力声明**）；其余几列是**引擎**的命令，摆出来是为了让你一眼看到
"这个项目还能做什么"。

表头是中文，**一列只对应一条命令**：

| 列名 | 对应命令 |
|---|---|
| `构建` | `wtool build` |
| `安装` | `wtool install` |
| `卸载` | `wtool uninstall` |
| `sudo安装` | `wtool sudo-install` |
| `sudo卸载` | `wtool sudo-uninstall` |
| `做gz包` | `wtool pack-release` |
| `发布包` | `wtool publish-release` |
| `下gz包` | `wtool download-release` |
| `解容器层` | `wtool unpack-layer`（`__layer/` → 安装产物 `__output/`，不联网、不要 docker） |
| `推容器层` | `wtool push-layer`（`__layer/` → 镜像仓库） |
| `拉容器层` | `wtool pull-layer`（镜像仓库 → `__layer/`） |

（`解gz包` = `wtool unpack-release` **没有独立列** —— 它是"装东西"那条路上的一步
（`__release/` → `__output/`），只在表下边的图例里出现。）

每一格是**六种状态之一**，终端里各有颜色：

| 状态 | 颜色 | 意思 |
|---|---|---|
| **不支持** | 红 | 这个项目没这项能力（比如纯配置项目不能 build） |
| **可执行** | 黄 | 现在就能跑 |
| **待产出** | 蓝 | 能力有，但 `__output/` 里还是空的 —— 先 `wtool build`，或者 `download-release` + `unpack-release` |
| **已完成** | 绿 | 跑过了 |
| **未发布** | 紫 | 只在 `download` 那一格出现：这个项目还没发布过（仓库里没有 `scripts/release.json`），所以没东西可下 |
| **未安装** | 青 | 只在 `uninstall` / `sudo-uninstall` 那两格出现：**现在没什么可撤的**（还没装）。它和「不支持」不是一回事 —— 后者是"这个项目根本没这项能力" |

`install` 和 `uninstall` 是**成对**的两列，`sudo安装` 和 `sudo卸载` 也是这样：

- **装之前**：`install` = 可执行，`uninstall` = 未安装（没东西可撤）；
- **装之后**：`install` = 已完成，`uninstall` = 可执行（现在撤得掉）。

`install` 那一列显示的是**你这台机器上的进度**，所以它会变：装过一个项目就从黄变绿，
换台机器或者卸掉它又变回黄。（`build` / `sudo` 那两列同理：跑过一次就变绿。）

下面是这台机器上前几行的样子（**节选，实际以你自己敲出来的为准**）：

```
┌─────────────────────────┬──────┬────────┬────────┬────────┬──────────┬──────────┬────────┬────────┬────────┬──────────┬──────────┬──────────┐
│ 项目                    │ prio │  构建  │  安装  │  卸载  │ sudo安装 │ sudo卸载 │ 做gz包 │ 发布包 │ 下gz包 │ 解容器层 │ 推容器层 │ 拉容器层 │
├─────────────────────────┼──────┼────────┼────────┼────────┼──────────┼──────────┼────────┼────────┼────────┼──────────┼──────────┼──────────┤
│ bootstrap               │ 5    │ 不支持 │ 已完成 │ 可执行 │ 不支持   │ 不支持   │ 已完成 │ 已完成 │ 可执行 │ 不支持   │ 不支持   │ 不支持   │
│ os/ubuntu               │ 5    │ 不支持 │ 不支持 │ 不支持 │ 可执行   │ 未安装   │ 已完成 │ 已完成 │ 可执行 │ 不支持   │ 不支持   │ 不支持   │
│ shell/oh-my-zsh         │ 10   │ 不支持 │ 已完成 │ 可执行 │ 不支持   │ 不支持   │ 已完成 │ 已完成 │ 可执行 │ 不支持   │ 不支持   │ 不支持   │
│ …（其余项目省略）        │      │        │        │        │          │          │        │        │        │          │          │          │
└─────────────────────────┴──────┴────────┴────────┴────────┴──────────┴──────────┴────────┴────────┴────────┴──────────┴──────────┴──────────┘
```

**这台机器上没有 sudo 的话，表会少两列**（`sudo安装` / `sudo卸载`，13 列变 11 列）。
看板**每次跑都重新探一次**这台机器能不能提权（权限可能刚加上），判定结果直接决定摆哪几列：

- **能提权**（本来就是 root / `sudo` 免密 / 刚输过密码、凭证还在缓存里）：13 列；
- **不能**（没有 sudo；有 sudo 但要密码而凭证已过期；或者你设了 `WTOOL_SUDO=never`）：11 列，
  表下面的图例会写清原因和后果。

看板**不缓存**这个判定：权限或凭证一变，不用重装、不用重开 shell，重跑一次 `wtool` 就看到了。
**有 sudo 但要密码的机器**照样列那两列（wtool 靠"你在不在 `sudo`/`wheel` 组"判断，
不会为了探测弹密码框）；真去跑 `wtool sudo-bootstrap` 时系统会照常问你要密码。
判断实在不准（比如用了 `NOPASSWD` 之类的特殊配置），用 `WTOOL_SUDO=yes` / `=never`
直接告诉它 —— `=never` 只影响它怎么判断，`sudo-*` 命令本身没被删掉。

**某一格看不懂、想知道"为什么是这个状态"：`wtool status <项目>`。** 它把看板按行摊开，
每一列给你三样东西：**状态**、**对应的命令**、**依据**（这一格是从哪看出来的）。
项目写路径或者末段都行：

```bash
wtool status editor/astronvim_v5
```

（`status` 是**只看不动**的命令：不写任何状态、也不碰你的 `$HOME`。它**不带参数**时是
另一种形态：登记表 + 软链检查 —— 适合回答"我是不是把什么东西删掉了"。）

表后面还有四段：`wtool install` 能装哪些、`wtool sudo-install` 能装哪些、
`wtool bootstrap` 这次会装哪些（按顺序、谁被跳过）、`wtool sudo-bootstrap` 会跑哪些。

> 三条「层」命令各占一列：`解容器层`（`unpack-layer`）的「已完成」看的是 `__output/` 里
> 有没有解出来的东西；而 **`push-layer` / `pull-layer` 推过没、拉过没，本机不记账** ——
> 它们最高只到「可执行」，真状态要去镜像仓库看。

### 6.3 加一个项目 / 自定义一个项目

`wtool.xml` 用几行 XML 说清楚"我有哪些文件要被 shell 加载""哪些文件要软链到哪里"。
剩下的 —— 建链接、写 shell 块、保证顺序、记录状态、支持卸载 —— 全部由 `wtool` 负责。

一个项目最少只需要两部分：

```
terminal/tmux/
├── wtool.xml      声明：这个项目有哪些东西要装、装到哪
├── tmux.conf      实际的配置文件
├── env.zsh        需要在 shell 里生效的环境变量（可选）
└── scripts/       通用机制表达不了的动作，**只有两种**（可选）
    ├── build.sh     需要自己产出时（产物写进 __output/）
    └── install.sh   有自定义安装步骤时
```

`wtool init <目录>` 给你起一个骨架（`--priority N` 定加载顺序，`--all` 连可选文件一起生成），
然后照着改 `wtool.xml`。改完跑一句 `wtool validate <项目目录>` 看写得对不对。

**只有通用机制表达不了的事情，项目才需要额外提供一个脚本**，都放在项目自己的
`scripts/` 下，**只有两种**：

| 脚本 | 什么时候需要 | 对应的命令 |
|---|---|---|
| `build.sh` | 这个项目要自己编（比如从源码编一个编辑器） | `wtool build <项目>` |
| `install.sh` | 装它需要通用机制做不到的步骤 | `wtool install <项目>` |
| `install.sh --uninstall` | 撤销上面做的 | `wtool uninstall <项目>` |

**这两个脚本只有引擎会跑，别自己去敲。** 引擎调它们的时候会导好环境变量
（`WTOOL_PROJECT_DIR` / `WTOOL_PREFIX` …）、按顺序铺实体和软链、并记下"装过什么"；
绕过引擎直接跑，账上没有这一笔，以后 `wtool uninstall` 就撤不干净。

**下载、打包、上传都不用项目写脚本**：`wtool download-release` / `unpack-release`
（取现成的包）和 `wtool pack-release` / `publish-release`（打包上传）是引擎自带的命令，
每个项目走的都是同一条路。老项目里的 `download.sh` / `publish.sh` / `extract.sh`
已经退休，看到它们可以当历史遗留。

写 `install.sh` 的时候有三条硬契约（都是踩过的）：

1. **产物落在 `$WTOOL_PREFIX`（默认 `~/.wtool/usr`）下面。** 不是 `~/.local`。
   `$HOME` 里只允许留**软链**（登记进清单，可撤销）。违反的后果：`wtool uninstall`
   撤不掉，`$HOME` 被污染且没人知道是谁放的。
2. **`build.sh` 产出的形状，必须和 `download-release` + `unpack-release` 解出来的完全一样。**
   这是 `build+install` 与 `download+install` 等价的前提。
3. **shell 集成要靠"环境变量块"，而且要带全。** 最容易漏的是 `PATH` ——
   只写 `NVIM_APPNAME` 那种，表现为"装完了但敲命令是 command not found"，
   而 `~/.config` 里又看得到东西，看起来像装了一半。**`$WTOOL_PREFIX/bin` 一定要进 PATH。**

另外两个**生成物**（不是脚本，是文本，要提交进仓库）：

| 文件 | 谁写 | 干什么 |
|---|---|---|
| `scripts/release.json` | `wtool publish-release`（上传成功后） | "这一版发布了什么"：每个文件的名字、大小、校验值。`download-release` 照它下 |
| `docs/download.md` | `wtool pack-release` | 给人看的下载页；项目 `README.md` 里留一行指过来就行 |

**同一份 `env` 要配 zsh / bash 两份。** 项目里的 `env.zsh` 必须配一份等价的 `env.bash`，
`wtool.xml` 里两份都声明 —— 受众里有人机器上**没有 zsh**（公司机器很常见），
只写一份的后果是"那个 shell 的用户敲命令 command not found"，而 rc 文件里看起来明明装过了。

### 6.4 不要手改的地方

- 项目的 `wtool.xml` 可以改（那是给你声明用的），改完跑 `wtool validate <项目目录>` 看一眼
- 项目里的 `__output/` / `__release/` / `__layer/` 是**产物**，不要手改，也不要把文件放进
  Git —— 它们在 `.gitignore` 里是有原因的
- `~/.wtool/` 下的东西不要手改，那是生成物；要改就改声明再重跑
- `~/.local/state/wtool/` 是状态记录（谁装过、谁发布过），**只由 `wtool` 写**。
  想清干净就用 `wtool kill-self-forever`
- 各项目 `scripts/` 下的脚本可以读、可以照着改，但别在没跑过的机器上盲改
- [`download.md`](download.md) 里 `wtool:downloads` 标记**中间**的内容是引擎生成的，
  手改一定会被下一次刷新冲掉 —— 要改就改标记**外面**的字

---

## 7. 常见问题

**`wtool`: command not found**

引擎挂在 `~/.wtool/bootstrap`，靠 shell 托管块加进 `PATH`（Tab 补全也挂在同一个块上）。
重开一个终端，或者：

```bash
exec $SHELL        # bash / zsh 都行
```

**按 Tab 补出来的是当前目录的文件名，不是 wtool 的命令**

补全要**新开的 shell** 才读得到。还不行就确认两件事：`wtool version` 能不能敲、
这个 shell 是不是 bash / zsh（补全只做了这两份）。能敲命令、Tab 还是补文件名的话，
跑一次 `wtool install bootstrap --force` 再重开 shell。

**`wtool` 报"不是 git 仓库"或"有未提交改动"**

这是故意的：安装前要能确定"装的是哪个版本"。先提交，或者确实不在乎版本就加 `--force`。

**装完发现某个链接不对**

```bash
cd <工作区目录>
wtool check                        # 看哪些登记的链接不见了（声明/日志/磁盘对比）
wtool repair all                   # 让引擎把缺的补回来（只补不删，不跑项目脚本）
wtool install <项目目录> --force    # 项目脚本装出来的实体也缺了，才重新装一遍
```

`install` 是幂等的，重装不会出问题；`repair` 更轻，适合"只是软链丢了"这种情况。

**看板显示「待产出」，但项目里明明有产物**

多半是**老工作区里的目录名还没改**：`__output/` / `__release/` / `__layer/` 是后来的名字，
老的 `output/` / `release/` / `layer/` 不会被自动搬。`wtool check` 认得出旧目录时，
会把该敲的 `mv` 直接打出来（只提示，不自动搬）。

**下载下来的包怎么用 / 哪个是最新版**

看 [`download.md`](download.md)。那一页里的资产表是引擎自动刷新的，
表里没有的项目就是"引擎这次没查到它的包"（还没发过、或者 tag 对不上）。

**想看看 `wtool` 到底把东西放哪了**

```bash
wtool doctor     # 环境、路径、状态目录、编译安装前缀
wtool check      # 登记的东西是不是都还在（声明/日志/磁盘对比，含软链目标）
```

**想彻底退回去**

```bash
cd <工作区目录>
wtool uninstall <项目目录>          # 一个项目
wtool uninstall all                # 所有项目（=$HOME 软链 + ~/.wtool 里的实体）
./uninstall.sh                     # 连 wtool 自己一起卸（在工作区根目录跑）
wtool kill-self-forever            # 最后：连状态记录也删掉，要求逐字确认
```

---

以上只是速查。**完整的说明 —— 项目结构、每个命令的细节、所有子项目的索引 ——
在 [`guide.md`](guide.md)；下载和发布相关的都在 [`download.md`](download.md)。**
