# wtool

把一堆零散的个人配置和工具——shell、终端、编辑器、主题——用一条命令装到一台新机器上。

这不是一个软件，是一套**管理方式**：所有配置以独立的小项目形式存在，各自放在自己的 Git 仓库里，由一个叫 `wtool` 的小引擎统一安装、构建、发布。

---

## 0. 在一台新机器上，从这里开始

**先装 `wtool` 自己，再让它去装项目。** 一共五步：

```bash
# 1. 把仓库拿到本地（第一次）
repo init -u ssh://git@github.com/allinkernel/w_manifests.git -b wtool
repo sync

# 2. 装 wtool 自己 —— 会准备好运行环境（python3/git/…），然后停下
cd <工作区目录>
./install.sh

# 3. 让当前 shell 认识 wtool（PATH 是 shell 启动时定下的，所以要重读一次）
exec $SHELL
#    或者干脆重开一个终端

# 4. 装系统层的东西：apt 软件包、系统配置文件（换 apt 源之类）。这一步可能要 sudo
wtool sudo-bootstrap

# 5. 装其余的项目：文件、软链、shell 集成。不需要 sudo，也不联网
wtool bootstrap
```

**第 4 步和第 5 步为什么分开？** 因为**要 sudo 的事和不要 sudo 的事不能混在一格里**。
第 4 步动的是整个系统（apt 包、`/etc` 下的文件），第 5 步动的只是你自己的家目录。
混在一条命令里，你看到一屏输出，分不清该修哪一头。

这条分工贯穿整套命令：**带 `sudo-` 前缀的才可能要 sudo，其余的命令永不要 sudo、永不联网。**
所以 `wtool uninstall` 不会去动 `/etc`——那是 `wtool sudo-uninstall` 的事。

**第 2 步为什么到那里就停？** 因为它只负责「让 `wtool` 这条命令能用」，
不装任何项目。这样失败原因清清楚楚：`install.sh` 挂了 = 系统环境问题
（缺依赖、源连不上）；后面几条挂了 = 某个项目自己的问题。

第 2 步跑完它会把后面该做什么直接打在屏幕上，不用回来翻文档。

**不想在真机上试？** 用容器跑一遍（`--network=host` 不能省：容器里的
`127.0.0.1` 只有在这个网络模式下才是宿主自己，脚本靠它自动接上宿主代理）：

```bash
# 从头走一遍，每一步自己决定（等价于"刚 repo sync 完"）
docker run --rm -it --network=host -v "$PWD":/wtool:ro \
  ubuntu:24.04 bash /wtool/bootstrap/scripts/container-raw.sh

# 或者一步到位，直接给一个装好的环境
docker run --rm -it --network=host -v "$PWD":/wtool:ro \
  ubuntu:24.04 bash /wtool/bootstrap/scripts/container-shell.sh
```

（`$PWD` 要换成工作区目录；两个容器脚本的差别见第 4.3 节。）

> **怎么看下面这些表**：✅ = 现在就能用；🚧 = 已经设计好、还没实现，
> 今天敲它会报"不认识这条命令"。缺口清单在第 1.6 节。

---

## 1. 它是怎么工作的

### 1.1 三个阶段，一张图

在新机器上重建开发环境，麻烦的从来不是"装"这个动作，而是四个副作用：
**装过什么记不住、装在哪儿说不清、装错了撤不掉、换台机器得重来一遍**。

`wtool` 把这件事拆成三个阶段，每个阶段的输入输出都不重叠：

```
  ① 产出 ── 需要网络；build 还需要编译器
  ┌────────────────────────────────────────────────┐
  │  wtool build       自己编                       │
  │  wtool download    下别人编好的（两者等价）      │
  └───────────────────────┬────────────────────────┘
                          │ 写
                          ▼
  ┌────────────────────────────────────────────────┐
  │  项目的 release/ 目录 —— 产物的中转站            │
  │  （不进 Git，可以整个拷到别的机器）               │
  └───────────────────────┬────────────────────────┘
                          │ 读（install 是唯一的读者）
                          ▼
  ② 铺设 / ③ 打包发布
  ┌────────────────────────────────────────────────┐
  │  wtool install        铺进 ~/.wtool ← 断网也能跑 │
  │  wtool pack-release   打包 → 项目的 publish/     │
  │  wtool unpack-release 校验 + 解包                │
  │  wtool publish        打包 + 上传 ← 需要网络     │
  └────────────────────────────────────────────────┘
```

一句话记住：**「编」和「下」产出同一个东西，装只认那个东西。**

所以：

- 换台机器，只要有 `release/`，**不用重编**；
- `install` 跑得再多次也不会产生新东西，**可以随便重跑**；
- 卸载 = 把 `install` 铺出去的东西收回来。

### 1.2 命令速查

**每条命令都要能回答三个问题：要 sudo 吗、碰网络吗、能撤吗。**
下面就是这张表（命令后面写 `<路径>` 的，指的是**项目目录**，比如 `terminal/tmux`）。

