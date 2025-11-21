$HF_OWNER = "neashton"
$HF_PREFIX = "drivaerml"
$LOCAL_DIR = "./drivaer_data"

New-Item -ItemType Directory -Force -Path $LOCAL_DIR | Out-Null

1..2 | ForEach-Object {
    $i = $_
    $RUN_DIR = "run_$i"
    $RUN_LOCAL_DIR = "$LOCAL_DIR/$RUN_DIR"
    New-Item -ItemType Directory -Force -Path $RUN_LOCAL_DIR | Out-Null

    Write-Host "Processing Run $i..."

    # Download drivaer_i.stl
    $url_stl = "https://huggingface.co/datasets/$HF_OWNER/$HF_PREFIX/resolve/main/$RUN_DIR/drivaer_$i.stl"
    $output_stl = "$RUN_LOCAL_DIR/drivaer_$i.stl"
    try {
        Invoke-WebRequest -Uri $url_stl -OutFile $output_stl
    } catch {
        Write-Host "Failed to download STL for run $i"
    }

    # Download force_mom_i.csv
    $url_csv = "https://huggingface.co/datasets/$HF_OWNER/$HF_PREFIX/resolve/main/$RUN_DIR/force_mom_$i.csv"
    $output_csv = "$RUN_LOCAL_DIR/force_mom_$i.csv"
    try {
        Invoke-WebRequest -Uri $url_csv -OutFile $output_csv
    } catch {
        Write-Host "Failed to download CSV for run $i"
    }
}
