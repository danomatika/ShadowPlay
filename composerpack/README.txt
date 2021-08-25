Shadow Play Composer Pack
=========================

Dan Wilcox 2021

Basic info and test data for creating a Pure Data "scene" for the ShadowPlay iOS application.

>An exploration of architecture and light in outdoor spaces through sound.

User Perspective
----------------

(Projection so far based on pre-production work.)

1. Open ShadowPlay application
2. Calibrate:
  a. Point camera at area of shadow & set brightness min
  b. Point camera at area of light & set brightness max
3. Place device in bicycle mount with active camera facing up or down
4. Choose scene & press play
5. Ride through areas of light and dark to trigger scene audio

Scene Format
------------

Directory with following contents:

* main.pd: main patch to open
* info.json: metadata (display name, author, description, etc)
* additional support files (optional)

The libpd samplerate is device-native within the app, so don't expect a fixed 44100, etc.

Scene I/O:

* input: #brightness receiver message, f f
  - normalized: float 0 to 1, interpolated from min/max raw range chosen within the app,
                              slightly smoothed via moving average with 2 sample window size
  - raw: float -16 to 16, raw EXIF brightness value for the current frame\*
* output: dac~ stereo audio

\* https://en.wikipedia.org/wiki/APEX_system#Use_of_APEX_values_in_Exif

Test Data
---------

Sample test data is available as qlist text files. The `qlister-play.pd` patch is provided for sample playback to the #brightness receiver.
