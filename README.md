ShadowPlay
==========

![shadow play alpha 0.1.0](composerpack/doc/app%200.1.0%20alpha.jpeg)

Copyright (c) [Dan Wilcox](danomatika.com) 2021

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

Description
-----------

ShadowPlay is an exploration of architecture and light in outdoor spaces through sound. Using a bicycle-mounted sensor and a smartphone aimed skywards, the mottled patterns of light and shadow become the musical score and one rides along their city streets. Much like a simple music box plucked by patterns of pins on a rotating wheel, the transitions between light and dark as you ride control playback of prepared sequences, generated patterns, or prepared audio playback speed.

![street building shadows](composerpack/doc/street%20buildings.jpeg)

User Guide
----------

1. Place device in bicycle mount with active camera uncovered (either front or rear)
2. Open ShadowPlay application
3. Calibrate:
  a. Open calibration interface & press Start button
  b. Roll bike over both light and dark areas along the route you wish to sonify
  c. Press Stop button when finished
4. Choose scene
5. Ride through areas of light and dark to trigger scene audio

Developing
----------

### Dependencies

* [libpd](http://github.com/libpd/libpd): included as a git submodule

### Checkout & Build

Clone this repository and checkout it's submodules using git:

    git clone https://github.com/danomatika/ShadowPlay.git
    git submodule update --init --recursive

Open the Xcode project and Build/Run.

### Release steps

1. Update version in Xcode project and changelog
2. Update changelog with relevant changes
3. Archive and distribute to App Store Connect
4. Tag version

Acknowledgments
---------------

Supported through the UNESCO City of Media Arts Karlsruhe as well as through the City of Karlsruhe. / Unterstützt durch die UNESCO City of Media Arts Karlsruhe sowie durch die Stadt Karlsruhe.

![KA UNESCO COMA logo](media/logo_karlsruhe-unesco_rgb.svg)

Sound scene contributions by:

* Sofy Yuditskaya (New York, USA) <https://www.yuditskaya.com>
* Damian Stewart (Vienna, AT) <http://damianstewart.com>
