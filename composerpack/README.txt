Shadow Play Composer Pack
=========================

Dan Wilcox 2021

Basic info and test data for creating a Pure Data "scene" for the ShadowPlay iOS application.

ShadowPlay is:

>An exploration of architecture and light in outdoor spaces through sound.

User Perspective
----------------

1. Place device in bicycle mount with active camera uncovered (either front or rear)
2. Open ShadowPlay application
3. Calibrate:
  a. Open ... -> Calibrate
  b. Press the Start button
  c. Roll bike over both light and dark areas
  d. Press Stop button when finished
4. Choose audio scene in Scenes table
5. Ride through areas of light and dark to trigger scene audio

Scene Format
------------

A ShadowPlay audio scene is a directory with following contents:

* main.pd: main patch to open
* info.json: metadata (display name, author, description, etc)
* additional support files (optional)

The libpd samplerate is device-native within the app, so don't expect a fixed rate of 44100, etc.

Scene I/O:

* input: #brightness receiver message, f f
  - normalized: float 0 to 1, interpolated from min/max raw range chosen within the app,
                              slightly smoothed via moving average with 2 sample window size
  - raw: float -16 to 16, raw EXIF brightness value for the current frame\* (reference only, prefer normalized)
* output: dac~ stereo audio

\* https://en.wikipedia.org/wiki/APEX_system#Use_of_APEX_values_in_Exif

Test Data
---------

Sample test data is available as qlist text files. The `qlister-play.pd` patch is provided for sample playback to the #brightness receiver.

If you have the app installed on your device, you can also record your own qlists. In ... -> Settings, turn on "Show qlist record controls" to show the record & play buttons on the main view.

The current qlist can be played back after recording to a timestamped text file in the ShadowPlay Documents directory. You can access the saved qlists either via the iOS Files app or Finder/iTunes file sharing and replay them using `qlister-play.pd`.

Running on Device
-----------------

Scene directories can be uploaded to the ShadowPlay Documents folder on your device, either via the Files app or Finder/iTunes file sharing. When the Scenes view is opened, any folders in Documents with the required scene files are automatically included in the list.

Acknowledgements
----------------

Supported through the UNESCO City of Media Arts Karlsruhe as well as through the City of Karlsruhe.

https://www.cityofmediaarts.de/
