# 图放这里

README.md 和 guide.md 里有几处【图片占位】，需要人工截图后放到这个目录。
每个占位下面都有一个 `<!-- TODO: ... -->` 注释，写了该执行什么命令、截什么。

占位清单（搜 `图片占位` 可以全部找到）：

| 文件 | 文件名 | 截什么 |
|---|---|---|
| README.md | `table.png` | `wtool` 的输出（带颜色，终端 120 列以上：这张表有 11 列，能看出 不支持=红 / 可执行=黄 / 待产出=蓝 / 已完成=绿 / 未发布=紫 / 未安装=青 这六种状态的区别） |
| README.md | `install.png` | `wtool bootstrap` 的过程输出 |
| guide.md | `bootstrap.png` | `wtool bootstrap` 的输出（`--install-only` 已经删掉，bootstrap 现在就是 install-only） |

截图存成 PNG 放在本目录，然后把文档里的 `【图片占位】` 四个字删掉即可
（`![...](.pic/xxx.png)` 那部分已经写好了）。

---

## 画出来的图（不是截图）

两张，源码都是 Mermaid 文本（`.mmd`），渲染成 PNG 给不认 Mermaid 的阅读器看。
**注意**：GitHub 自己会渲染 Mermaid，但这个仓库的图**故意只用 PNG** ——
Typora 能看 PNG，harness 右边栏那个 markdown 预览器两者都不认（实测：它不带 Mermaid，
也不解析文档里的相对图片路径）。

| 图 | 用在哪 | 画什么 |
|---|---|---|
| `layers.png` | README §1.4 | 三层路径：`__output/` → `~/.wtool/` → `$HOME`，命令标在箭头上 |
| `commands.png` | README §1.3 | 每条命令与 `__output/`、`__release/` 的关系（一条闭环） |

改图就改 `.mmd`，然后：

```sh
sh .pic/render.sh                     # 渲染 .pic 下所有 .mmd
sh .pic/render.sh .pic/layers.mmd     # 或只渲染一个
```

渲染走的是 mermaid.ink 这个在线服务（原因和代价写在 `render.sh` 的注释里：
这台机器没浏览器，本地渲染要拉一个 headless Chrome）。
**图源码会发到公网**，所以只画路径说明这类东西；
真要画含主机名/内网地址/密钥路径的图，得先在本机把渲染环境搭起来。
