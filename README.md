# Installation
__ffmpeg__ for reading frames (used by [VideoReaderFFMPEG](https://github.com/postpop/VideoReaderFFMPEG)):
- OSX: `brew install ffmpeg`
- WIN: download binaries from [here](https://ffmpeg.zeranoe.com/builds/)
- `VideoReaderFFMPEG` look for the `ffmpeg` binary in `/usr/local/bin` (OSX) or `C:\Program Files\ffmpeg\bin` (WIN). See `help  VideoReaderFFMPEG` for how to set a custom path to the binary.

__GhostScript__ for saving figures. Download binaries from the [official website](https://www.ghostscript.com/download/gsdnld.html). Add directory with the ghostscript binary (`gs` or `gs.exe`) to your system path.

Download the code `git clone https://github.com/murthylab/FLyTRAP.git`, cd into the newly created directory `FLyTRAP` and add the `src` subdirectory to your matlab path: `addpath(genpath('src')); savepath()`.


# Organization of data
Raw data should be copied to `/scratch/murthyplayback/dat/`. After the recordings have been processed copy to `/bucket/murthy/playback/dat.processed/` regularly to free up space on `scratch` (and to make sure everything is backed up safely).

Tracking results are saved to `/bucket/murthy/playback/res/` on `bucket` one `VIDEOFILENAME_spd.mat` file per recording.

Metadata for generating tuning curves reside in [a spreadsheet on google docs](https://docs.google.com/spreadsheets/d/1Cld_cK8rZ2hDrUdq62m8VqQZ-ZFrKEkOytXEtac3WlY/edit?usp=sharing):
- The sheet `list` describes each recorded video: filename, genotype and age, playlist, housing condition.
- The sheet `playbackLists` describes playlists\tuning curves: playlist name (in `list`), x-axis and x-tick labels, etc.
- The sheets are pulled from google docs automatically by `tuning.m`.

# Running analyses
## Annotate videos
Copy folder for each recording to `/scratch/murthyplayback` and run on a _local_ machine:
```matlab
cd /scratch/murthyplayback
video_preProcessLocal
```
This will run through all videos that have not been pre-processed in `dat/` so you can mark the fly positions. The script will present you with the first frame of each video and use [`roipoly`](https://www.mathworks.com/help/images/ref/roipoly.html) for annotating the flies: 1) click on the flies, 2) when done right click to close the polygon (even if there's just a single fly), and 3) double click inside the polygon to move on to the next video.

## Track videos
To track the videos run _on spock_:
```shell
cd /scratch/murthyplayback
module load matlab/R2016b
matlab -r 'video_submit([1 1 1]);exit'
```
This will submit three types of jobs that will process the video in serial order:
1. _Preprocessing:_ detects chambers and initializes tracker
2. _Tracking:_ tracks files and creates one `*res.mat` file per chamber
3. _Postprocessing:_ aggregrates the data in the `*res.mat` for each experiment and copies the results to `/bucket/murthy/playback/res/*_spd.mat` 

See `help video_submit` for arguments.

## Generate tuning curves
See `tuning.m`.

