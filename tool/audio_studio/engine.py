"""Pinned CPU Thai Kokoro adapter. No cloud credentials or synthesis API calls."""
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.request

HERE = Path(__file__).resolve().parent
LOCK = json.loads((HERE / "model-lock.json").read_text(encoding="utf-8"))
SPEAKERS = [
    (0, "female", "Bright / teen"), (1, "female", "Bright / young"),
    (2, "female", "Clear / young"), (3, "female", "Warm / young"),
    (4, "female", "Clear / mature"), (5, "female", "Warm / mature"),
    (6, "female", "Soft / older"), (7, "female", "Low / older"),
    (8, "male", "Bright / teen"), (9, "male", "Clear / young"),
    (10, "male", "Warm / mature"), (11, "male", "Deep / older"),
]


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download_model(folder, progress=lambda message: None, cancelled=lambda: False):
    """Download allowlisted, revision-pinned files and verify every SHA256."""
    folder = Path(folder)
    for index, (name, expected) in enumerate(LOCK["files"].items()):
        if cancelled():
            raise ValueError("Stopped. Completed downloads are kept for next time.")
        path = folder / name
        if path.is_file() and sha256(path) == expected:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        progress(f"Downloading model {index + 1}/{len(LOCK['files'])}: {Path(name).name}")
        url = f"https://huggingface.co/{LOCK['repository']}/resolve/{LOCK['revision']}/{name}"
        temp = path.with_suffix(path.suffix + ".part")
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=90) as response, temp.open("wb") as target:
                    while chunk := response.read(1024 * 1024):
                        if cancelled():
                            raise ValueError("Stopped. Retry to finish model setup.")
                        target.write(chunk)
                if sha256(temp) != expected:
                    raise ValueError("Model integrity check failed; file not loaded")
                temp.replace(path)
                break
            except ValueError:
                raise
            except (OSError, TimeoutError):
                if attempt == 2:
                    raise ValueError(f"Download failed: {Path(name).name}. Check internet and retry.") from None
                time.sleep(1)
    progress("Model files verified. Loading CPU voices...")


def validate_choices(male, female, speed):
    if type(male) is not int or male not in {8, 9, 10, 11}:
        raise ValueError("Choose a male voice")
    if type(female) is not int or female not in set(range(8)):
        raise ValueError("Choose a female voice")
    if type(speed) not in (int, float) or speed not in (0.85, 1.0, 1.1):
        raise ValueError("Choose Slow, Normal or Fast")


def validate_text(text):
    if not isinstance(text, str) or not 1 <= len(text.strip()) <= 500:
        raise ValueError("Enter 1 to 500 Thai characters")
    if re.search(r"[A-Za-z]", text) or not re.search(r"[ก-๿]", text):
        raise ValueError("This lightweight engine accepts Thai text. English voices are not installed.")
    return text.strip()


class KokoroEngine:
    def __init__(self, folder):
        self.folder = Path(folder)
        self.student = None
        self.styles = None

    def prepare(self, progress, cancelled):
        if self.student is not None:
            return
        download_model(self.folder, progress, cancelled)
        # Only integrity-checked Python modules from the pinned model revision enter sys.path.
        sys.path.insert(0, str(self.folder))
        os.environ["KOKORO_THAI_NO_RUST"] = "1"
        from kokoro_thai.onnx_infer import load_onnx, load_styles
        self.student = load_onnx(self.folder / "onnx", precision="fp32", intra_threads=2)
        self.styles = load_styles(self.folder / "onnx")

    def synthesize(self, text, speaker, speed):
        import numpy as np
        import lameenc
        from kokoro_thai.onnx_infer import synth_phonemes, count_tokens
        text = validate_text(text)
        phonemes, word_drops, _ = self.student.g2p.phonemize_report(text)
        if word_drops or not phonemes.strip():
            raise ValueError("A Thai word could not be pronounced. Edit the phrase before retrying.")
        if count_tokens(self.student, phonemes) > 450:
            raise ValueError("Phrase too long for this voice. Split it into shorter phrases.")
        waveform = synth_phonemes(self.student, phonemes, self.styles[speaker], speed=float(speed))
        if waveform.size < 2400 or not np.isfinite(waveform).all() or np.max(np.abs(waveform)) < 0.001:
            raise ValueError("The voice produced empty or invalid audio")
        pcm = (np.clip(waveform, -1, 1) * 32767).astype("<i2").tobytes()
        encoder = lameenc.Encoder()
        encoder.set_bit_rate(128)
        encoder.set_in_sample_rate(24000)
        encoder.set_channels(1)
        encoder.set_quality(2)
        audio = bytes(encoder.encode(pcm)) + bytes(encoder.flush())
        return audio


def verify_mp3(path):
    import miniaudio
    if not path.is_file() or path.stat().st_size < 100:
        raise ValueError("Missing or empty MP3")
    try:
        decoded = miniaudio.decode_file(str(path))
        if decoded.num_frames < 100:
            raise ValueError("No playable audio frames")
    except Exception:
        raise ValueError("MP3 verification failed; retry generation") from None
