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
#   sh .pic/render.sh              # 渲染 .pic 下所有 .mmd
#   sh .pic/render.sh .pic/x.mmd   # 只渲染指定的那个
#
# 代理：这台机器上出网要过 http://127.0.0.1:7897（没设就直连）。
set -eu

_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

render_one() {
    _src=$1
    _out=${_src%.mmd}.png
    python3 - "$_src" "$_out" <<'PY'
import base64, json, os, subprocess, sys

src, out = sys.argv[1], sys.argv[2]
with open(src, encoding='utf-8') as fh:
    code = fh.read()
payload = base64.urlsafe_b64encode(
    json.dumps({"code": code, "mermaid": {"theme": "default"}}).encode()
).decode()
url = "https://mermaid.ink/img/%s?type=png&bgColor=FFFFFF" % payload

cmd = ["curl", "-sS", "--max-time", "60", "-o", out, "-w", "%{http_code}"]
proxy = os.environ.get("https_proxy") or os.environ.get("HTTPS_PROXY")
if proxy:
    cmd += ["-x", proxy]
cmd.append(url)

# mermaid.ink 会偶发连不上（HTTP 000），重试几次再放弃
code_ = "000"
for _ in range(4):
    code_ = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
    if code_ == "200" and os.path.getsize(out):
        break
if code_ != "200" or not os.path.getsize(out):
    sys.exit("渲染失败：%s（HTTP %s）" % (src, code_))
print("%s -> %s（%d 字节）" % (src, out, os.path.getsize(out)))
PY
}

if [ $# -ge 1 ]; then
    render_one "$1"
else
    for _f in "$_dir"/*.mmd; do
        [ -e "$_f" ] || continue
        render_one "$_f"
    done
fi
