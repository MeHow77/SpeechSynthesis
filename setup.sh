#!/bin/bash
###PREREQUISITS###
### start in virtualenv location
### activate virtualenv

export PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
apt-get update -y
apt-get install -y wget
apt-get install -y ffmpeg
pip install -r requirements.txt

###INSTAL APEX###
git clone https://github.com/NVIDIA/apex
cd apex
pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./
cd .. #venv

###CLONE TACOTRON@ REPO###
git clone https://github.com/NVIDIA/tacotron2.git
cd tacotron2 #venv/tacotron2

###DOWNLOAD DATA###
wget http://www.caito.de/data/Training/stt_tts/pl_PL.tgz
tar -xvf pl_PL.tgz

###MOVE DATASET###
mkdir -p polish_22k/wavs
mkdir -p polish/wavs
mv pl_PL/by_book/female/nina_brown/saragossie/wavs polish
mv pl_PL/by_book/female/nina_brown/saragossie/metadata.csv polish_22k/metadata.csv

###PREPROCESS TEXT DATA###
cd polish_22k #venv/tacotron2/polish_22k
awk -F "|" '{print "./polish_22k/wavs/"$1".wav|"$3}' metadata.csv > modFileList.csv
sed -i 's/[[:blank:]]*$//' modFileList.csv
###ADD PUNCTUATION###
#cat modFileList.csv | grep [^,\.\;:?\!-]$ > nonpunc.txt
#awk '{print $0"."}' nonpunc.txt > punct_file_list.txt
#cat modFileList.csv | grep [,\.\;:?\!-]$  >> punct_file_list.txt 
#rm nopunc.txt


cd .. #venv/tacotron2

###GIT MODULES###
git submodule init
git submodule update
git submodule update --remote --merge

###TRUNCATE SILENCE###
cd polish/wavs #venv/tacotron2/polish/wavs
for i in *.wav; do ffmpeg -y -i "$i" -af silenceremove=start_periods=1:stop_periods=1:detection=peak ../../polish_22k/wavs/$i; done
cd ../../ #venv/tacotron2

###ADD SHORT SILENCE AT THE END###
python preprocess.py -p polish/modFileList.csv

cd .. #venv

###RESAMPLE 16kHZ->22kHZ###
./resampling.sh ./tacotron2/polish_22k/wavs ./tacotron2/polish_22k/wavs

###COPY WAVS IN (1,10)SECS RANGE###
filename="saragossie_filelist_thresholded.txt"
dataset_path="./tacotron2/polish_22k"
echo "" > $dataset_path/$filename
./audio_file_selector.sh $dataset_path/punct_file_list.txt $dataset_path/$filename $dataset_pathq/wavs

###SPLIT DATA###
cd $dataset_path
cat $filename | tail -n+4617 > saragossie_train.txt
cat $filename | head -n514 > saragossie_val.txt

#TODO MANUALLY:
#SET SYMBOLS.PY
#CHANGE HPARAMS.PY
#REMOVE EMPTY LINES FROM FILES
