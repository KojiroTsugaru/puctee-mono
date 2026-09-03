import io

import pytest
from fastapi import HTTPException, UploadFile
from PIL import Image

from app.core import storage


class _Response:
    def raise_for_status(self) -> None:
        return None


class _Client:
    def __init__(self, calls: list, **kwargs):
        self.calls = calls

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        return None

    async def post(self, url, *, content, headers):
        self.calls.append((url, content, headers))
        return _Response()


@pytest.mark.asyncio
async def test_profile_upload_uses_supabase_and_returns_public_url(monkeypatch):
    calls = []
    monkeypatch.setattr(storage.settings, "SUPABASE_URL", "https://project.supabase.co/")
    monkeypatch.setattr(storage.settings, "SUPABASE_SECRET_KEY", "")
    monkeypatch.setattr(storage.settings, "SUPABASE_SERVICE_ROLE_KEY", "secret")
    monkeypatch.setattr(storage.settings, "SUPABASE_STORAGE_BUCKET", "public images")
    monkeypatch.setattr(
        storage.httpx,
        "AsyncClient",
        lambda **kwargs: _Client(calls, **kwargs),
    )

    image_buffer = io.BytesIO()
    Image.new("RGBA", (10, 10), (255, 0, 0, 128)).save(image_buffer, "PNG")
    upload = UploadFile(filename="avatar.png", file=io.BytesIO(image_buffer.getvalue()))

    url = await storage.upload_profile_image(upload, user_id=42)

    assert url == (
        "https://project.supabase.co/storage/v1/object/public/"
        "public%20images/profile_images/42.jpg"
    )
    request_url, body, headers = calls[0]
    assert request_url.endswith("/storage/v1/object/public%20images/profile_images/42.jpg")
    assert body.startswith(b"\xff\xd8")
    assert headers["Content-Type"] == "image/jpeg"
    assert headers["x-upsert"] == "true"
    assert headers["Authorization"] == "Bearer secret"


@pytest.mark.asyncio
async def test_upload_requires_server_side_storage_credentials(monkeypatch):
    monkeypatch.setattr(storage.settings, "SUPABASE_SECRET_KEY", "")
    monkeypatch.setattr(storage.settings, "SUPABASE_SERVICE_ROLE_KEY", "")

    with pytest.raises(HTTPException) as error:
        await storage.upload_proof_image(b"image", user_id=1, request_id=2)

    assert error.value.status_code == 503
