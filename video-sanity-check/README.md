# Video sanity check script

Usage: 

```
./check_video_sanity.sh [-v|-d|-c] <folder_path>
```

## Options:

```
  -v      Display verbose information about files being processed (or skipped).
  -c      Specify a custom cache file name (default is .video_cache inside the script folder)
  -d      Specify the names of the directories the cache should put entry from.
	    Useful if you have multiple mount points to same directory inside a volume.
	    For example: /mnt/hdd0/Movies/dir1/dir2, dir1/dir2 will only be memorized inside the cache.
  folder_path   Path to the folder containing video files
```

## Description:
This script sanity checks video files within the specified folder and subfolders.
It identifies invalid or corrupt video files through ffprobe.
The script has a cache, stored in .video_cache within the script folder,
in order to not re-processed known valid files.
