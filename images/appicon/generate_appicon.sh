#! /bin/bash
#
# generate various icon size sets using ImageMagick
#
# Dan Wilcox <danomatika@gmail.com> 2021
#

WD=$(dirname $0)
DEST=_generated

NAME=shadowplay
ICON=$NAME-1024.png

# $1 - width
# $2 - height
# $3 - filename
function convert-icon() {
	convert $ICON -resize $1x$2 -density 72 $DEST/$3.png
}

###

cd $WD

DEST=$(pwd)/$DEST
mkdir -p $DEST

# iPhone Notification iOS 7-14
# iPad Notifications iOS 7-14
convert-icon 20 20 $NAME-20
convert-icon 40 40 $NAME-20@2x
convert-icon 60 60 $NAME-20@3x

# iPhone Settings iOS 7-14
# iPad Settings iOS 7-14
convert-icon 29 29 $NAME-29
convert-icon 58 58 $NAME-29@2x
convert-icon 87 87 $NAME-29@3x

# iPhone Spotlight iOS 7-14
# iPad Spotlight iOS 7-14
convert-icon 40 40 $NAME-40
convert-icon 80 80 $NAME-40@2x
convert-icon 120 120 $NAME-40@3x

# iPhone App iOS 7-14
convert-icon 120 120 $NAME-60@2x
convert-icon 180 180 $NAME-60@3x

# iPad App iOS 7-14
convert-icon 76 76 $NAME-76
convert-icon 152 152 $NAME-76@2x

# iPad Pro App iOS 10
convert-icon 167 167 $NAME-83-5@2x

# App Store iOS
convert-icon 1024 1024 $NAME-1024
