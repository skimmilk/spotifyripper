spotifyripper
=============

Rips music from Spotify as it plays through the Spotify Linux client on Debian/Ubuntu and dumps into the /tmp/spotifyripper directory.

Run with:
```bash
./spotifyripper.py
```

Requirements (Ubuntu):
```bash
sudo apt install -y python3-pip python3-pydub ffmpeg libavcodec-extra libmp3lame0
pip3 install pulsectl
```

Requires that Spotify is running and has played music *before* the ripper is ran and no other music software is running.

This application records the audio that is played from Spotify, much like one would rip songs from a radio.

## Features

The recorded audio is automatically splitted and tagged with the artist, song name, track number, and album cover image information, and encoded in 160kbps MP3.

In order to control and rip Spotify's audio, the client has to be registered with the audio server, which only happens when Spotify plays a sound or song.

In order to split and tag the recording, the information about play/pause/skip events that are sent to the GNOME sound indicator are read.

If any other application sends play/pause/skip events to the sound indicator, the ripper's audio splicing and tagging messes up.
