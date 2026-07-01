from __future__ import annotations

import hashlib
import html
import json
import re
from pathlib import Path

import argostranslate.translate


ROOT = Path("C:/Users/Karolina/Documents/FIXON")
SOURCE_DIR = ROOT / "dokumenty"
CACHE_DIR = ROOT / ".translation-cache"


def slug_base(doc: dict) -> str:
    return Path(doc["Slug"]).stem


def cache_key(lang: str, text: str) -> str:
    return hashlib.sha1(f"{lang}\n{text}".encode("utf-8")).hexdigest()


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(value)).strip()


def split_html(value: str) -> list[str]:
    return re.split(r"(<[^>]+>)", value)


def collect_texts_from_html(value: str) -> list[str]:
    skip = None
    texts: list[str] = []
    for part in split_html(value):
        if not part:
            continue
        if part.startswith("<"):
            lower = part.lower()
            if lower.startswith("<style"):
                skip = "style"
            if lower.startswith("<script"):
                skip = "script"
            if skip == "style" and lower.startswith("</style"):
                skip = None
            if skip == "script" and lower.startswith("</script"):
                skip = None
            continue
        if skip or not part.strip():
            continue
        text = normalize_text(part)
        if text and re.search(r"[^\W\d_]", text, flags=re.UNICODE):
            texts.append(text)
    return texts


def collect_all_texts() -> list[str]:
    manifest = json.loads((SOURCE_DIR / "manifest.json").read_text(encoding="utf-8-sig"))
    seen: dict[str, None] = {}
    for doc in manifest:
        source = (SOURCE_DIR / f"{slug_base(doc)}.html").read_text(encoding="utf-8")
        for text in collect_texts_from_html(source):
            seen.setdefault(text, None)
    return list(seen.keys())


def split_for_translation(text: str, max_len: int = 900) -> list[str]:
    text = normalize_text(text)
    if len(text) <= max_len:
        return [text]
    sentences = re.split(r"(?<=[.!?;:])\s+", text)
    chunks: list[str] = []
    current = ""

    def push_current() -> None:
        nonlocal current
        if current.strip():
            chunks.append(current.strip())
        current = ""

    for sentence in sentences:
        candidate = f"{current} {sentence}".strip()
        if len(candidate) <= max_len:
            current = candidate
            continue
        push_current()
        if len(sentence) <= max_len:
            current = sentence
            continue
        for word in sentence.split():
            candidate = f"{current} {word}".strip()
            if len(candidate) > max_len:
                push_current()
            current = f"{current} {word}".strip()
    push_current()
    return chunks or [text]


def post_process(text: str, lang: str) -> str:
    out = re.sub(r"\bFixon\b", "FIXON", text or "")
    out = re.sub(r"\bTools\s*&\s*Tech\b", "Tools & Tech", out)
    if lang == "en":
        out = out.replace("Partner Program", "Partner Programme")
        out = out.replace("Program Partner FIXON", "FIXON Partner Programme")
    if lang == "de":
        out = out.replace("Partnerprogramm FIXON", "FIXON Partnerprogramm")
    return normalize_text(out)


def translate_chunked(text: str, source: str, target: str) -> str:
    translated = []
    for chunk in split_for_translation(text):
        translated.append(argostranslate.translate.translate(chunk, source, target))
    return normalize_text(" ".join(translated))


def build_cache(texts: list[str], lang: str, overwrite: bool = True) -> dict[str, str]:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = CACHE_DIR / f"{lang}.json"
    if path.exists():
        cache = json.loads(path.read_text(encoding="utf-8"))
    else:
        cache = {}

    total = len(texts)
    if lang == "en":
        for index, text in enumerate(texts, 1):
            key = cache_key("en", text)
            if overwrite or key not in cache:
                cache[key] = post_process(translate_chunked(text, "pl", "en"), "en")
            if index % 100 == 0:
                path.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
                print(f"en: cached {index}/{total}", flush=True)
        path.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
        return cache

    en_cache = build_cache(texts, "en", overwrite=False)
    for index, text in enumerate(texts, 1):
        key = cache_key("de", text)
        if overwrite or key not in cache:
            english = en_cache[cache_key("en", text)]
            cache[key] = post_process(translate_chunked(english, "en", "de"), "de")
        if index % 100 == 0:
            path.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"de: cached {index}/{total}", flush=True)
    path.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
    return cache


def main() -> None:
    texts = collect_all_texts()
    print(f"Collected {len(texts)} unique text blocks", flush=True)
    build_cache(texts, "en", overwrite=True)
    build_cache(texts, "de", overwrite=True)
    print("done", flush=True)


if __name__ == "__main__":
    main()
