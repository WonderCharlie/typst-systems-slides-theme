#!/usr/bin/env python3
"""Exercise Tinymist hover and signature help against the stable package API."""

from __future__ import annotations

import argparse
import json
import os
import queue
import re
import shutil
import subprocess
import sys
import threading
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
TIMEOUT_SECONDS = 30


@dataclass(frozen=True)
class Case:
    label: str
    binding: str
    symbol: str
    active_parameter: str | None


CASES = (
    Case("flat theme", "_doc-theme", "systems-slides-theme", "title"),
    Case("flat slide", "_doc-slide", "slide", "counted"),
    Case("flat title-slide", "_doc-title-slide", "title-slide", "subtitle"),
    Case("flat outline-slide", "_doc-outline", "outline-slide", "auto-layout"),
    Case("flat section-slide", "_doc-section", "section-slide", "numbered"),
    Case("flat page-mark", "_doc-mark", "page-mark", "slot"),
    Case("flat page-layer", "_doc-layer", "page-layer", "area"),
    Case("flat row-split", "_doc-row-split", "row-split", "rows"),
    Case("flat column-split", "_doc-column-split", "column-split", "columns"),
    Case("flat layout-profile", "_doc-profile", "layout-profile", "gutter"),
    Case("flat region", "_doc-region", "region", "overflow"),
    Case("flat body-flow", "_doc-flow", "body-flow", "outer-gutter"),
    Case("flat point", "_doc-point", "point", "level"),
    Case("flat points", "_doc-points", "points", "gap"),
    Case("flat page-frame", "_doc-frame", "page-frame", "chrome"),
    Case("flat panel", "_doc-panel", "panel", "tone"),
    Case("flat callout", "_doc-callout", "callout", "fill-tone"),
    Case("flat lead", "_doc-lead", "lead", "compact"),
    Case("typography namespace", "_doc-danger", "danger", "body"),
    Case("runtime speaker-note", "_doc-note", "speaker-note", "mode"),
    Case("runtime jump", "_doc-jump", "jump", "relative"),
    Case("runtime uncover", "_doc-uncover", "uncover", "cover-fn"),
    Case("runtime only", "_doc-only", "only", "only-cont"),
    Case("runtime alternatives", "_doc-alternatives", "alternatives", "repeat-last"),
    Case("runtime namespace", "_doc-presenter", "presenter-view", "side"),
    Case("runtime pause value", "_doc-pause", "pause", None),
    Case("runtime meanwhile value", "_doc-meanwhile", "meanwhile", None),
)

def make_source(import_ref: str) -> str:
    return f"""#import "{import_ref}": (
  body-flow,
  callout,
  column-split,
  layout-profile,
  lead,
  outline-slide,
  page-frame,
  page-layer,
  page-mark,
  panel,
  point,
  points,
  region,
  row-split,
  runtime,
  section-slide,
  slide,
  systems-slides-theme,
  title-slide,
  typography,
)

#let _doc-theme = systems-slides-theme(title: [Tinymist])[]
#let _doc-slide = slide(title: [Tinymist], counted: true)[]
#let _doc-title-slide = title-slide(subtitle: [Tinymist])
#let _doc-outline = outline-slide(
  spacing: 20pt,
  top-spacing: 12pt,
  bottom-spacing: 18pt,
  auto-layout: true,
)
#let _doc-section = section-slide(numbered: false, body: none)
#let _doc-mark = page-mark([Artifact], slot: "header-end")
#let _doc-layer = page-layer([Layer], area: "page")
#let _doc-row-split = row-split(([], []), rows: (auto, 1fr), height: 100pt)
#let _doc-column-split = column-split(([], []), columns: (1fr, 1fr), width: 100pt)
#let _doc-profile = layout-profile(gutter: 12pt)
#let _doc-region = region([], overflow: "visible")
#let _doc-flow = body-flow((region([]),), gutter: 1fr, outer-gutter: 2fr)
#let _doc-point = point([First], level: 1)
#let _doc-points = points((point([First]),), gap: 2pt)
#let _doc-frame = page-frame(name: "Tinymist", chrome: true)
#let _doc-panel = panel([Worker], tone: white)
#let _doc-callout = callout([Warning], fill-tone: white)
#let _doc-lead = lead([Summary], compact: false)
#let _doc-danger = typography.danger(body: [Danger])
#let _doc-note = runtime.speaker-note(mode: "typ")[Note]
#let _doc-jump = runtime.jump(2, relative: false)
#let _doc-uncover = runtime.uncover("2-", cover-fn: auto)[Later]
#let _doc-only = runtime.only("2-", only-cont: [Only])
#let _doc-alternatives = runtime.alternatives(repeat-last: true)[A][B]
#let _doc-presenter = runtime.presenter-view(side: right)
#let _doc-pause = runtime.pause
#let _doc-meanwhile = runtime.meanwhile
"""