**产出 `release/`**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool build <路径>` | 自己编：编译源码、拉插件、装语言服务，结果写进项目的 `release/` | ❌ | ✅ | 删掉 `release/` 就没了 |
| `wtool download <路径>` | 从发布页下别人编好的包，解开写进 `release/` 的**同一个位置** | ❌ | ✅ | 同上 |

**安装到系统**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool install <路径>` | 把 `release/` 铺进 `~/.wtool/usr`，再在 `$HOME` 里建软链、加 shell 集成 | **❌ 永不要** | **❌ 永不联网** | **完全可逆**，一条命令原样撤回 |
| `wtool uninstall <路径>` | 撤销 `install` | **❌ 永不要** | ❌ | —— |
| `wtool sudo-install <路径>` | 装系统软件包、改系统文件（换 apt 源之类） | 🚧 **可能要** | ✅ | ⚠️ apt 包撤不干净；`/etc` 下的文件可以还原 |
| `wtool sudo-uninstall <路径>` | 撤销 `sudo-install`：卸载 apt 包 + 还原 `/etc` | 🚧 **可能要** | ❌ | —— |

**打包与分发**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool pack-release <路径>` | 打成**两个包**（源码包 + 产物包）写进项目的 `publish/`，各带一个校验文件 | ❌ | ❌ | 删掉 `publish/` 就没了 |
| `wtool unpack-release <路径>` | 校验 + 解包发布包（大项目是分卷的），解到 `release/` | ❌ | ❌ | 同上 |
| `wtool publish [<路径>]` | `pack-release` + 上传到项目自己的 GitHub Release 页 | ❌ | ✅ | 已经被人下载走的收不回来 |

**批量**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool bootstrap` | 所有项目 `install` 一遍 | ❌ | ❌ | 逐个 `uninstall` 即可 |
| `wtool sudo-bootstrap` | 所有项目 `sudo-install` 一遍 | 🚧 可能要 | ✅ | 同上，逐个项目来 |

**检查与修复**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool check [<路径>\|all]` | 三者对比：**声明**（`wtool.xml`）、**日志**（装过什么）、**磁盘**（现在有什么） | ❌ | ❌ | 只看不动 |
| `wtool repair [<路径>\|all]` | 修 `check` 报出来的问题（补软链、清多余记录） | ❌ | ❌ | 只按 `check` 的结果修，不引入新东西 |

**销毁**

| 命令 | 做什么 | 要 sudo 吗 | 碰网络吗 | 可撤吗 |
|---|---|---|---|---|
| `wtool kill-self-forever` | 删掉 wtool 的一切痕迹（**含状态记录**）。会让你逐字输入一句全大写确认，并先列清删什么、不删什么 | ❌ | ❌ | ❌ **不可撤，这就是它的语义** |

**信息类（只看不动）**

| 命令 | 做什么 |
|---|---|
| `wtool` | 不带参数跑一下 = 第 1.5 节那张能力总览表 |
| `wtool doctor` | 环境诊断（版本、系统、状态目录、缺什么） |
| `wtool status [<路径>]` | 检查登记的软链是不是都还在 |
| `wtool validate <路径>` | 检查某个项目的 `wtool.xml` 写得对不对 |
| `wtool init <目录>` | 新建一个 wtool 项目 |
| `wtool version` | 打印版本 |

**会动手的那些命令**（`build` / `download` / `install` / `uninstall` / `sudo-install` /
`sudo-uninstall` / `pack-release` / `unpack-release` / `publish` / `bootstrap` /
`sudo-bootstrap` / `repair`）都支持 `--dry-run`：先打印计划、不真的动系统。

**"永不要 sudo、永不联网"不是口号，它是可逆性的实现方式。** 只要 `install`
不产生任何新的外部依赖，"撤销"就是把铺出去的东西删掉这么简单。
一旦它偷偷开始下载或编译，撤销就成了一句空话——所以需要网络和编译器的活
全在 `build` / `download` 里，需要 root 的活全在 `sudo-*` 里。

> apt 装的系统包**没有记账**，所以严格来说撤不回来。
> `sudo-uninstall` 能做的：把装的包卸掉、把改过的 `/etc` 文件从备份还原回去。
> 这就是为什么它必须单独一条命令——让"撤不干净"这件事有个明确的入口，
> 而不是混在 `install` 里假装它可逆。

### 1.3 `release/` 和 `publish/` 是什么

**`release/`（发布目录）**：每个需要产出的项目，在自己目录下都有一个 `release/` 目录，
它是**构建产物的唯一落脚点**。**`publish/`（打包目录）** 就在它旁边，
装的是 `pack-release` 打出来的发布包。

```
<项目>/
├── wtool.xml            项目声明
├── scripts/             这个项目专属的动作脚本
├── release/             ← build 或 download 的产物，不进 Git
│   └── ubuntu_22/       按"系统_版本"分目录
│       ├── main/        底座：主程序 + 基础配置
│       └── lang/        语言增量包，依赖 main
│           └── cpp/ python/ java/ rust/ go/ lua/
└── publish/             ← pack-release 的产物，不进 Git
    ├── xxx-源码.zip     整个项目（不含 release/ 和 publish/）
    ├── xxx-源码-hash.txt
    ├── xxx-release.zip  产物包：release/ 里的东西（大项目切成 -vol01、-vol02…）
    ├── xxx-release-hash.txt
    └── dist.json        分卷清单：每一卷叫什么、多大、校验值是多少
