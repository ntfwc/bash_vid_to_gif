#!/bin/bash

#--------------------------Settings------------------------------

#Output settings
OUTPUT_GIF="out.gif"
RESIZE_WIDTH=200
OPTIMIZE=1

#Program settings
VIDEO_CONVERTER=ffmpeg #avconv or ffmpeg
VIDEO_INSPECTOR=ffprobe #avprobe or ffprobe

#Temporary intermediate files
TMP_DIR="/tmp"
INTERMEDIATE_FRAMES_DIR="$TMP_DIR/gif_conversion_frames"
INTERMEDIATE_GIF="$TMP_DIR/intermediate_gif.gif" #Used with gif optimization

#-----------------------------------------------------------------

#Parse input
INPUT_VIDEO="$1"

if [ -z $1 ]
then
	echo "Usage: convert_video_to_gif.sh video_file [duration] [starting_second]"
	exit 0
fi

if [ ! -r "$INPUT_VIDEO" ]
then
	echo "Given video is not readable"
	exit 1
fi

POSITIVE_NUM_RE='^[0-9]+(\.[0-9]+)?$'

if [ ! -z $2 ]
then
	if [[ $2 =~ $POSITIVE_NUM_RE ]]
	then
		DURATION=$2
	else
		echo "Given duration does not look like a positive number"
		exit 1
	fi
fi

if [ -z $3 ]
then
	START_SECOND=0
else
	if [[ $3 =~ $POSITIVE_NUM_RE ]]
	then
		START_SECOND=$3
	else
		echo "Given start second does not look like a positive number"
		exit 1
	fi
fi

#Set up
mkdir $INTERMEDIATE_FRAMES_DIR

#Extract the frames
if [ -z $DURATION ]
then
	$VIDEO_CONVERTER -i "$INPUT_VIDEO" -pix_fmt rgb24 "$INTERMEDIATE_FRAMES_DIR/%3d.png" || exit 1
else
	$VIDEO_CONVERTER -i "$INPUT_VIDEO" -ss $START_SECOND -t $DURATION -pix_fmt rgb24  "$INTERMEDIATE_FRAMES_DIR/%3d.png" || exit 1
fi

#Get the framerate
FRAMERATE=$($VIDEO_INSPECTOR -v quiet -show_streams "$INPUT_VIDEO" | grep -P -o '(?<=(r_frame_rate=))[0-9]+' | cut -f 1 -d $'\n')

#Create the gif
if [ $OPTIMIZE -eq 1 ]
then
	convert -delay 1x$FRAMERATE -loop 0 -resize $RESIZE_WIDTH "$INTERMEDIATE_FRAMES_DIR/*.png" "$INTERMEDIATE_GIF"
	convert -layers Optimize "$INTERMEDIATE_GIF" "$OUTPUT_GIF"
else
	convert -delay 1x$FRAMERATE -loop 0 -resize $RESIZE_WIDTH "$INTERMEDIATE_FRAMES_DIR/*.png" "$OUTPUT_GIF"
fi

#Clean up
rm $INTERMEDIATE_FRAMES_DIR/*.png
rm "$INTERMEDIATE_GIF"
rmdir "$INTERMEDIATE_FRAMES_DIR"