def local_package_ref() -> str:
    manifest = tomllib.loads((ROOT / "typst.toml").read_text(encoding="utf-8"))
    package = manifest["package"]
    return f"@local/{package['name']}:{package['version']}"


def executable_from(value: str) -> Path | None:
    candidate = Path(value).expanduser()
    if candidate.is_file():
        return candidate.resolve()
    located = shutil.which(value)
    return Path(located).resolve() if located else None


def find_tinymist() -> Path:
    configured = os.environ.get("TINYMIST")
    if configured:
        result = executable_from(configured)
        if result is None:
            raise RuntimeError(
                f"TINYMIST={configured!r} 不是可执行文件，且无法从 PATH 解析"
            )
        return result

    on_path = shutil.which("tinymist")
    if on_path:
        return Path(on_path).resolve()

    patterns = (
        ".vscode/extensions/myriad-dreamin.tinymist-*/out/tinymist",
        ".vscode-insiders/extensions/myriad-dreamin.tinymist-*/out/tinymist",
        ".cursor/extensions/myriad-dreamin.tinymist-*/out/tinymist",
    )
    candidates: list[Path] = []
    for pattern in patterns:
        candidates.extend(path for path in Path.home().glob(pattern) if path.is_file())
    if candidates:
        return max(candidates, key=lambda path: path.stat().st_mtime).resolve()

    raise RuntimeError(
        "找不到 Tinymist：请安装 VS Code Tinymist 扩展、将 tinymist 放入 PATH，"
        "或以 TINYMIST=/absolute/path/to/tinymist 运行本测试"
    )


def markup_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "\n".join(markup_text(item) for item in value)
    if isinstance(value, dict):
        if "value" in value:
            return str(value["value"])
        if "language" in value and "value" in value:
            return str(value["value"])
    return str(value)


def contains_chinese(value: str) -> bool:
    return any("\u3400" <= char <= "\u9fff" for char in value)