```

**`release/` 的四条规则**：

| 规则 | 为什么 |
|---|---|
| **`release/` 不进 Git** | 它是机器特定的二进制产物，跟着仓库走只会把仓库撑爆 |
| **`build` 和 `download` 写到完全相同的路径** | 这是两条路等价的**唯一**实现方式 |
| **`install` 只读它，不写它** | 产物层和安装层分开，重装不用重建 |
| **整个目录可以搬走** | 拷到另一台机器 + `wtool install`，环境就复现了 |

**为什么按"系统_版本"分目录？** 编译出来的程序依赖系统的基础库（glibc）。
在 Ubuntu 22.04 上编的在 20.04 上跑不起来，反过来可以 —— 基础库只保证往前兼容。
所以每个目标系统单独出一份。**在最老的那个系统里编，一张包能通吃所有更新的系统。**

> 这句话对"我们自己编出来的东西"成立。**有个例外**：如果项目还要下**别人预先编好的**
> 二进制，那些二进制的底线由别人怎么编决定，可能比你的构建系统还新。
> 这类项目要在构建时逐个检查，超线的直接让构建失败，而不是发一个装上才发现不能用的包。

**`pack-release` 为什么要打两个包？** 因为你可能只需要其中一个：

- **源码包**（整个项目）——给"要自己编"的机器，或者存档
- **产物包**（`release/` 里的东西）——给"只要用"的机器，
  它**自带编译好的程序**，解开就能用，不需要源码、不需要编译器

装到别的机器上时，**只需要产物包**。项目大到一个包传不完的时候，
产物包会切成若干分卷，放在项目的 `publish/` 里，旁边配一份 `dist.json` 说明每一卷叫什么、
多大、校验值是多少——`wtool unpack-release` 照着它校验和拼接，不需要人记顺序。

**这三个动作拼起来是一条闭环**，而且可以当成一条断言来验：

```
pack-release → unpack-release   ≡   repo sync 之后 build 一遍   ≡   repo sync 之后 download 一遍
```

### 1.4 装的东西放在哪：三层

这是整套设计里最值得记住的一件事 —— **每一层只放一种东西**。

```
   ①  release/<系统_版本>/      产物    可以整目录删掉，删了等于"没构建过"
          │  install 读
          ▼
   ②  ~/.wtool/                实体    它是 wtool 版的 $HOME，路径一一对应
          │  引擎建软链
          ▼
   ③  你的 $HOME/               软链    ~/.config/xxx 之类，全都是软链
                                       ~/.zshrc 里只多一小段 loader
