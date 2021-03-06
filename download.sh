#!/bin/bash
#
# A download script for STAIR Actions
# 
# usage:
# bash download.sh 
#
DATADIR=STAIR_Actions_v1.0
TMPDIR=tmp
YOUTUBEDIR=$TMPDIR/youtube
CLIPDIR=$TMPDIR/clip
TOPDIR=`pwd`

# make dir
mkdir -p $DATADIR
mkdir -p $TMPDIR
mkdir -p $YOUTUBEDIR
mkdir -p $CLIPDIR

# download original videos
for action in $(tail -n 100 actionlist.csv | cut -f 2 -d ',')
do
    wget https://data.airc.aist.go.jp/stair-actions-v1.0/train/${action}.zip -P $TMPDIR \
    && unzip $TMPDIR/${action}.zip -d $DATADIR \
    && rm $TMPDIR/${action}.zip
done

# clone ActivityNet repository
git clone https://github.com/activitynet/ActivityNet
chmod +x ActivityNet/Crawler/fetch_activitynet_videos.sh

# download youtube videos
for type in Y X Z
do
    cd ActivityNet/Crawler \
    && ./fetch_activitynet_videos.sh $TOPDIR/$YOUTUBEDIR $TOPDIR/data/youtube_videos_${type}.json \
    && cd -
    bash script/clipping_${type}.sh $YOUTUBEDIR $CLIPDIR
done 

wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O jq
chmod +x ./jq

# move youtube videos to action directories
for action in $(tail -n 100 actionlist.csv | cut -f 2 -d ',')
do  
    for fn in $(jq .[\"$action\"].train[].name -r data/dataset_train.json)
    do
        if [ -e $CLIPDIR/$fn ]
        then
            mv $CLIPDIR/$fn $DATADIR/$action/
        fi
    done
done

# remove tmp dir
rm -fr $TMPDIR

# finish
echo "Finished!"
