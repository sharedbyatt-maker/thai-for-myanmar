# Thai Audio Studio — no-card local web interface

## Windows: the short version

1. Download the repository ZIP from the branch containing this change (GitHub **Code → Download ZIP**).
2. Right-click the ZIP → **Extract All**. Do not run from inside the ZIP. Use a normal writable folder such as Documents; avoid an administrator-only folder.
3. Double-click **Start_Audio_Studio.bat** in the extracted folder. Leave the console window open. First launch downloads a hash-verified uv Windows x64 binary from its official GitHub release, creates a private Python 3.11 environment, and installs PyPI dependencies. It does not need administrator access or alter your global Python/PATH. The PowerShell execution-policy flag applies only to this launcher process, not a permanent machine policy change; do not bypass organization policies or Windows security warnings.
4. Your browser opens **Thai Audio Studio** at a private `127.0.0.1` URL. Click the green **အသံစမ်းမယ်** button. The first synthesis downloads and verifies about 332 MB of Thai Kokoro model/runtime files. The full initial setup also downloads Python and packages, so total download is larger. Keep internet connected for setup.
5. Listen with the audio player. Try male/female voices and Slow/Normal. Generate the nine-file sample first, then all 990 files if satisfied. The ZIP button appears when ready. Extract it and check `generation-report.json`; only `status: complete` with `readyForms: 990` indicates complete all-corpus coverage.
6. Press **Studio ပိတ်မယ်** when finished. The launcher window can then be closed. Closing only the browser tab does not stop the server.

No Google account, card, API key or Google Cloud project is needed. If you already created a Google project, this tool does not touch its billing or credentials.

## What runs where?

The browser is a local control panel. Downloads happen on first setup; text synthesis runs on the computer's CPU using Thai Kokoro ONNX. No synthesis API or paid cloud service is called. Once the required model and dependencies are cached, Thai generation does not need network access. Dependency checks at launcher startup may still contact PyPI. No GPU is required. Windows x64 is supported by the launcher; Windows ARM/32-bit and macOS launchers are not included.

This is a **local web view**, not a hosted website. A public static page cannot run this Python engine by itself. Do not put this server on Render or a public network: it intentionally binds only to loopback and uses a random session token and same-origin checks. Do not forward its port or share its private launch URL. There are no analytics, CDN scripts or remote fonts in the UI.

## Audio and output

- Default voices are roster 9 (`m_young_clear`) and 2 (`f_young_clear`); all 12 model voices can be previewed.
- Voice descriptions are the model author's labels, not an independent assessment of age or quality.
- Male/female **phrase forms** remain exact dataset text; neutral phrases use the selected female voice.
- Changing voice or speed creates a different cache identity, so old audio is not incorrectly reused.
- Browser controls play generated MP3 previews. Batch output includes MP3 files, exact-text app manifest, source dataset, generation report and engine provenance.
- Work is saved under `build/audio-studio/`. Jobs remain in `jobs/`; matching verified files remain in `cache/`. The tool never deletes production audio or edits the app's checked-in audio manifest.
- Stop finishes the current CPU operation, then preserves a partial ZIP when possible. Partial output is explicitly marked. Restarting uses cached complete files. An abruptly closed console can lose the current operation, but completed cache files remain.
- Time depends on CPU and phrase lengths. No fixed completion-time promise is made.
- The lightweight frontend handles Thai, including the current 502-phrase corpus. English text is explicitly rejected rather than silently producing incomplete audio. Very long phrases and unpronounceable words fail with a message instead of a fake success.

## Review before public release

The model card declares Apache-2.0, and the app's ZIP records the model source/revision. Model/voice provenance and generated pronunciation are not independently certified. Human Thai listening review remains required before importing recordings into a public learning app, especially tones, particles, placeholders, medical and emergency phrases. Do not claim the generated voices are native-speaker recordings.

After review, copy the ZIP's `assets/` into a new app branch, run the existing content/audio validators and Flutter checks, and submit the audio pack for review. The tool does not automatically publish or merge audio.

## Pinned source and integrity

- Model: [kunato/wayu-kokoro-thai-v1](https://huggingface.co/kunato/wayu-kokoro-thai-v1), revision `abf63dc118365bea784fa881bdd1dce4b2cc1fd4`.
- `tool/audio_studio/model-lock.json` allowlists the runtime Python files, configuration and ONNX files by SHA256. Only verified files are imported; no pickle/Torch checkpoint or arbitrary user model is loaded by this tool. The model runtime uses ONNX and NumPy artifacts.
- Bootstrap: [astral-sh/uv](https://github.com/astral-sh/uv), Windows x64 release `0.13.6`, ZIP SHA256 `a2a8820d5eea32f08ef467ef3b7f66883a9b076d5737a2fc2fbb5f458d1bb50f`.
- Direct dependencies are pinned for Python 3.11 compatibility, including tltk's sklearn 1.2 requirement and NumPy <2. uv resolves transitive platform wheels from PyPI; it is not a complete cross-platform dependency lock.

## Troubleshooting

- **No browser opens:** copy the private URL printed in the launcher into Chrome/Edge.
- **Download fails:** check internet, then rerun. Completed verified model files are reused. No key or card will fix a blocked download.
- **Installation error / missing wheel:** copy the final error message. Do not install compilers or change machine security settings just to work around it.
- **Microsoft runtime DLL error:** ONNX may require the official Microsoft Visual C++ x64 Redistributable on some Windows machines. The launcher does not install system components automatically; share the exact error before proceeding.
- **App still uses old TTS:** expected until reviewed MP3s and the new manifest are imported into the app and rebuilt.

## Developer checks

`python -m unittest discover -s tool/tests -p 'test_audio_studio.py' -v` tests the HTTP API and batch behavior with an injected fake engine and no model download. `python tool/audio_studio/server.py` runs the real engine after installing `tool/audio_studio/requirements.txt` in Python 3.11. Linux is supported for development, but the double-click launcher is Windows only.