```

**`~/.wtool/` 是"影子家目录"**：它按 XDG 规范一一对应你的家目录，只是东西都住在里面。

```
你的 $HOME                      ~/.wtool/
~/.config/astronvim_v5     ←→   ~/.wtool/.config/astronvim_v5
~/usr                      ←→   ~/.wtool/usr
~/.tmux.conf               ←→   ~/.wtool/.tmux.conf
```

路径长得一模一样，所以"这个文件从哪来的、删了会少什么"一眼就能看出来。
**编译产物、下载产物统一放在 `~/.wtool/usr/` 这一格**，`~/usr` 就是它接回 `$HOME`
的那条软链——`~/usr/bin/nvim` 和 `~/.wtool/usr/bin/nvim` 是同一个东西。
（早先的版本用的是 `~/.wtool/config/xxx` 这种名字，两边对不上，
需要对着文档查——现在不用了。）

**反过来也成立**：`~/.wtool/` 下面**不会出现你 `$HOME` 里没有的路径**。
引擎自己用的东西（自举、中转软链、临时文件）都关在 `~/.wtool/wtool-work-dir/` 里，
那是唯一一个故意不像家目录的目录。

**你的家目录里不该多出一个实体文件。** 所以卸载是干净的：
`wtool uninstall <项目>` 把②里的实体和③里的软链一起撤掉，家目录回到装之前。

配置文件和 shell 集成也走这条路：每个项目贡献的环境变量收在 `~/.wtool/.zshrc` 里，
你的 `~/.zshrc` 里只会多出**一小段 loader** 指过去，而不是每个项目各插一段。
（用 bash 的人对应 `~/.wtool/.bashrc`，两个 shell 各有一份，行为一致。）

**引擎自己用的东西**（自举、中转软链、临时文件）都在 `~/.wtool/wtool-work-dir/` 里 ——
目录名就是它的用途。**状态记录**（谁装过、谁发布过）在 `~/.local/state/wtool/`，
这个位置是 XDG 标准给"状态"用的，你不会顺手把它当缓存删掉。

【图片占位】![三层路径](.pic/layers.png)

<!-- TODO: 画一张三层路径图保存为 .pic/layers.png，比 ASCII 图更直观 -->

### 1.5 能力和进度：那张表

**每个项目里有一个 `wtool.xml`。有它 = 这是个 wtool 项目；没有 = 就是一堆文件，不参与 wtool。**
没有第二种判据 —— 不用问"这个目录算不算项目"，看有没有那个文件就行。

`wtool.xml` 用几行 XML 说清楚"我有哪些文件要被 shell 加载""哪些文件要软链到哪里"。
剩下的——建链接、写 shell 块、保证顺序、记录状态、支持卸载——全部由 `wtool` 负责。

只有通用机制表达不了的事情，项目才需要额外提供一个脚本，都放在项目自己的 `scripts/` 下：

| 脚本 | 什么时候需要 | 对应的命令 |
|---|---|---|
| `build.sh` | 这个项目要自己编（比如从源码编一个编辑器） | `wtool build <项目>` |
| `download.sh` | 这个项目可以从发布页下别人编好的包，省掉编译 | `wtool download <项目>` |
| `install.sh` | 装它需要通用机制做不到的步骤 | `wtool install <项目目录>` |
| `publish.sh` | 打成两个包还不够、需要额外处理时才要（很少见） | `wtool publish <项目>` |

**这些脚本在不在，就代表这个项目有没有这几项能力**（`install` 还有一条来源：`wtool.xml` 里声明了 `link` 或 `zshrc`/`bashrc` 也算有）。`wtool` 不带参数跑一下，会看到一张表，哪一格写着「可执行」或「已完成」，就说明这个项目能做这件事：

```
┌──────────────────────┬──────┬────────────┬────────────┬────────────┬────────────┐
│ 项目                 │ prio │ build      │ download   │ install    │ publish    │
├──────────────────────┼──────┼────────────┼────────────┼────────────┼────────────┤
│ bootstrap            │ 5    │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ os/ubuntu            │ 5    │ 不支持     │ 不支持     │ 不支持     │ 可执行     │
│ shell/oh-my-zsh      │ 10   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ shell/zsh            │ 20   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ tools/repo           │ 40   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ tools/android_repack │ 45   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ tools/gerrit-gate    │ 46   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ tools/dsh-remote     │ 47   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ harness/dsh-conf     │ 48   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ terminal/tmux        │ 50   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ terminal/fzf         │ 60   │ 不支持     │ 不支持     │ 可执行     │ 可执行     │
│ editor/astronvim_v5  │ 70   │ 可执行     │ 可执行     │ 待构建下载 │ 待构建下载 │
└──────────────────────┴──────┴────────────┴────────────┴────────────┴────────────┘
```

（这是在一台**什么都没装过**的机器上跑出来的样子，所以状态列大多是"可执行"。
你自己的机器上装过的项目会显示"已完成"。）

`prio`（优先级）越小越先加载，决定环境变量块的顺序 —— 引擎要在最前面，所以是 5。

每一格是**四种状态之一**，终端里各有颜色：

| 状态 | 颜色 | 意思 |
|---|---|---|
| **不支持** | 红 | 这个项目没这项能力（比如纯配置项目不能 build） |
| **可执行** | 黄 | 现在就能跑 |
| **待构建下载** | 蓝 | 能力有，但得先 `build` 或 `download` |
| **已完成** | 绿 | 跑过了 |

`install` 和 `publish` 显示的是**你这台机器上的进度**，所以它会变：装过一个项目就从黄变绿，换台机器或者卸掉它又变回黄。

**这四列是一条流水线，后面的依赖前面的：**

```
build 或 download  →  install  →  publish
```

前置没做时 `install` / `publish` 会**直接报错告诉你去跑哪条**，不会替你跑 ——
因为「自己编」和「下载别人编好的」是两个不该由工具替你做的决定。

【图片占位】![wtool 能力总览](.pic/table.png)

<!-- TODO: 在装好 wtool 的机器上执行 `wtool`，把输出截图保存为 .pic/table.png
     建议终端宽度 100 列以上、保留颜色，这样四种状态的区别看得出来。 -->

### 1.6 现在到哪一步了

上面这套是**正在落地的目标**。已经做到的和还没做的：

| | 状态 |
|---|---|
| `wtool.xml` 存在即项目、`<link>` 三段映射、软链只在 `$HOME` | 🚧 目标形态；今天 `wtool.xml` 里的写法还是旧的 `src=`/`dest=` |
| 影子家目录（实体在 `~/.wtool`，路径和 `$HOME` 一一对应） | 🚧 目标形态；今天产物都在 `~/.wtool/usr/` 下，`~/usr` 这条软链还没建 |
| 引擎自己的东西（自举、中转软链、临时）收在 `~/.wtool/wtool-work-dir/` | 🚧 今天散在 `~/.wtool/bootstrap`、`~/.wtool/src`、`~/.wtool/links/`（最后这个违反了"影子家目录里只放家目录里有的路径"，要收进来） |
| `install` 永不要 sudo、永不联网 | ✅ 本机安装这条路已经是；但**从发布包铺开**那条路（`publish/` 里放着 `dist.json` 加分卷时）今天还会装系统依赖，而且是直接铺到 `$HOME` |
| 执行顺序：先跑项目的 `install.sh`，再铺 `$HOME` 软链 | 🚧 今天是反的（先铺软链再跑脚本） |
| `build` / `download` 写进项目的 `release/` 再给 `install` 读 | 🚧 还没改，目前产物直接落在 `~/.wtool/usr` |
| `pack-release` / `unpack-release` / `publish` 分成三条 | 🚧 打包和上传还是一条命令，也没有 `unpack-release` |
| `sudo-install` / `sudo-uninstall` / `sudo-bootstrap` | 🚧 今天叫 `provision`，没有批量那条 |
| `check` / `repair` / `kill-self-forever` | 🚧 还没有 |
| `wtool status` 含软链检查、`wtool doctor` 含环境变量 | 🚧 今天 `list` 和 `env` 还是单独两条命令 |
| 语言包（`lang/cpp`、`lang/python`…）按需叠加 | 🚧 设计好了，还没实现 |

**今天敲命令的对照**（左：本文档里的新名字；右：现在实际存在的名字）：

| 新名字 | 今天实际敲 |
|---|---|
| `wtool sudo-install <路径>` | `wtool provision <路径>` |
| `wtool doctor` | `wtool doctor` 和 `wtool env` 两条 |
| `wtool status <路径>` | `wtool status` 和 `wtool list` 两条 |
| `wtool`（裸跑） | `wtool table` 也行 |
| —— | `wtool scaffold` 已改名叫 `wtool init` |

对使用者来说，差别只有一个：**今天换机器还是得重编或重下**，
等 `release/` 那层落地之后，产物目录可以整个拷过去。

### 1.7 现在有哪些项目

| 项目 | 一句话简介 |
|---|---|
| [wtool-base](https://github.com/allinkernel/wtool) | 你现在看的这份文档。只有文档，没有工具 |
| [wtool-bootstrap](https://github.com/allinkernel/wtool-bootstrap) | 引擎本体：`wtool` 命令、安装/卸载机制、清单解析、发布逻辑。其他项目都靠它 |
| [wtool-os-ubuntu](https://github.com/allinkernel/wtool-os-ubuntu) | Ubuntu 上要装的系统软件包清单，以及把 apt 源换成国内镜像 |
| [wtool-zsh](https://github.com/allinkernel/wtool-zsh) | zsh 自身的配置和补全别名 |
| [wtool-ohmyzsh](https://github.com/allinkernel/wtool-ohmyzsh) | oh-my-zsh 本体，带自己的定制和插件选择 |
| [wtool-tmux-config](https://github.com/allinkernel/wtool-tmux-config) | tmux 配置，外加一组显示 CPU/内存/磁盘/网络的小脚本 |
| [wtool-fzf-binary](https://github.com/allinkernel/wtool-fzf-binary) | fzf 的预编译二进制，省得每台机器重编 |
| [wtool-repo](https://github.com/allinkernel/wtool-repo) | `repo` 工具（管理多仓库的那个）和它的快捷命令 |
| [wtool-android_repack](https://github.com/allinkernel/wtool-android_repack) | Android 镜像"解包 → 改 → 重新打包"的流水线 |
| [wtool-gerrit-gate](https://github.com/allinkernel/wtool-gerrit-gate) | 本机的代码检视闸门（Gerrit），改动要过它才进主线 |
| [wtool-dsh-remote](https://github.com/allinkernel/wtool-dsh-remote) | 不在电脑前时用手机接管会话 |
| [wtool-astronvim_v5](https://github.com/allinkernel/wtool-astronvim_v5) | 一整套 Neovim 环境：编译 nvim、装插件、装语言服务器、打成发布包 |
| [wtool-astronvim_v5_config](https://github.com/allinkernel/wtool-astronvim_v5_config) | 上面那套环境的具体配置（快捷键、主题、插件选择） |
| [typora-LightMindTheme](https://github.com/allinkernel/typora-LightMindTheme) | Typora 的一个自制主题 |

每个项目的细节看它自己的 README（点上面的名字）。

> 上面这些仓库**不一定都是 wtool 项目**。判断标准只有一个：目录里有没有 `wtool.xml`。
> 纯文档、纯素材的仓库（比如这份文档自己）没有它，也就不参与 `wtool install`。
>
> 反过来也一样：第 1.5 节那张表里可能出现**这里没列**的条目 —— 那些是助手自用、
> 或者还没建独立 GitHub 仓库的内部项目（比如 `harness/dsh-conf`）。要完整的清单，
> 看表而不是看这份列表。

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
接着 `cd ~/self/wtool && ./bootstrap/scripts/install.sh`（第一次要用完整路径，
它会把根目录的 `./install.sh` 等入口补齐，之后就能直接用短的了）。

### PowerShell（Windows 10 及以上自带 tar）

```powershell
$d = "$HOME\self"; New-Item -ItemType Directory -Force -Path $d | Out-Null; Set-Location $d
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-bootstrap/releases/download/snapshot-2026-09-15/bootstrap-2026-09-15.tar.gz" -OutFile "bootstrap-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/typora-LightMindTheme/releases/download/snapshot-2026-09-15/themes-typora-lightmind-2026-09-15.tar.gz" -OutFile "themes-typora-lightmind-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-os-ubuntu/releases/download/snapshot-2026-09-15/os-ubuntu-2026-09-15.tar.gz" -OutFile "os-ubuntu-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-ohmyzsh/releases/download/snapshot-2026-09-15/shell-oh-my-zsh-2026-09-15.tar.gz" -OutFile "shell-oh-my-zsh-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-zsh/releases/download/snapshot-2026-09-15/shell-zsh-2026-09-15.tar.gz" -OutFile "shell-zsh-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-fzf-binary/releases/download/snapshot-2026-09-15/terminal-fzf-2026-09-15.tar.gz" -OutFile "terminal-fzf-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-tmux-config/releases/download/snapshot-2026-09-15/terminal-tmux-2026-09-15.tar.gz" -OutFile "terminal-tmux-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool-repo/releases/download/snapshot-2026-09-15/tools-repo-2026-09-15.tar.gz" -OutFile "tools-repo-2026-09-15.tar.gz"
Invoke-WebRequest -Uri "https://github.com/allinkernel/wtool/releases/download/snapshot-2026-09-15/wtool-base-2026-09-15.tar.gz" -OutFile "wtool-base-2026-09-15.tar.gz"
tar -xf bootstrap-2026-09-15.tar.gz
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

