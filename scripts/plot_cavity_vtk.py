"""Plot VTK files in cavity/VTK using PyVista.

Usage (Windows cmd):
    python -m venv .venv
    .venv\Scripts\activate
    pip install -r requirements.txt
    python scripts\plot_cavity_vtk.py --input-dir cavity\VTK --output-dir output\vtk_plots --var U

Arguments:
    --input-dir    Directory containing .vtk files (default: cavity/VTK)
    --output-dir   Directory to write plot images (default: output/vtk_plots)
    --var          Name of variable to plot; if omitted, will try to derive.
    --list-only    Only list arrays found per file (no plotting).

Behavior:
 - Attempts to find the requested variable in point or cell data.
 - If the variable is vector data (e.g. velocity U) magnitude is plotted.
 - If no --var provided, prefers velocity magnitude (U) if present, else first scalar.
 - Writes PNG images and a JSON summary of arrays per file.
"""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import pyvista as pv


def discover_vtk_files(directory: Path) -> List[Path]:
    return sorted([p for p in directory.glob("*.vtk") if p.is_file()], key=lambda x: x.name)


def extract_step(filename: str) -> Optional[int]:
    m = re.search(r"(\d+)", filename)
    return int(m.group(1)) if m else None


def choose_variable(mesh: pv.DataSet, preferred: Optional[str]) -> (str, np.ndarray, bool):
    point_names = list(mesh.point_data.keys())
    cell_names = list(mesh.cell_data.keys())
    all_names = point_names + cell_names

    # Helper to fetch array
    def get_array(name: str) -> np.ndarray:
        if name in mesh.point_data:
            return mesh.point_data[name]
        return mesh.cell_data[name]

    if preferred and preferred in all_names:
        arr = get_array(preferred)
        return preferred, arr, arr.ndim == 2 and arr.shape[1] in (2, 3)

    # Try common velocity variable names
    for cand in ["U", "velocity", "Velocity"]:
        if cand in all_names:
            arr = get_array(cand)
            return cand, arr, arr.ndim == 2 and arr.shape[1] in (2, 3)

    # Fallback: first scalar
    for name in all_names:
        arr = get_array(name)
        if arr.ndim == 1:
            return name, arr, False
        if arr.ndim == 2 and arr.shape[1] in (2, 3):
            return name, arr, True
    raise RuntimeError("No plottable arrays found in mesh.")


def ensure_output_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def plot_mesh_scalar(mesh: pv.DataSet, scalars: np.ndarray, scalar_name: str, title: str, output_path: Path):
    # Attach scalars temporarily
    mesh_copy = mesh.copy()
    mesh_copy[scalar_name] = scalars
    plotter = pv.Plotter(off_screen=True)
    plotter.add_mesh(mesh_copy, scalars=scalar_name, cmap="viridis", show_scalar_bar=True)
    plotter.add_title(title, font_size=12)
    plotter.background_color = "white"
    plotter.show(screenshot=str(output_path))


def main():
    parser = argparse.ArgumentParser(description="Plot cavity VTK files.")
    parser.add_argument("--input-dir", default="cavity/VTK", help="Directory containing .vtk files")
    parser.add_argument("--output-dir", default="output/vtk_plots", help="Directory for plots")
    parser.add_argument("--var", default=None, help="Variable name to plot")
    parser.add_argument("--list-only", action="store_true", help="Only list variables, no plots")
    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    if not input_dir.exists():
        raise SystemExit(f"Input directory not found: {input_dir}")

    files = discover_vtk_files(input_dir)
    if not files:
        raise SystemExit(f"No .vtk files found in {input_dir}")

    output_dir = Path(args.output_dir)
    ensure_output_dir(output_dir)

    metadata: Dict[str, Dict[str, List[str]]] = {}

    for f in files:
        try:
            mesh = pv.read(f)
        except Exception as e:
            print(f"Failed to read {f.name}: {e}")
            continue

        point_arrays = list(mesh.point_data.keys())
        cell_arrays = list(mesh.cell_data.keys())
        metadata[f.name] = {"point_data": point_arrays, "cell_data": cell_arrays}

        print(f"File: {f.name}")
        print(f"  Point data arrays: {point_arrays}")
        print(f"  Cell data arrays:  {cell_arrays}")

        if args.list_only:
            continue

        try:
            var_name, arr, is_vector = choose_variable(mesh, args.var)
        except RuntimeError as e:
            print(f"Skipping {f.name}: {e}")
            continue

        if is_vector:
            mag = np.linalg.norm(arr, axis=1)
            scalar_name = f"{var_name}_mag"
        else:
            mag = arr
            scalar_name = var_name

        step = extract_step(f.name)
        title = f"{scalar_name} (step {step})" if step is not None else scalar_name
        out_file = output_dir / f"{f.stem}_{scalar_name}.png"

        try:
            plot_mesh_scalar(mesh, mag, scalar_name, title, out_file)
            print(f"  Saved plot -> {out_file}")
        except Exception as e:
            print(f"  Plot failed for {f.name}: {e}")

    # Write summary JSON
    summary_path = output_dir / "arrays_summary.json"
    with summary_path.open("w", encoding="utf-8") as fh:
        json.dump(metadata, fh, indent=2)
    print(f"Array summary written to {summary_path}")

    if args.list_only:
        print("Listing only; rerun without --list-only to create plots.")


if __name__ == "__main__":
    main()
