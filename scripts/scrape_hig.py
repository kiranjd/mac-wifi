#!/usr/bin/env python3
"""Scrape Apple HIG docs and organize output by guideline hierarchy.

Usage:
  python3 scripts/scrape_hig.py --clean
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Any

import scrapy
from scrapy.crawler import CrawlerProcess

BASE_URL = "https://developer.apple.com"
INDEX_PATH = "/tutorials/data/index/design--human-interface-guidelines.json"


def inline_to_text(nodes: Any) -> str:
    if not isinstance(nodes, list):
        return ""
    out: list[str] = []
    for node in nodes:
        if not isinstance(node, dict):
            continue
        node_type = node.get("type")
        if node_type == "text":
            out.append(str(node.get("text", "")))
        elif node_type == "codeVoice":
            out.append(f"`{node.get('code', '')}`")
        elif node_type in {"emphasis", "strong", "superscript", "subscript", "newTerm"}:
            out.append(inline_to_text(node.get("inlineContent", [])))
        elif node_type == "reference":
            title = node.get("overridingTitle") or node.get("identifier", "")
            out.append(str(title))
        elif node_type == "link":
            title = node.get("title") or node.get("destination", "")
            out.append(str(title))
        else:
            nested = node.get("inlineContent")
            if isinstance(nested, list):
                out.append(inline_to_text(nested))
    return "".join(out).strip()


def render_blocks(blocks: Any, heading_level: int = 3) -> list[str]:
    lines: list[str] = []
    if not isinstance(blocks, list):
        return lines

    for block in blocks:
        if not isinstance(block, dict):
            continue
        block_type = block.get("type")

        if block_type == "heading":
            level = block.get("level")
            if not isinstance(level, int):
                level = 1
            title = block.get("text") or ""
            lines.append(f"{'#' * max(heading_level, min(6, heading_level + level - 1))} {title}")
            lines.append("")
        elif block_type == "paragraph":
            text = inline_to_text(block.get("inlineContent", []))
            if text:
                lines.append(text)
                lines.append("")
        elif block_type == "unorderedList":
            for item in block.get("items", []):
                content = render_blocks(item.get("content", []), heading_level=heading_level)
                text = " ".join(line.strip() for line in content if line.strip())
                if text:
                    lines.append(f"- {text}")
            lines.append("")
        elif block_type == "orderedList":
            counter = int(block.get("start", 1))
            for item in block.get("items", []):
                content = render_blocks(item.get("content", []), heading_level=heading_level)
                text = " ".join(line.strip() for line in content if line.strip())
                if text:
                    lines.append(f"{counter}. {text}")
                    counter += 1
            lines.append("")
        elif block_type == "aside":
            kind = block.get("style") or "note"
            lines.append(f"> **{kind.title()}**")
            aside_lines = render_blocks(block.get("content", []), heading_level=heading_level)
            for line in aside_lines:
                if line:
                    lines.append(f"> {line}")
            lines.append("")
        elif block_type == "codeListing":
            syntax = block.get("syntax") or ""
            lines.append(f"```{syntax}")
            lines.append(str(block.get("code", "")))
            lines.append("```")
            lines.append("")
        else:
            nested = block.get("content")
            if isinstance(nested, list):
                lines.extend(render_blocks(nested, heading_level=heading_level))

    return lines


def node_page_path(node_path: str) -> str:
    return f"pages/{node_path.strip('/')}/index.md"


class HIGSpider(scrapy.Spider):
    name = "hig_spider"

    custom_settings = {
        "ROBOTSTXT_OBEY": True,
        "LOG_LEVEL": "INFO",
        "CONCURRENT_REQUESTS": 8,
        "DOWNLOAD_DELAY": 0.05,
        "RETRY_TIMES": 2,
    }

    def __init__(
        self,
        output_root: str,
        language: str = "swift",
        max_pages: int | None = None,
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)
        self.output_root = Path(output_root)
        self.pages_root = self.output_root / "pages"
        self.language = language
        self.max_pages = max_pages
        self.paths_seen: set[str] = set()
        self.page_count = 0
        self.index_data: dict[str, Any] = {}
        self.tree: list[dict[str, Any]] = []

    async def start(self) -> Any:
        yield scrapy.Request(f"{BASE_URL}{INDEX_PATH}", callback=self.parse_index)

    def parse_index(self, response: scrapy.http.Response) -> Any:
        self.output_root.mkdir(parents=True, exist_ok=True)
        self.pages_root.mkdir(parents=True, exist_ok=True)

        self.index_data = json.loads(response.text)

        tree = self.index_data.get("interfaceLanguages", {}).get(self.language)
        if not isinstance(tree, list):
            raise RuntimeError(f"Language '{self.language}' not found in index")
        self.tree = tree

        yield from self.enqueue_nodes(response, tree, breadcrumbs=[])

    def enqueue_nodes(
        self,
        response: scrapy.http.Response,
        nodes: list[dict[str, Any]],
        breadcrumbs: list[str],
    ) -> Any:
        for node in nodes:
            path = node.get("path")
            title = node.get("title")
            node_type = node.get("type")
            if isinstance(path, str) and path.startswith("/design/human-interface-guidelines"):
                if path not in self.paths_seen:
                    self.paths_seen.add(path)
                    if self.max_pages is None or len(self.paths_seen) <= self.max_pages:
                        endpoint = f"/tutorials/data{path}.json"
                        yield response.follow(
                            endpoint,
                            callback=self.parse_page,
                            cb_kwargs={
                                "path": path,
                                "title": title,
                                "node_type": node_type,
                                "breadcrumbs": breadcrumbs[:],
                            },
                        )

            children = node.get("children")
            next_crumbs = breadcrumbs[:] + ([str(title)] if title else [])
            if isinstance(children, list):
                yield from self.enqueue_nodes(response, children, next_crumbs)

    def parse_page(
        self,
        response: scrapy.http.Response,
        path: str,
        title: str | None,
        node_type: str | None,
        breadcrumbs: list[str],
    ) -> Any:
        data = json.loads(response.text)
        page_dir = self.pages_root / path.strip("/")
        page_dir.mkdir(parents=True, exist_ok=True)

        metadata = data.get("metadata", {})
        md_title = metadata.get("title") or title or path.split("/")[-1]

        lines: list[str] = []
        lines.append(f"# {md_title}")
        lines.append("")
        lines.append(f"- Path: `{path}`")
        lines.append(f"- Type: `{node_type or data.get('kind', 'unknown')}`")
        if breadcrumbs:
            lines.append(f"- Breadcrumbs: {' > '.join(breadcrumbs)}")
        lines.append("")

        abstract = data.get("abstract")
        if isinstance(abstract, list) and abstract:
            lines.append("## Summary")
            lines.append("")
            lines.extend(render_blocks([{"type": "paragraph", "inlineContent": abstract}], heading_level=3))

        for section_key in (
            "primaryContentSections",
            "sections",
            "topicSections",
            "relationshipsSections",
            "seeAlsoSections",
            "defaultImplementationsSections",
        ):
            sections = data.get(section_key)
            if not isinstance(sections, list) or not sections:
                continue
            lines.append(f"## {section_key}")
            lines.append("")
            for idx, section in enumerate(sections, start=1):
                if not isinstance(section, dict):
                    continue
                section_title = section.get("title") or section.get("kind") or f"Section {idx}"
                lines.append(f"### {section_title}")
                lines.append("")

                content = section.get("content")
                if isinstance(content, list):
                    lines.extend(render_blocks(content, heading_level=4))

                identifiers = section.get("identifiers")
                if isinstance(identifiers, list) and identifiers:
                    lines.append("Referenced identifiers:")
                    for ident in identifiers:
                        lines.append(f"- `{ident}`")
                    lines.append("")

        if lines and lines[-1] != "":
            lines.append("")

        (page_dir / "index.md").write_text("\n".join(lines), encoding="utf-8")
        self.page_count += 1

    def closed(self, reason: str) -> None:
        toc_lines: list[str] = []
        toc_lines.append("# Apple HIG TOC")
        toc_lines.append("")
        toc_lines.append("Generated from Apple Developer HIG index.")
        toc_lines.append("")

        def walk(nodes: list[dict[str, Any]], depth: int = 0) -> None:
            for node in nodes:
                title = node.get("title") or "Untitled"
                path = node.get("path")
                if isinstance(path, str) and path.startswith("/design/human-interface-guidelines"):
                    indent = "  " * depth
                    toc_lines.append(f"{indent}- [{title}]({node_page_path(path)})")
                children = node.get("children")
                if isinstance(children, list) and children:
                    walk(children, depth + 1)

        walk(self.tree, depth=0)
        toc_lines.append("")
        toc_lines.append(f"Total pages discovered: {len(self.paths_seen)}")
        toc_lines.append(f"Total pages fetched: {self.page_count}")
        toc_lines.append("")

        (self.output_root / "TOC.md").write_text("\n".join(toc_lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Scrape Apple HIG docs with Scrapy.")
    parser.add_argument("--output", default="docs/hig", help="Output directory.")
    parser.add_argument("--language", default="swift", help="Index language key (default: swift).")
    parser.add_argument("--max-pages", type=int, default=None, help="Optional page fetch limit.")
    parser.add_argument(
        "--clean",
        action="store_true",
        help="Delete output directory before scraping.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    out = Path(args.output)
    if args.clean and out.exists():
        shutil.rmtree(out)

    process = CrawlerProcess()
    process.crawl(
        HIGSpider,
        output_root=str(out),
        language=args.language,
        max_pages=args.max_pages,
    )
    process.start()


if __name__ == "__main__":
    main()
