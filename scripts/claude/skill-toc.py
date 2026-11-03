#!/usr/bin/env python3
import re
import sys
from pathlib import Path

THRESHOLD = 100
TOC_HEADING = "## Contents"
FENCE = re.compile(r"^\s*(```|~~~)")
HEADING = re.compile(r"^(#{1,3}) +(.+?)(?: +#+)? *$")


def strip_toc(lines):
    if TOC_HEADING not in lines:
        return lines
    start = lines.index(TOC_HEADING)
    end = start + 1
    while end < len(lines) and (lines[end] == "" or lines[end].lstrip().startswith("- [")):
        end += 1
    return lines[:start] + lines[end:]


def headings(lines):
    in_fence = False
    for index, line in enumerate(lines):
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        match = HEADING.match(line)
        if match:
            yield index, len(match.group(1)), match.group(2)


def slug(title, seen):
    text = re.sub(r"[^\w\- ]", "", title.replace("`", "").lower()).replace(" ", "-")
    count = seen.get(text, 0)
    seen[text] = count + 1
    return text if count == 0 else f"{text}-{count}"


def build(lines):
    seen = {}
    entries = []
    first_section = None
    for index, level, title in headings(lines):
        if level == 1:
            continue
        if first_section is None:
            first_section = index
        entries.append(f"{'  ' * (level - 2)}- [{title}](#{slug(title, seen)})")
    return first_section, entries


def render(path):
    original = path.read_text()
    lines = original.split("\n")
    had_toc = TOC_HEADING in lines
    body = strip_toc(lines)
    if not had_toc and len(body) - 1 <= THRESHOLD:
        return original
    first_section, entries = build(body)
    if first_section is None:
        return original
    block = [TOC_HEADING, "", *entries, ""]
    return "\n".join(body[:first_section] + block + body[first_section:])


def main(paths):
    changed = []
    for name in paths:
        path = Path(name)
        updated = render(path)
        if updated != path.read_text():
            path.write_text(updated)
            changed.append(name)
    for name in changed:
        print(f"skill-toc: rewrote Contents in {name}")
    return 1 if changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
