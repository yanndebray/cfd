"""parse_vtp_slices.py

Reads all .vtp slice files in a directory (e.g. OpenFOAM sampled slices)
using PyVista/VTK and exports per-slice data to MATLAB .mat files plus a
summary CSV for quick inspection.

Usage (from workspace root):
  C:/Users/ydebray/Downloads/cfd/.venv/Scripts/python.exe scripts/parse_vtp_slices.py \
      drivaer/drivaer_data/run_1/slices output/slices_mat
"""

from __future__ import annotations
import sys
import re
import os
import math
from pathlib import Path
import numpy as np
import pyvista as pv
from scipy.io import savemat
import csv

SLICE_PATTERN = re.compile(r"xNormal_([mp])(\d{5})", re.IGNORECASE)

def slice_location_from_name(name: str) -> float:
    """Derive x-location from slice filename convention xNormal_m01000.vtp.
    Assumes digits represent value scaled by 10000.
    m -> negative, p -> positive.
    """
    stem = Path(name).stem
    m = SLICE_PATTERN.search(stem)
    if not m:
        return math.nan
    sign = -1.0 if m.group(1).lower() == 'm' else 1.0
    raw = float(m.group(2))
    return sign * raw / 10000.0

def process_vtp_file(path: Path, out_dir: Path) -> dict:
    mesh = pv.read(path)
    out = {}
    # Points
    pts = np.asarray(mesh.points)  # (N,3)
    out['points'] = pts
    # Point data arrays
    for name, arr in mesh.point_data.items():
        out[name] = np.asarray(arr)
        # If vector (N,3) ensure 2D
    # Cell data (optional)
    for name, arr in mesh.cell_data.items():
        out[f'cell_{name}'] = np.asarray(arr)
    # Derived quantities
    if 'U' in out and out['U'].ndim == 2 and out['U'].shape[1] == 3:
        U = out['U']
        out['Umag'] = np.linalg.norm(U, axis=1)
    # Save mat
    loc = slice_location_from_name(path.name)
    out['slice_x'] = loc
    mat_name = path.stem + '.mat'
    savemat(out_dir / mat_name, out, do_compression=True)
    return out

def main():
    if len(sys.argv) < 3:
        print("Usage: python parse_vtp_slices.py <slice_dir> <output_dir>")
        sys.exit(1)
    slice_dir = Path(sys.argv[1]).resolve()
    out_dir = Path(sys.argv[2]).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    files = sorted(slice_dir.glob('xNormal_*.vtp'))
    if not files:
        print(f"No slice files found in {slice_dir}")
        sys.exit(1)
    summary_rows = []
    for f in files:
        try:
            data = process_vtp_file(f, out_dir)
            row = {
                'file': f.name,
                'x': data['slice_x'],
                'nPoints': data['points'].shape[0],
            }
            if 'Umag' in data:
                row['meanUmag'] = float(np.mean(data['Umag']))
            if 'p' in data:
                p = data['p']
                row['meanP'] = float(np.mean(p))
            summary_rows.append(row)
            print(f"Processed {f.name} (x={row['x']:.4f}, points={row['nPoints']})")
        except Exception as e:
            print(f"ERROR processing {f}: {e}")
    # Write summary CSV
    csv_path = out_dir / 'slice_summary.csv'
    fieldnames = ['file','x','nPoints','meanUmag','meanP']
    with open(csv_path,'w',newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        for r in summary_rows:
            w.writerow(r)
    print(f"Summary written to {csv_path}")

if __name__ == '__main__':
    main()
