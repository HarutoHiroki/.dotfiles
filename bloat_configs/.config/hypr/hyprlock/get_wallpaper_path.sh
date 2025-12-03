#!/usr/bin/env bash

# Get wallpaper path from illogical-impulse config
# For video files, returns thumbnailPath instead

II_CONFIG="$HOME/.config/illogical-impulse/config.json"

if [[ ! -f "$II_CONFIG" ]]; then
  echo "# Error: Config file not found at $II_CONFIG"
  echo "\$wallpaper = "
  exit 1
fi

# Extract wallpaperPath using jq
if command -v jq &> /dev/null; then
  WALLPAPER_PATH=$(jq -r '.background.wallpaperPath' "$II_CONFIG")
  
  if [[ "$WALLPAPER_PATH" == "null" || -z "$WALLPAPER_PATH" ]]; then
    echo "# Error: wallpaperPath not found in config"
    echo "\$wallpaper = "
    exit 1
  fi
  
  # Get file extension (lowercase)
  EXTENSION="${WALLPAPER_PATH##*.}"
  EXTENSION="${EXTENSION,,}"
  
  # Check if it's a video file
  if [[ "$EXTENSION" == "mp4" || "$EXTENSION" == "webm" || "$EXTENSION" == "mkv" || "$EXTENSION" == "avi" || "$EXTENSION" == "mov" ]]; then
    # Get thumbnailPath for video files
    THUMBNAIL_PATH=$(jq -r '.background.thumbnailPath' "$II_CONFIG")
    
    if [[ "$THUMBNAIL_PATH" == "null" || -z "$THUMBNAIL_PATH" ]]; then
      echo "# Warning: Video detected but thumbnailPath is empty, using wallpaperPath"
      echo "\$wallpaper = $WALLPAPER_PATH"
    else
      echo "\$wallpaper = $THUMBNAIL_PATH"
    fi
  else
    echo "\$wallpaper = $WALLPAPER_PATH"
  fi
else
  # Fallback to grep/sed if jq is not available
  WALLPAPER_PATH=$(grep -o '"wallpaperPath"[[:space:]]*:[[:space:]]*"[^"]*"' "$II_CONFIG" | sed 's/.*"wallpaperPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
  
  if [[ -z "$WALLPAPER_PATH" ]]; then
    echo "# Error: wallpaperPath not found in config"
    echo "\$wallpaper = "
    exit 1
  fi
  
  # Get file extension (lowercase)
  EXTENSION="${WALLPAPER_PATH##*.}"
  EXTENSION="${EXTENSION,,}"
  
  # Check if it's a video file
  if [[ "$EXTENSION" == "mp4" || "$EXTENSION" == "webm" || "$EXTENSION" == "mkv" || "$EXTENSION" == "avi" || "$EXTENSION" == "mov" ]]; then
    # Get thumbnailPath for video files
    THUMBNAIL_PATH=$(grep -o '"thumbnailPath"[[:space:]]*:[[:space:]]*"[^"]*"' "$II_CONFIG" | sed 's/.*"thumbnailPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    
    if [[ -z "$THUMBNAIL_PATH" ]]; then
      echo "# Warning: Video detected but thumbnailPath is empty, using wallpaperPath"
      echo "\$wallpaper = $WALLPAPER_PATH"
    else
      echo "\$wallpaper = $THUMBNAIL_PATH"
    fi
  else
    echo "\$wallpaper = $WALLPAPER_PATH"
  fi
fi
