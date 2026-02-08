# Scream - Music-Reactive Ribbon Shader

A raymarched twisting ribbon tunnel that reacts to music, built for [Shadertoy](https://www.shadertoy.com).

## Setup on Shadertoy

1. Go to [shadertoy.com/new](https://www.shadertoy.com/new)
2. Paste the contents of `music_ribbons.glsl` into the editor
3. Click **iChannel0** at the bottom and select a **music track** (or microphone input)
4. Hit play

## How the Audio Reactivity Works

| Frequency Band | What It Controls |
|---|---|
| **Bass** (low freq) | Ribbon width/thickness, camera speed, edge glow |
| **Mids** (mid freq) | Ribbon length, rotation speed |
| **Treble** (high freq) | Color shifts, background brightness |
| **Waveform** | Oscilloscope line overlay across the screen |

## Based On

A classic twisting ribbon raymarcher using box SDFs with domain repetition, enhanced with Shadertoy's audio FFT texture (`iChannel0`).
