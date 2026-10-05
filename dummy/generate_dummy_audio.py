import os
import subprocess
import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SFX_DIR = os.path.join(BASE, "sfx")
BGM_DIR = os.path.join(BASE, "bgm")
os.makedirs(SFX_DIR, exist_ok=True)
os.makedirs(BGM_DIR, exist_ok=True)

# (filename, duration_seconds)
SFX = {
    "jump": 0.35,
    "double_jump": 0.35,
    "land": 0.30,
    "attack": 0.40,
    "hit": 0.35,
    "defeat": 0.55,
    "hurt": 0.45,
    "collect_key": 0.45,
    "collect_emblem": 0.40,
    "win": 0.90,
    "victory": 1.40,
    "lose": 0.90,
    "checkpoint": 0.50,
    "portal": 0.70,
    "crumble": 0.50,
    "teleport": 0.55,
    "node": 0.55,
    "mushroom": 0.35,
    "vine": 0.45,
    "dig": 0.45,
    "lever": 0.35,
    "glide": 0.30,
    "ui": 0.18,
    "thunder": 0.60,
    "time_warning": 0.40,
    "start": 0.70,
    "pause": 0.25,
}


def make(path, dur):
    # -f lavfi -i anullsrc produces a silent audio stream; encode as valid mp3.
    cmd = [
        FFMPEG, "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-t", str(dur), "-q:a", "9", "-map", "a", path,
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


count = 0
for name, dur in SFX.items():
    p = os.path.join(SFX_DIR, f"{name}.mp3")
    make(p, dur)
    count += 1

# Background music: a longer silent loop placeholder.
bgm_path = os.path.join(BGM_DIR, "bgm.mp3")
make(bgm_path, 6.0)
count += 1

print(f"Generated {count} dummy mp3 files under {os.path.abspath(BASE)}")
