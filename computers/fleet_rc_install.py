#!/usr/bin/env python3
"""Normalise shell rc files to a single fleet-managed block.

Removes every hand-placed copy of fleet-owned config (claude-local, the ssh_*
aliases, LOCAL_LLM_* exports, the older fleet-prompt marker block) and appends
one identical managed block that sources the two managed files.

Idempotent: safe to run repeatedly. Backs up before writing.
"""
import os
import re
import shutil
import sys
import time

BEGIN = "# BEGIN fleet-managed"
END = "# END fleet-managed"

BLOCK = f"""{BEGIN} -- generated, do not edit by hand
# Source: myprojects/computers/  ·  regenerate, never hand-patch.
[ -f ~/.fleet-prompt.sh ]  && . ~/.fleet-prompt.sh
[ -f ~/.fleet-aliases.sh ] && . ~/.fleet-aliases.sh
{END}"""

# Single-line items fleet-aliases.sh now owns.
LINE_PATTERNS = [
    re.compile(r'^\s*alias\s+ssh_(opi|macpro|macbook|spark1|spark2)\s*=', re.M),
    re.compile(r'^\s*export\s+LOCAL_LLM_(URL|MODEL)\s*=', re.M),
]


def strip_marker_block(text, begin, end):
    """Remove a BEGIN..END block including a trailing newline."""
    pat = re.compile(
        re.escape(begin) + r'.*?' + re.escape(end) + r'[^\n]*\n?',
        re.S,
    )
    return pat.sub('', text)


def strip_function(text, name):
    """Remove `name() { ... }` by brace matching, plus its comment header."""
    while True:
        m = re.search(r'^[ \t]*' + re.escape(name) + r'\s*\(\)\s*\{', text, re.M)
        if not m:
            return text
        i, depth = m.end() - 1, 0
        while i < len(text):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    break
            i += 1
        if i >= len(text):
            return text  # unbalanced; leave it alone
        end = i + 1
        if end < len(text) and text[end] == '\n':
            end += 1
        # absorb contiguous comment lines immediately above
        start = m.start()
        lines = text[:start].split('\n')
        while len(lines) >= 2 and lines[-2].lstrip().startswith('#'):
            lines.pop(-2)
        text = '\n'.join(lines) + text[end:]


def clean(path):
    if not os.path.isfile(path):
        return None
    original = open(path, encoding='utf-8', errors='surrogateescape').read()
    text = original

    text = strip_marker_block(text, BEGIN, END)
    text = strip_marker_block(text, "# BEGIN fleet-prompt", "# END fleet-prompt")
    text = strip_function(text, "claude-local")
    text = strip_function(text, "fleet_llm_model")
    for pat in LINE_PATTERNS:
        text = pat.sub('', text)

    text = re.sub(r'\n{3,}', '\n\n', text).rstrip() + '\n'
    text += '\n' + BLOCK + '\n'

    if text == original:
        return 'unchanged'
    shutil.copy2(path, f"{path}.bak.{time.strftime('%Y%m%d-%H%M%S')}")
    open(path, 'w', encoding='utf-8', errors='surrogateescape').write(text)
    return 'updated'


results = []
for rc in ('.zshrc', '.bashrc', '.bash_profile'):
    p = os.path.expanduser('~/' + rc)
    r = clean(p)
    if r:
        results.append(f"{rc}:{r}")
print(' '.join(results) if results else 'no rc files')
