# Installation
__ffmpeg__ for reading frames (used by VideoReaderFFMPEG):
- OSX: `brew install ffmpeg`
- WIN: download binaries from [here](https://ffmpeg.zeranoe.com/builds/)
- looks for the binary in `/usr/local/bin` (OSX) or `C:\Program Files\ffmpeg\bin` (WIN). see `help  VideoReaderFFMPEG` for how to set custom path.

__GhostScript__ for saving figures. download binaries from the [official website](https://www.ghostscript.com/download/gsdnld.html). add directory with binary (`gs` or `gs.exe`) to your system path.

Download scripts `git clone https://github.com/postpop/playbackanalyses.git` and add the directory `playbackanalyses` and its subdirectories to your matlab path: `addpath(genpath('src')); savepath()`.


# Organization of data
Raw data should be copied to `/scratch/janc/playback/dat/`. After the recordings have been processed copy to `/bucket/murthy/janc/playback/dat.processed/` regularly to free up space on scratch (and to make sure everything is backed up safely).

Tracking results are saved to `/bucket/murthy/jan/playback/res/` on bucket one `VIDEOFILENAME_spd.mat` files per recording.

Metadata for generating tuning curves reside in two databases:
- `playback.xlsx` describes each recorded video: filename, genotype and age, playlist, housing condition. Lives currently in [google docs](https://docs.google.com/spreadsheets/d/1Cld_cK8rZ2hDrUdq62m8VqQZ-ZFrKEkOytXEtac3WlY/edit?usp=sharing). 
- `playbackLists.xlsx` decribes playlists: playlist name (in `playback.xlsx`), x-axis and x-tick labels, etc.

# Running analyses
## Annotate videos
Copy folder for each recording to `/scratch/janc/playback` and run on a local machine:
```matlab
cd /scratch/janc/playback
video_preProcessLocal
```
This will run through all videos that have not been pre-processed in `dat/` so you can mark the fly positions. The script will present you with the first frame of each video and use [`roipoly`](https://www.mathworks.com/help/images/ref/roipoly.html) for annotating the flies: 1) click on the flies, 2) when done right click to close the polygon (even if there's just a single fly), and 3) double click inside the polygon to move on to the next video.

## Track videos
To track the videos run on spock:
```shell
cd /scratch/janc/playback
module load matlab/R2016b
matlab -r 'video_submit([1 1 1]);exit'
```
This will submit three types of jobs that will process the video in serial order:
1. 1 preprocessing jobs - detect chambers and initializes tracker
2. 12 tracker jobs - tracks files and creates one *res.mat per chamber
3. 1 postprocessing jobs - aggregrate *res.mat per video to `/Volumes/jan/playback/res/*_spd.mat` 

See `help video_submit` for arguments.

The generated `*_spd.mat` files contain the following:
- `spdF` 
- `stiID`
- `recID` 
- ...

## Generate tuning curves
See `tuning.m`.