class LspClient:
    def __init__(self, binary: Path) -> None:
        self.binary = binary
        self.process = subprocess.Popen(
            [str(binary), "lsp"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if self.process.stdin is None or self.process.stdout is None or self.process.stderr is None:
            raise RuntimeError("无法建立 Tinymist LSP 管道")
        self.messages: queue.Queue[dict[str, Any]] = queue.Queue()
        self.stderr_lines: list[str] = []
        self.next_id = 1
        self.write_lock = threading.Lock()
        self.reader = threading.Thread(target=self._read_messages, daemon=True)
        self.stderr_reader = threading.Thread(target=self._read_stderr, daemon=True)
        self.reader.start()
        self.stderr_reader.start()

    def _read_messages(self) -> None:
        assert self.process.stdout is not None
        while True:
            headers: dict[str, str] = {}
            while True:
                line = self.process.stdout.readline()
                if not line:
                    return
                if line in (b"\r\n", b"\n"):
                    break
                decoded = line.decode("ascii", errors="replace").strip()
                if ":" in decoded:
                    key, value = decoded.split(":", 1)
                    headers[key.lower()] = value.strip()
            length_text = headers.get("content-length")
            if length_text is None:
                continue
            payload = self.process.stdout.read(int(length_text))
            if not payload:
                return
            try:
                self.messages.put(json.loads(payload.decode("utf-8")))
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                self.messages.put({"_protocol_error": str(error)})

    def _read_stderr(self) -> None:
        assert self.process.stderr is not None
        for line in iter(self.process.stderr.readline, b""):
            self.stderr_lines.append(line.decode("utf-8", errors="replace").rstrip())

    def send(self, message: dict[str, Any]) -> None:
        assert self.process.stdin is not None
        payload = json.dumps(message, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        packet = f"Content-Length: {len(payload)}\r\n\r\n".encode("ascii") + payload
        with self.write_lock:
            self.process.stdin.write(packet)
            self.process.stdin.flush()

    def notify(self, method: str, params: dict[str, Any] | None = None) -> None:
        message: dict[str, Any] = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            message["params"] = params
        self.send(message)

    def _reply_to_server_request(self, message: dict[str, Any]) -> None:
        method = message.get("method")
        params = message.get("params") or {}
        if method == "workspace/configuration":
            result: Any = [{} for _ in params.get("items", [])]
        elif method == "workspace/workspaceFolders":
            result = [{"uri": ROOT.as_uri(), "name": ROOT.name}]
        elif method == "workspace/applyEdit":
            result = {"applied": False}
        else:
            result = None
        self.send({"jsonrpc": "2.0", "id": message["id"], "result": result})

    def request(self, method: str, params: dict[str, Any]) -> Any:
        request_id = self.next_id
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": request_id, "method": method, "params": params})
        while True:
            try:
                message = self.messages.get(timeout=TIMEOUT_SECONDS)
            except queue.Empty as error:
                stderr = "\n".join(self.stderr_lines[-20:])
                raise RuntimeError(
                    f"等待 Tinymist 响应 {method} 超时"
                    + (f"\nTinymist stderr:\n{stderr}" if stderr else "")
                ) from error
            if "_protocol_error" in message:
                raise RuntimeError(f"Tinymist LSP 协议错误：{message['_protocol_error']}")
            if "method" in message and "id" in message:
                self._reply_to_server_request(message)
                continue
            if message.get("id") != request_id:
                continue
            if "error" in message:
                raise RuntimeError(f"Tinymist {method} 返回错误：{message['error']}")
            return message.get("result")

    def close(self) -> None:
        if self.process.poll() is not None:
            return
        try:
            self.request("shutdown", {})
            self.notify("exit")
            self.process.wait(timeout=5)
        except Exception:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()


def line_position(
    source: str,
    binding: str,
    needle: str,
    *,
    after: bool = False,
) -> dict[str, int]:
    lines = source.splitlines()
    for line_number, line in enumerate(lines):
        if binding not in line:
            continue
        column = line.index(needle)
        if after:
            column += len(needle)
        return {"line": line_number, "character": column}
    raise RuntimeError(f"测试源码中找不到 {binding}/{needle}")


def parameter_label(parameter: dict[str, Any], signature_label: str) -> str:
    label = parameter.get("label", "")
    if isinstance(label, str):
        return label
    if isinstance(label, list) and len(label) == 2:
        return signature_label[int(label[0]) : int(label[1])]
    return str(label)


def validate_case(client: LspClient, uri: str, source: str, case: Case) -> list[str]:
    errors: list[str] = []
    # Search the callable token, not the local fixture binding.  Several
    # bindings intentionally repeat the function name (for example
    # `_doc-slide`), and hovering that value would only show sampled output.
    callable_token = (
        f"{case.symbol}("
        if case.active_parameter is not None
        else f"runtime.{case.symbol}"
    )
    hover_position = line_position(source, case.binding, callable_token)
    hover_position["character"] += (
        len("runtime.") + 1 if case.active_parameter is None else 1
    )

    hover = client.request(
        "textDocument/hover",
        {"textDocument": {"uri": uri}, "position": hover_position},
    )
    hover_text = markup_text((hover or {}).get("contents"))
    if os.environ.get("TINYMIST_DOC_DEBUG"):
        print(f"[{case.label}] hover:\n{hover_text}\n", file=sys.stderr)
    if not hover_text:
        errors.append(f"{case.label}: hover 为空")
    else:
        if case.symbol not in hover_text:
            errors.append(f"{case.label}: hover 未显示函数名 {case.symbol}")
        if not contains_chinese(hover_text):
            errors.append(f"{case.label}: hover 未显示中文职责/参数说明")
        if case.active_parameter is not None and case.active_parameter not in hover_text:
            errors.append(f"{case.label}: hover 未包含参数 {case.active_parameter}")
        if case.active_parameter is not None and "默认" not in hover_text and "必填" not in hover_text:
            errors.append(f"{case.label}: hover 未包含默认值或必填信息")

    if case.active_parameter is None:
        return errors

    signature_position = line_position(
        source, case.binding, f"{case.active_parameter}:", after=True
    )

    signature_help = client.request(
        "textDocument/signatureHelp",
        {
            "textDocument": {"uri": uri},
            "position": signature_position,
            "context": {"triggerKind": 1, "isRetrigger": False},
        },
    )
    signatures = (signature_help or {}).get("signatures") or []
    if not signatures:
        errors.append(f"{case.label}: signatureHelp 为空")
        return errors

    active_signature = int((signature_help or {}).get("activeSignature") or 0)
    signature = signatures[min(active_signature, len(signatures) - 1)]
    signature_label = str(signature.get("label", ""))
    if os.environ.get("TINYMIST_DOC_DEBUG"):
        print(
            f"[{case.label}] signature:\n{json.dumps(signature, ensure_ascii=False, indent=2)}\n",
            file=sys.stderr,
        )
    if case.symbol not in signature_label:
        errors.append(f"{case.label}: signatureHelp 标签未包含 {case.symbol}: {signature_label!r}")

    parameters = signature.get("parameters") or []
    matching_parameter = False
    for parameter in parameters:
        label = parameter_label(parameter, signature_label)
        documentation = markup_text(parameter.get("documentation"))
        if case.active_parameter in label:
            matching_parameter = True
        if not documentation:
            errors.append(f"{case.label}: 参数 {label!r} 缺少 signatureHelp 文档")
        elif not contains_chinese(documentation):
            errors.append(f"{case.label}: 参数 {label!r} 的 signatureHelp 文档不是中文")
    if not matching_parameter:
        errors.append(
            f"{case.label}: signatureHelp 未返回关键参数 {case.active_parameter}；"
            f"实际 {[parameter_label(item, signature_label) for item in parameters]}"
        )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--installed",
        action="store_true",
        help="通过 typst.toml 中的 @local 包引用验证真实系统安装，而不是当前源码",
    )
    args = parser.parse_args()
    import_ref = local_package_ref() if args.installed else "../lib.typ"
    source = make_source(import_ref)
    mode = f"installed {import_ref}" if args.installed else "source ../lib.typ"

    try:
        binary = find_tinymist()
    except RuntimeError as error:
        print(f"Tinymist LSP 文档检查失败：{error}", file=sys.stderr)
        return 2

    try:
        version_output = subprocess.run(
            [str(binary), "--version"],
            check=True,
            capture_output=True,
            text=True,
            timeout=5,
        ).stdout.strip()
        described = re.search(r"Build Git Describe:\s*(\S+)", version_output)
        version = f"tinymist {described.group(1)}" if described else version_output.splitlines()[0]
    except (OSError, subprocess.SubprocessError) as error:
        print(f"Tinymist LSP 文档检查失败：无法执行 {binary}: {error}", file=sys.stderr)
        return 2

    client = LspClient(binary)
    uri = (ROOT / "tests/.tinymist-doc-contract.typ").as_uri()
    try:
        client.request(
            "initialize",
            {
                "processId": os.getpid(),
                "clientInfo": {"name": "systems-slides-template-doc-test", "version": "1"},
                "rootPath": str(ROOT),
                "rootUri": ROOT.as_uri(),
                "workspaceFolders": [{"uri": ROOT.as_uri(), "name": ROOT.name}],
                "capabilities": {
                    "workspace": {"configuration": True, "workspaceFolders": True},
                    "textDocument": {
                        "hover": {"contentFormat": ["markdown", "plaintext"]},
                        "signatureHelp": {
                            "signatureInformation": {
                                "documentationFormat": ["markdown", "plaintext"],
                                "parameterInformation": {"labelOffsetSupport": True},
                            }
                        },
                    },
                },
            },
        )
        client.notify("initialized", {})
        client.notify(
            "textDocument/didOpen",
            {
                "textDocument": {
                    "uri": uri,
                    "languageId": "typst",
                    "version": 1,
                    "text": source,
                }
            },
        )

        errors: list[str] = []
        for case in CASES:
            errors.extend(validate_case(client, uri, source, case))

        client.notify("textDocument/didClose", {"textDocument": {"uri": uri}})
        if errors:
            print(
                f"Tinymist LSP 文档检查失败（{version}，{mode}，{binary}）：",
                file=sys.stderr,
            )
            for error in errors:
                print(f"- {error}", file=sys.stderr)
            return 1

        print(
            f"Tinymist LSP 文档检查通过：{version}，"
            f"{mode}，{len(CASES)} 个 flat/namespace 接口均返回中文 hover 与参数提示。"
        )
        return 0
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(
            f"Tinymist LSP 文档检查失败（{version}，{mode}，{binary}）：{error}",
            file=sys.stderr,
        )
        return 1
    finally:
        client.close()


if __name__ == "__main__":
    raise SystemExit(main())
