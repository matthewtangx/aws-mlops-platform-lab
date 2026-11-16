import pytest

from training import storage


def test_local_roundtrip(tmp_path):
    src = tmp_path / "a.txt"
    src.write_text("hello")
    dest = tmp_path / "out" / "b.txt"
    storage.upload(src, str(dest))
    assert storage.download(str(dest), tmp_path / "c" / "c.txt").read_text() == "hello"


def test_sha256(tmp_path):
    p = tmp_path / "f"
    p.write_bytes(b"abc")
    assert storage.sha256_file(p).startswith("ba7816bf")


class FakeS3:
    def __init__(self):
        self.calls = []

    def upload_file(self, filename, bucket, key):
        self.calls.append(("upload", filename, bucket, key))

    def download_file(self, bucket, key, filename):
        self.calls.append(("download", bucket, key, filename))


def test_s3_paths_use_bucket_and_key(tmp_path, monkeypatch):
    fake = FakeS3()
    monkeypatch.setattr(storage, "_s3_client", lambda: fake)
    src = tmp_path / "m.bin"
    src.write_bytes(b"x")
    storage.upload(src, "s3://bkt/models/sha/model.joblib")
    storage.download("s3://bkt/data/d.csv", tmp_path / "d.csv")
    assert fake.calls[0] == ("upload", str(src), "bkt", "models/sha/model.joblib")
    assert fake.calls[1][:3] == ("download", "bkt", "data/d.csv")


@pytest.mark.parametrize("uri", ["s3://bucket", "s3:///key"])
def test_invalid_s3_uri(uri, tmp_path):
    with pytest.raises(ValueError):
        storage.download(uri, tmp_path / "x")
