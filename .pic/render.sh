#!/bin/sh
# 把 .pic/*.mmd 渲染成 .pic/*.png。
#
# 为什么用在线服务：这台机器没装浏览器，mermaid 的官方 CLI（mmdc）要拉一个
# headless Chrome 才能跑。mermaid.ink 只吃 base64 过的图源码，回一张 PNG，
# 不需要本地依赖。代价是**图源码会发到公网**——这里的图都是路径说明，
# 没有敏感信息；将来要画含内部信息（主机名、内网地址、密钥路径）的图，
# 就得换成本地渲染。
#
# 用法：
#   sh .pic/render.sh              # 渲染 .pic/layers.mmd
#   sh .pic/render.sh foo.mmd      # 渲染指定的那个
#
# 代理：这台机器上出网要过 http://127.0.0.1:7897（没设就直连）。
set -eu

_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
_src=${1:-$_dir/layers.mmd}
_out=${_src%.mmd}.png

python3 - "$_src" "$_out" <<'PY'
import base64, json, os, subprocess, sys

src, out = sys.argv[1], sys.argv[2]
code = open(src, encoding='utf-8').read()
payload = base64.urlsafe_b64encode(
    json.dumps({"code": code, "mermaid": {"theme": "default"}}).encode()
).decode()
url = "https://mermaid.ink/img/%s?type=png&bgColor=FFFFFF" % payload

cmd = ["curl", "-sS", "--max-time", "60", "-o", out, "-w", "%{http_code}"]
proxy = os.environ.get("https_proxy") or os.environ.get("HTTPS_PROXY")
if proxy:
    cmd += ["-x", proxy]
cmd.append(url)

code_ = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
if code_ != "200" or not os.path.getsize(out):
    sys.exit("渲染失败：HTTP %s" % code_)
print("%s -> %s（%d 字节）" % (src, out, os.path.getsize(out)))
PY
