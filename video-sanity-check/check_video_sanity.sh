#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DEFAULT_CACHE_FILE="$SCRIPT_DIR/.video_cache.txt"
VERBOSE=0
CACHE_FILE=$DEFAULT_CACHE_FILE
USAGE_STRING="Usage: $0 [-v|-d|-c] <folder_path>"
# Check if ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe not found. Please install ffmpeg package."
    exit 1
fi

# Function to display script usage
display_help() {
    echo $USAGE_STRING
    echo "Options:"
    echo "  -v      Display verbose information about files being processed (or skipped)."
    echo "  -c      Specify a custom cache file name (default is .video_cache inside the script folder)"
    echo "  -d      Specify the names of the directories the cache should put entry from."
    echo "	    Useful if you have multiple mount points to same directory inside a volume."
    echo "	    For example: /mnt/hdd0/Movies/dir1/dir2, dir1/dir2 will only be memorized inside the cache."
    echo "  folder_path   Path to the folder containing video files"
    echo
    echo "Description:"
    echo -e "\tThis script sanity checks video files within the specified folder and subfolders."
    echo -e "\tIt identifies invalid or corrupt video files through ffprobe."
    echo -e "\tThe script has a cache, stored in .video_cache within the script folder,"
    echo -e "\tin order to not re-processed known valid files."
}

while getopts ":h:v:d:" opt; do
  case $opt in
    v)
      VERBOSE=$((VERBOSE + 1))
      ;;
    d)
      IFS=',' read -ra FIXED_PATHS <<< "$OPTARG"
      ;;
    c)
      CACHE_FILE="$OPTARG"
      ;;
    h)
      display_help
      exit 0
      ;;
    \?)
      echo -e "Invalid option: -$OPTARG\n" >&2
      display_help
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
  echo $USAGE_STRING
  exit 1
fi

folder_path=$1

# Create or touch the cache file
touch "$CACHE_FILE"

if [ ! -d "$folder_path" ]; then
  echo "Error: The specified path is not a directory."
  exit 1
fi

# Create or touch the cache file
touch "$CACHE_FILE"
INVALID_COUNT=0
PROCESSED_COUNT=0
TOTAL_FILES=$(find "$folder_path" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \) | wc -l)

echo "About to process $TOTAL_FILES total files. Starting now."

while IFS= read -r file; do
  if [ -f "$file" ]; then
    # Remove the initial part of the string up to any fixed path and the next '/' character
    for path in "${FIXED_PATHS[@]}"; do
      	if [[ "$file" == *"$path"* ]]; then
      		file_in_cache=$(echo "$file" | sed "s|^.*/$path/||")
	fi
    done

    # Check if the file is in the cache
    grep -q "$file_in_cache" "$CACHE_FILE" 2> /dev/null
    if [ $? -ne 0 ]; then
      # If not in the cache, process the file and add it to the cache
      if [ $VERBOSE -eq 1 ]; then
      	echo "Checking file: $file ..."
      fi

      ffprobe -loglevel quiet "$file"

      if [ $? -ne 0 ]; then
	echo -e "\e[91mFile $file is invalid or corrupt.\e[0m"
	INVALID_COUNT=$(($INVALID_COUNT + 1))
      else
      	echo "$file_in_cache" >> "$CACHE_FILE"
      fi
    elif [ $VERBOSE -eq 1 ]; then
      echo "File $file has already been processed. Skipping."
    fi
    PROCESSED_COUNT=$(($PROCESSED_COUNT + 1))
  fi

  progress=$(awk "BEGIN { printf \"%.2f\", $PROCESSED_COUNT * 100 / $TOTAL_FILES }")
  echo -ne "Progress: $progress%\r"
done < <(find "$folder_path" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" \))

echo -e "\n\nFound $INVALID_COUNT invalid video files out of $PROCESSED_COUNT total in $folder_path"
