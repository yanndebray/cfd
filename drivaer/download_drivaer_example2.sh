#!/bin/bash

# Set the path and prefix
HF_OWNER="neashton"
HF_PREFIX="drivaerml"

# Set the local directory to download the files
LOCAL_DIR="./drivaer_data"

# Create the local directory if it doesn't exist
mkdir -p "$LOCAL_DIR"

# Loop through the run folders from 1 to 2
for i in $(seq 1 2); do
    RUN_DIR="run_$i"
    RUN_LOCAL_DIR="$LOCAL_DIR/$RUN_DIR"

    # Create the run directory if it doesn't exist
    mkdir -p "$RUN_LOCAL_DIR"

    # Download the drivaer_i.stl file
    wget "https://huggingface.co/datasets/${HF_OWNER}/${HF_PREFIX}/resolve/main/$RUN_DIR/drivaer_$i.stl" -O "$RUN_LOCAL_DIR/drivaer_$i.stl"

    # Download the force_mom_i.csv file
    wget "https://huggingface.co/datasets/${HF_OWNER}/${HF_PREFIX}/resolve/main/$RUN_DIR/force_mom_$i.csv" -O "$RUN_LOCAL_DIR/force_mom_$i.csv"

    # Note: The example on the website mentions images but does not provide the specific wget command for them in the snippet.
    # Images are likely in an 'Images' subdirectory. Downloading a directory via wget requires recursive flags or knowing filenames.
done
