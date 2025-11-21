$HF_OWNER = "neashton"
$HF_PREFIX = "drivaerml"
$LOCAL_DIR = "./drivaer_data"

# List of slice files identified from the repository
$slice_files = @(
    "xNormal-autocfd_1.vtp",
    "xNormal-autocfd_2.vtp",
    "xNormal_m01000.vtp", "xNormal_m03000.vtp", "xNormal_m05000.vtp", "xNormal_m07000.vtp", "xNormal_m09000.vtp",
    "xNormal_m11000.vtp", "xNormal_m13000.vtp", "xNormal_m15000.vtp",
    "xNormal_p01000.vtp", "xNormal_p03000.vtp", "xNormal_p05000.vtp", "xNormal_p07000.vtp", "xNormal_p09000.vtp",
    "xNormal_p11000.vtp", "xNormal_p13000.vtp", "xNormal_p15000.vtp", "xNormal_p17000.vtp", "xNormal_p19000.vtp",
    "xNormal_p21000.vtp", "xNormal_p23000.vtp", "xNormal_p25000.vtp", "xNormal_p27000.vtp", "xNormal_p29000.vtp",
    "xNormal_p31000.vtp", "xNormal_p33000.vtp", "xNormal_p35000.vtp", "xNormal_p37000.vtp", "xNormal_p39000.vtp",
    "xNormal_p41000.vtp", "xNormal_p43000.vtp", "xNormal_p45000.vtp", "xNormal_p47000.vtp", "xNormal_p49000.vtp",
    "xNormal_p51000.vtp", "xNormal_p53000.vtp", "xNormal_p55000.vtp", "xNormal_p57000.vtp", "xNormal_p59000.vtp",
    "xNormal_p61000.vtp", "xNormal_p63000.vtp", "xNormal_p65000.vtp",
    "yNormal_m02000.vtp", "yNormal_m04000.vtp", "yNormal_m06000.vtp", "yNormal_m08000.vtp", "yNormal_m10000.vtp",
    "yNormal_m12000.vtp", "yNormal_m14000.vtp"
)

# Runs to process
$runs = 1, 2

foreach ($i in $runs) {
    $RUN_DIR = "run_$i"
    $RUN_LOCAL_DIR = "$LOCAL_DIR/$RUN_DIR/slices"
    New-Item -ItemType Directory -Force -Path $RUN_LOCAL_DIR | Out-Null

    Write-Host "Processing Slices for Run $i..."

    foreach ($file in $slice_files) {
        $url = "https://huggingface.co/datasets/$HF_OWNER/$HF_PREFIX/resolve/main/$RUN_DIR/slices/$file"
        $output = "$RUN_LOCAL_DIR/$file"
        
        # Skip if already exists
        if (Test-Path $output) {
            Write-Host "  Skipping $file (already exists)"
            continue
        }

        Write-Host "  Downloading $file..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $output
        } catch {
            Write-Host "  Failed to download $file"
        }
    }
}
