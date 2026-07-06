#!/bin/bash

SOURCE_IMG="/Users/sridhargs/.gemini/antigravity/brain/a01fe749-7217-45b9-bc6d-4fca833ca5d2/deep_sci_icon_1783115668078.png"
DEST_DIR="/Users/sridhargs/Documents/Antigravity/SpamCallTagging/DeepSCI/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$DEST_DIR"

echo "Scaling app icons using sips..."

sips -z 40 40 "$SOURCE_IMG" --out "$DEST_DIR/icon-20x20@2x.png" > /dev/null
sips -z 60 60 "$SOURCE_IMG" --out "$DEST_DIR/icon-20x20@3x.png" > /dev/null

sips -z 58 58 "$SOURCE_IMG" --out "$DEST_DIR/icon-29x29@2x.png" > /dev/null
sips -z 87 87 "$SOURCE_IMG" --out "$DEST_DIR/icon-29x29@3x.png" > /dev/null

sips -z 80 80 "$SOURCE_IMG" --out "$DEST_DIR/icon-40x40@2x.png" > /dev/null
sips -z 120 120 "$SOURCE_IMG" --out "$DEST_DIR/icon-40x40@3x.png" > /dev/null

sips -z 120 120 "$SOURCE_IMG" --out "$DEST_DIR/icon-60x60@2x.png" > /dev/null
sips -z 180 180 "$SOURCE_IMG" --out "$DEST_DIR/icon-60x60@3x.png" > /dev/null

sips -z 152 152 "$SOURCE_IMG" --out "$DEST_DIR/icon-76x76@2x.png" > /dev/null
sips -z 167 167 "$SOURCE_IMG" --out "$DEST_DIR/icon-83.5x83.5@2x.png" > /dev/null

sips -z 1024 1024 "$SOURCE_IMG" --out "$DEST_DIR/icon-1024.png" > /dev/null

echo "Generating Contents.json..."

cat <<EOT > "$DEST_DIR/Contents.json"
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "icon-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "icon-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "icon-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "icon-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "icon-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "icon-1024.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOT

echo "Icon asset catalog generated successfully."
