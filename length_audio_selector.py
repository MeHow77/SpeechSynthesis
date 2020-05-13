from scipy.io.wavfile import write
from pydub import AudioSegment
import librosa
import numpy as np
import argparse


def select_samples(file_name):
    min_len = 1
    max_len = 10
    max_total_len = 36000
    curr_len = 0

    f = open(file_name, 'r', encoding='utf-8')
    R = f.readlines()
    f.close()
    
    matched_files = []
    for i, line in enumerate(R):
        wav_name = line.split('|')[0]
        wav_file = AudioSegment.from_file(wav_name)
        if wav_file.duration_seconds > min_len and wav_file.duration_seconds < max_len:
            matched_files.append(line)
            curr_len += wav_file.duration_seconds
        if curr_len >= max_total_len:
            break

    thresholded_file_name =  file_name.split('/')[-1].split('.')[0]+'_thresholded.txt'
    with open(thresholded_file_name, 'w', encoding='utf-8') as f1:
        f1.writelines(matched_files)

if __name__ == "__main__":
    """
    usage
    python preprocess_audio.py -f=filelists/nam-h_test_filelist.txt,filelists/nam-h_train_filelist.txt,filelists/nam-h_val_filelist.txt -s=3
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file_name', type=str,
                        help='metadata to preprocess')
    args = parser.parse_args()
    select_samples(args.file_name)