下载解压完成之后，你会得到一个 `~/self/wtool` 目录。进去，跑 `bootstrap/scripts/` 下面那个：

```bash
cd ~/self/wtool
./bootstrap/scripts/install.sh
```

**这一次要用完整路径**——解压出来的工作区还没有根目录那几个入口（`./install.sh`、`./README.md` 之类）。那些是 `repo` 工具在 `repo sync` 时按清单建的，而你是手动解压的。第一次跑它会顺手把它们补齐：

```
wtool-install: 第 2 步：工作区入口（/home/you/self/wtool）
wtool-install:   install.sh -> bootstrap/scripts/install.sh
wtool-install:   README.md -> wtool-base/README.md
...
```

之后 `./install.sh` 就能直接用了，和 `repo sync` 出来的工作区完全一样。

这个脚本只走四步：准备运行环境（缺 `python3`/`git` 就装上）、自举引擎到 `~/.wtool/wtool-work-dir/`（引擎自己的东西都收在这一个目录下，见 1.4）、补齐上面那些工作区入口、让 `wtool` 进 `PATH`。**做完就停，它不装任何项目**——屏幕最后会直接把接下来该敲的命令打给你（`exec $SHELL`，然后 `wtool sudo-bootstrap` / `wtool bootstrap`），照着走即可。

