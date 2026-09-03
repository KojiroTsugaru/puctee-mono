import io
import logging
from urllib.parse import quote

import httpx
from anyio import to_thread
from fastapi import HTTPException, UploadFile
from PIL import Image

from app.core.config import settings


logger = logging.getLogger(__name__)


def _storage_config() -> tuple[str, str, str]:
    storage_key = settings.SUPABASE_SECRET_KEY or settings.SUPABASE_SERVICE_ROLE_KEY
    if (
        not settings.SUPABASE_URL
        or not storage_key
        or not settings.SUPABASE_STORAGE_BUCKET
    ):
        raise HTTPException(
            status_code=503,
            detail="Supabase Storage is not configured",
        )
    return (
        settings.SUPABASE_URL.rstrip("/"),
        storage_key,
        settings.SUPABASE_STORAGE_BUCKET,
    )


async def compress_image(file: UploadFile, max_size: tuple[int, int] = (800, 800)) -> bytes:
    raw = await file.read()

    def _sync_compress(data: bytes) -> bytes:
        with Image.open(io.BytesIO(data)) as image:
            image.thumbnail(max_size, Image.Resampling.LANCZOS)
            # JPEG cannot encode alpha channels, so flatten transparent images first.
            if image.mode in ("RGBA", "LA") or "transparency" in image.info:
                rgba_image = image.convert("RGBA")
                background = Image.new("RGB", rgba_image.size, "white")
                background.paste(rgba_image, mask=rgba_image.getchannel("A"))
                image = background
            else:
                image = image.convert("RGB")

            output = io.BytesIO()
            image.save(output, format="JPEG", quality=85, optimize=True)
            return output.getvalue()

    try:
        return await to_thread.run_sync(_sync_compress, raw)
    except (OSError, ValueError) as exc:
        raise HTTPException(status_code=400, detail="Invalid image file") from exc


async def _upload_object(object_path: str, data: bytes, content_type: str) -> str:
    supabase_url, storage_key, bucket = _storage_config()
    encoded_bucket = quote(bucket, safe="")
    encoded_path = quote(object_path, safe="/")
    upload_url = f"{supabase_url}/storage/v1/object/{encoded_bucket}/{encoded_path}"
    headers = {
        "apikey": storage_key,
        "Content-Type": content_type,
        "x-upsert": "true",
    }
    # Legacy service_role keys are JWTs and Storage expects them as a bearer
    # token. Modern sb_secret keys belong only in the apikey header.
    if not storage_key.startswith("sb_secret_"):
        headers["Authorization"] = f"Bearer {storage_key}"

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(upload_url, content=data, headers=headers)
            response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        logger.exception("Supabase Storage rejected an image upload")
        raise HTTPException(status_code=502, detail="Image storage upload failed") from exc
    except httpx.RequestError as exc:
        logger.exception("Supabase Storage request failed")
        raise HTTPException(status_code=502, detail="Image storage is unavailable") from exc

    return f"{supabase_url}/storage/v1/object/public/{encoded_bucket}/{encoded_path}"


async def upload_profile_image(file: UploadFile, user_id: int) -> str:
    compressed_image = await compress_image(file)
    return await _upload_object(
        object_path=f"profile_images/{user_id}.jpg",
        data=compressed_image,
        content_type="image/jpeg",
    )


async def upload_proof_image(image_data: bytes, user_id: int, request_id: int) -> str:
    return await _upload_object(
        object_path=f"penalty_proof_images/{user_id}_{request_id}.jpg",
        data=image_data,
        content_type="image/jpeg",
    )
