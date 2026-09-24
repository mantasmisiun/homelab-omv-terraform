#!/usr/bin/env python3
"""Paperless post-consume hook: send only text-less documents to paperless-gpt for LLM OCR.

Paperless runs this after every consumed document. It looks at the ORIGINAL upload:
  - PDF with an extractable text layer  -> do nothing; Paperless already has the text.
  - PDF without one (a scan), or an image -> add the tag that paperless-gpt watches,
    so the document gets LLM OCR on the desktop GPU.

Environment (set on the paperless container):
  PAPERLESS_URL             public URL; its host is sent as Host header (ALLOWED_HOSTS)
  AUTO_OCR_API_TOKEN        Paperless API token used to add the tag
  AUTO_OCR_TAG              optional, default paperless-gpt-ocr-auto
  AUTO_OCR_MIN_CHARS_PAGE   optional, default 30 visible characters per page
Paperless provides DOCUMENT_ID and DOCUMENT_SOURCE_PATH to the script.
"""
import json
import os
import subprocess
import sys
import urllib.parse
import urllib.request

TAG = os.environ.get("AUTO_OCR_TAG", "paperless-gpt-ocr-auto")
MIN_CHARS_PER_PAGE = int(os.environ.get("AUTO_OCR_MIN_CHARS_PAGE", "30"))
API = "http://localhost:8000/api"
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".tif", ".tiff", ".webp", ".heic", ".bmp", ".gif"}


def log(msg):
    print(f"[auto-ocr] {msg}", flush=True)


def page_count(path):
    try:
        out = subprocess.run(["pdfinfo", path], capture_output=True, text=True, timeout=60).stdout
        for line in out.splitlines():
            if line.startswith("Pages:"):
                return max(1, int(line.split()[1]))
    except Exception:
        pass
    return 1


def text_chars(path):
    out = subprocess.run(["pdftotext", "-q", path, "-"], capture_output=True, text=True, timeout=300).stdout
    return sum(1 for c in out if not c.isspace())


def needs_llm_ocr(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in IMAGE_EXT:
        return True, "image, no text layer"
    if ext != ".pdf":
        return False, f"{ext} is not a PDF or image"
    pages, chars = page_count(path), text_chars(path)
    per_page = chars / pages
    verdict = per_page < MIN_CHARS_PER_PAGE
    return verdict, f"{chars} text chars over {pages} pages ({per_page:.0f}/page)"


def request(method, path, body=None):
    token = os.environ["AUTO_OCR_API_TOKEN"]
    host = urllib.parse.urlparse(os.environ.get("PAPERLESS_URL", "http://localhost")).hostname
    req = urllib.request.Request(
        f"{API}{path}", method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Token {token}", "Content-Type": "application/json",
                 "Accept": "application/json", "Host": host or "localhost"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r) if r.length != 0 else {}


def tag_id():
    found = request("GET", "/tags/?name__iexact=" + urllib.parse.quote(TAG))
    if found.get("results"):
        return found["results"][0]["id"]
    return request("POST", "/tags/", {"name": TAG, "matching_algorithm": 0})["id"]


def main():
    doc_id = os.environ.get("DOCUMENT_ID")
    source = os.environ.get("DOCUMENT_SOURCE_PATH")
    if not doc_id or not source:
        log("missing DOCUMENT_ID or DOCUMENT_SOURCE_PATH, nothing to do")
        return
    verdict, why = needs_llm_ocr(source)
    if not verdict:
        log(f"document {doc_id}: has text ({why}), leaving it to Paperless")
        return
    request("POST", "/documents/bulk_edit/",
            {"documents": [int(doc_id)], "method": "add_tag", "parameters": {"tag": tag_id()}})
    log(f"document {doc_id}: no usable text ({why}), tagged {TAG} for LLM OCR")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never fail the consume because of this hook
        log(f"error: {e}")
    sys.exit(0)