**要编译产物的项目（现在只有 Neovim 那套）还有一步**：它的 Release 页面里除了源码包，
还有产物包（大项目是若干分卷，配一个 `dist.json`）。把这些下到项目的 `publish/` 目录下，
用 `wtool unpack-release <项目目录>` 校验并解开，再 `wtool install <项目目录>` 收尾。
`unpack-release` 只认 `dist.json`，不需要你记分卷的顺序。

---

## 3. 怎么用

装完之后，`wtool` 命令就可以在任何目录下直接用了。

不过有几条命令要你告诉它**项目在哪**：`install` / `uninstall` / `sudo-install` /
`sudo-uninstall` / `validate` / `status` 认的是**项目目录**——在工作区根目录下写
`terminal/tmux` 就行，在别的地方要写全路径。`build` / `download` / `publish` 宽松些，
直接写项目名（`terminal/tmux`，甚至只要末段 `tmux`）也可以，在哪跑都认。

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
cd <工作区目录>                        # install / uninstall 认的是项目目录，在工作区根目录最省事
wtool install terminal/tmux         # 装一个项目
wtool uninstall terminal/tmux       # 撤销，系统回到装之前
```

`install` 是完全可逆的。想先看看它会做什么：

```bash
wtool install terminal/tmux --dry-run
```

它会打印出计划（要建哪些链接、要写哪几段 shell 块），但不真的动系统。

**装一个项目实际发生两件事，顺序是有意的**：

```
① 先跑项目自己的 scripts/install.sh   —— 把 release/ 里的东西铺进 ~/.wtool
② 再按 wtool.xml 建软链              —— 把 ~/.wtool 里的东西接到你的 $HOME
```

先①后②不能反：②建的软链**指向**①铺出来的东西，反了就是先建一堆悬空链接。

一次把不需要你先决策的项目都装上：

```bash
wtool sudo-bootstrap     # 系统层：apt 包、/etc 下的文件。可能要 sudo
wtool bootstrap          # 用户层：文件、软链、shell 集成。不需要 sudo、不联网
```

需要「编还是下」的项目它会跳过，并把该跑的命令列给你——见 3.3。

【图片占位】![wtool install 的输出](.pic/install.png)

<!-- TODO: 在一台干净机器（或容器）上执行，把输出截图保存为 .pic/install.png
     wtool bootstrap
     截图建议包含开始几行和结束几行，能看出"按项目逐个处理"的结构。
-->

### 3.3 构建和下载

有些项目要产出东西才能用——要么自己编，要么直接下别人编好的（比如那套 Neovim 环境）：

```bash
wtool build                      # 列出哪些项目可以构建
wtool build editor/astronvim_v5  # 自己编（小时级）

