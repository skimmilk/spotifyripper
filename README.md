spotifyripper
=============

Rips music from Spotify as it plays through the Spotify Linux client on Debian/Ubuntu

Run with:
```bash
./ripper.sh your_music_directory
```

Requirements (Ubuntu):
```bash
sudo apt install -y jq vorbis-tools wget
```

If no directory is specified, it dumps into the current directory.
Requires that Spotify is running and has played music *before* the ripper is ran and no other music software is running.

This application records the audio that is played from Spotify, much like one would rip songs from a radio.

## Features

The recorded audio is automatically splitted and tagged with the artist, song name, track number, and album cover image information, and encoded in 192kbps ogg vorbis.

Because audio interruptions can occur which get recorded along with the song, the ripper gains control over the sound output so only the sound coming from Spotify gets recorded, meaning Spotify will not play through the speakers, however no other sound playing on the machine will be recorded during the rip.

In order to control and rip Spotify's audio, the client has to be registered with the audio server, which only happens when Spotify plays a sound or song.

In order to split and tag the recording, the information about play/pause/skip events that are sent to the GNOME sound indicator are read.

If any other application sends play/pause/skip events to the sound indicator, the ripper's audio splicing and tagging messes up.
