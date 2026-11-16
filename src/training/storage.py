"""Copy files between the local filesystem and S3 using URIs (s3://bucket/key or a path)."""

from __future__ import annotations

import hashlib
import shutil
from pathlib import Path
from urllib.parse import urlparse


def _split_s3(uri: str) -> tuple[str, str]:
    parsed = urlparse(uri)
    key = parsed.path.lstrip("/")
    if not parsed.netloc or not key:
        raise ValueError(f"Invalid S3 URI: {uri}")
    return parsed.netloc, key


def _s3_client():
    import boto3  # imported lazily so local runs and tests need no AWS setup

    return boto3.client("s3")


def is_s3(uri: str) -> bool:
    return uri.startswith("s3://")


def download(uri: str, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if is_s3(uri):
        bucket, key = _split_s3(uri)
        _s3_client().download_file(bucket, key, str(dest))
    else:
        shutil.copyfile(uri, dest)
    return dest


def upload(src: Path, uri: str) -> None:
    if is_s3(uri):
        bucket, key = _split_s3(uri)
        _s3_client().upload_file(str(src), bucket, key)
    else:
        target = Path(uri)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, target)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