wtool download                   # 列出哪些项目能下现成的包
wtool download editor/astronvim_v5   # 从发布页拿（分钟级）
```

**这两条路二选一，结果完全等价。** 两条路都写进项目的 `release/` 目录、放在同一个位置，
所以之后的 `wtool install` 根本不关心它是从哪来的。能下就下。

这一步可以反复跑，中断了重来也不会坏——最坏只是白花一次时间。纯配置类的项目没有这一步。

### 3.4 打包与发布

**打包**（不联网，产物落在项目自己的 `publish/` 目录里）：

```bash
wtool pack-release editor/astronvim_v5
```

出来的是一对包——**源码包**（整个项目）和**产物包**（`release/` 里的东西），
各配一个校验文件。大项目的产物包会切成若干分卷，外加一份 `dist.json` 说明每一卷。

**解包**（在另一台机器上，或者你想验一遍包是好的）：

```bash
wtool unpack-release editor/astronvim_v5
```

它照 `dist.json` 校验每一卷的校验值、按正确顺序拼起来、解到 `release/`，然后你就能
`wtool install` 了。**装到别的机器上时只需要产物包**，不需要源码包。

**发布**（打包 + 上传到项目自己的 GitHub Release 页）：

```bash
wtool publish                    # 发布所有项目
wtool publish terminal/tmux      # 只发一个
wtool publish --dry-run          # 先看计划
```

发布完成后，本文档第 2 节的下载链接会自动更新成最新的 —— 那一段是 `wtool publish` 重写的，不用手动维护。

### 3.5 卸载：三条命令，别用 `rm -rf`

**`rm -rf ~/.wtool` 不是完整卸载。** 它只删掉了影子家目录里的实体，
你的 `$HOME` 里那些软链**还在**（全变成断链），`~/.zshrc` 里的 loader 块也还在。

正确的做法是三条命令，**管的东西不一样、权限也不一样**：

| 命令 | 管什么 | 要 sudo 吗 |
|---|---|---|
| `wtool uninstall all` | 撤销所有 `install`：`$HOME` 里的软链 + `~/.wtool` 里的实体 | ❌ |
| `wtool sudo-uninstall all` | 撤销所有 `sudo-install`：卸载 apt 包、还原 `/etc` 下的文件 | 🚧 可能要 |
| `wtool kill-self-forever` | 删掉 wtool 的一切痕迹，**含 `~/.local/state/wtool/` 里的状态记录** | ❌ |

`wtool uninstall` **不越权**：它不会去还原 `/etc`，因为那是 `sudo-uninstall` 的事。
反过来也一样。想只卸一个项目就把 `all` 换成项目目录。

**`kill-self-forever` 是第三条命令，因为它删的东西前两条都不碰**：状态记录
（谁装过、谁发布过）在 `~/.local/state/wtool/`，不在 `~/.wtool/` 里 ——
没有它，那本账永远留着。它会先列清**删什么、不删什么**，
再要求你**逐字输入一句全大写确认**，敲错一个字就什么都不做。

### 3.6 检查与修复

```bash
wtool check              # 全部项目：声明 / 日志 / 磁盘 三者对比
wtool check terminal/tmux
wtool repair all         # 修 check 报出来的
```

`check` 回答的是"我以为装了的东西，真的还在吗"：`wtool.xml` 里声明了什么、
日志里记着装过什么、磁盘上现在有什么——**三者对不上就报出来**。
`repair` 只按 `check` 的结果修，不会顺手引入新的东西。

### 3.7 其他命令

```bash
wtool doctor                        # 环境诊断（版本、系统、状态目录、缺什么）
wtool status [<项目目录>]            # 检查登记的软链接是不是都还在
wtool validate <项目目录>            # 检查某个项目的 wtool.xml 写得对不对
wtool init <目录> [--id ID] [--priority N] [--all]   # 新建一个 wtool 项目
wtool version
```

`build` / `download` / `install` / `uninstall` / `sudo-install` / `sudo-uninstall` /
`pack-release` / `unpack-release` / `publish` / `bootstrap` / `sudo-bootstrap` / `repair`
都支持 `--dry-run`：先打印计划、不真的动系统。
`status` / `doctor` / `validate` 这些只看不动的没有这个开关。

`wtool` 不带参数跑一下就是第 1 节那张能力总览表。

---

## 4. 仓库里这些脚本分别干什么

项目里有一堆同名的 `.sh`，容易搞混。按"谁调用谁"分三层看就清楚了。

### 4.1 工作区根目录看到的

根目录那几个是**软链接**，指向真正的文件（`repo sync` 建出来的）：

| 根目录 | 实际是 | 干什么 |
|---|---|---|
| `install.sh` | `bootstrap/scripts/install.sh` | 装 **wtool 自己**（准备运行环境、自举引擎、建工作区入口、让 `wtool` 进 `PATH`）。**不装任何项目** |
| `uninstall.sh` | `bootstrap/scripts/uninstall.sh` | 把 wtool 自己卸掉 |
| `README.md` | `wtool-base/README.md` | 就是本文 |
| `guide.md` | `wtool-base/guide.md` | 完整手册 |

记住一句分工：**根目录的 `install.sh` 只负责让 `wtool` 这条命令出现**，
项目是靠 `wtool install` 装的。这是两件事。

### 4.2 引擎

| 文件 | 干什么 |
|---|---|
| `bootstrap/wtool.sh` | 引擎本体，`wtool` 命令就是它的软链。所有 `wtool xxx` 都进这里 |
| `bootstrap/lib/*.py` | 只**算**不写：扫项目、算计划、画表、算环境变量 |
| `bootstrap/lib/*.sh` | 只**写**不算：落盘、记账、建链接、生成 rc |

刻意分成两半（Python 推理、Shell 动手），这样"会发生什么"可以在动手之前
完整算出来——`--dry-run` 才有意义。

### 4.3 给容器用的两个脚本

工作区挂进容器时，这两个差别很大：

| 脚本 | 做什么 | 什么时候用 |
|---|---|---|
| `bootstrap/scripts/container-shell.sh` | 装系统依赖 → 装引擎 → 跑一遍 `wtool bootstrap` → 把你丢进 zsh | 想马上得到一个能用的环境 |
| `bootstrap/scripts/container-raw.sh` | **什么都不装**，只挂工作区 → 进 bash | 想从零走一遍，每一步自己决定 |

`container-raw.sh` 的状态等价于"刚 `repo sync` 完"：连 `python3` 和 `git`
都没有。这是**故意的**——装了它们 `wtool` 就能跑，可真机器刚同步完时本来
就没有，如实反映那个状态才不会被误导。进去之后它会打一份操作对照表。

```bash
# 从头走一遍
docker run --rm -it --network=host \
  -v ~/self/wtool:/wtool:ro \
  ubuntu:20.04 bash /wtool/bootstrap/scripts/container-raw.sh

# 或者直接要一个装好的环境
docker run --rm -it --network=host \
  -v ~/self/wtool:/wtool:ro \
  ubuntu:20.04 bash /wtool/bootstrap/scripts/container-shell.sh
```

两个脚本进来时都会**自动探测宿主机的代理**（默认探 `127.0.0.1:7897`）并接上。这一步不能省：`docker run` 不会把你 shell 里的代理变量带进容器，不接的话容器里是"裸网"，所有下载都失败，而人很容易把它误判成"网络坏了"。这也是 `--network=host` 不能省的原因——只有在 host 网络下，容器里的 `127.0.0.1` 才是宿主自己。不想要自动探测就加 `-e WTOOL_NO_PROXY=1`，代理不在默认端口就加 `-e WTOOL_HOST_PROXY=http://127.0.0.1:端口`。

### 4.4 每个项目自己的 `scripts/`

项目目录下的 `scripts/` 是**这个项目专属**的动作。有没有某个文件本身
就是一种声明——有 `build.sh` 才叫"能构建"：

| 文件 | 什么时候跑 | 干什么 |
|---|---|---|
| `build.sh` | `wtool build <项目>` | 自己编，**产物写进项目的 `release/`** |
| `download.sh` | `wtool download <项目>` | 从发布页拿别人编好的包，**放到 `release/` 里完全相同的位置** |
| `install.sh` | `wtool install <项目目录>` | 把 `release/` 铺进 `~/.wtool/usr`；🚧 **不建 `$HOME` 软链、不写 rc**（那是引擎按 `wtool.xml` 干的 —— 今天项目脚本还自己建） |
| `install.sh --uninstall` | `wtool uninstall <项目目录>` | 撤销上面做的 |
| `publish.sh` | `wtool publish <项目>` | 只在"打成两个包"不够用时才需要，很少见 |
| `extract.sh` | 手动（只有浏览器、连 wtool 都还没装的机器） | 校验并解开分卷到 `release/`，**不装**（新架构里这活已经归引擎的 `wtool unpack-release`） |

**`build` 和 `download` 是二选一的两条路，结果等价。** 编一次几十分钟到
几小时，下载几分钟——能下载就下载。两条路把产物放进同一个 `release/` 目录，
所以之后的 `wtool install` 完全不关心它是编出来的还是下下来的。

**本机装这条路断网也能跑**，所以它出错时你看到的永远是"缺什么"，不会是"网断了"。
（从发布包铺开那条路目前还会装系统依赖，上面 1.6 说了。）

发布过包的项目分两种。**纯源码包**（大多数项目）解开就是仓库目录树，没有额外脚本。
**带编译产物的项目**（现在只有 Neovim 那套）Release 页面里会多带分卷和一份 `dist.json`——
那是给**只能用浏览器下载**的机器用的：把它们下到项目的 `publish/` 目录，
`wtool unpack-release <项目目录>` 校验并解开，再用 `wtool install <项目目录>` 收尾。

### 4.5 不要手改的地方

- 项目的 `wtool.xml` 可以改（那是给你声明用的），改完跑 `wtool validate <项目目录>` 看一眼
- 项目里的 `release/` 和 `publish/` 是**产物**，不要手改，也不要把文件放进 Git —— 它们在 `.gitignore` 里是有原因的
- `~/.wtool/` 下的东西不要手改，那是生成物；要改就改声明再重跑
- `~/.local/state/wtool/` 是状态记录（谁装过、谁发布过），**只由 `wtool` 写**。想清干净就用 `wtool kill-self-forever`
- 各项目 `scripts/` 下的脚本可以读、可以照着改，但别在没跑过的机器上盲改

---

以上只是速查。**完整的说明——项目结构、每个命令的细节、所有子项目的索引——在 [guide.md](guide.md)。**
