from io import BytesIO
import warnings

from fastapi import HTTPException
from PIL import Image, ImageOps, UnidentifiedImageError


def validate_upload(content: bytes, content_type: str) -> bytes:
    if content_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(status_code=400, detail="Unsupported image format")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(content)) as image:
                expected = "PNG" if content_type == "image/png" else "JPEG"
                if image.format != expected or image.width * image.height > 20_000_000:
                    raise ValueError("Image dimensions or format invalid")
                image.verify()
            with Image.open(BytesIO(content)) as image:
                cleaned = ImageOps.exif_transpose(image).convert("RGB")
                cleaned.thumbnail((2048, 2048))
                output = BytesIO()
                cleaned.save(output, format=expected, quality=85)
                return output.getvalue()
    except (UnidentifiedImageError, OSError, ValueError, SyntaxError, Image.DecompressionBombError, Image.DecompressionBombWarning) as exc:
        raise HTTPException(status_code=400, detail="Invalid or oversized image") from exc
