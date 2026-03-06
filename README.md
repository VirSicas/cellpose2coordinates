# Cellpose2Coordinates

Extract coordinates and tracking data from Cellpose segmentation with enhanced QC and export formats.



## Overview

Extends Cellpose-SAM segmentation with coordinate extraction and tracking-ready exports for TrackMate and ultrack.

**Three-notebook workflow:**
1. **Segmentation & Export** - Cellpose with QC and coordinate extraction
2. **Persistent ID Tracking** - Frame-to-frame cell tracking
3. **Tracking QC** - Validation and visualization

## Key Features

- **Coordinate extraction** from Cellpose masks (deterministic, no ML)
- **TrackMate export**: 3D TIFF stacks with ImageJ metadata
- **ultrack export**: Complete data package (masks, centroids, flows, confidence)
- **Persistent cell IDs** via Hungarian algorithm
- **Quality control** tools and visualizations

## Output Structure
```
output/
├── masks_stack.tif              # TrackMate-ready
├── ultrack_data/                # ultrack inputs
│   ├── detections.csv          # Coordinates & properties
│   ├── flow_stack.tif          # Motion vectors
│   └── confidence_stack.tif
└── tracked_results/
    └── persistent_ids.csv      # Cell IDs across frames
```

## Quick Start

### Google Colab (No Installation)
**[▶️ Open in Google Colab](https://colab.research.google.com/drive/YOUR-ACTUAL-COLAB-LINK-HERE)**

*Click above to run in your browser - no setup required!*

### Local Installation
```bash
git clone https://github.com/VirSicas/cellpose2coordinates.git
cd cellpose2coordinates
conda env create -f environment.yml
conda activate cellpose-tracking
jupyter notebook notebooks/01_cellpose_ultrack_qc_colab.ipynb
```

## Requirements

Python 3.8-3.10 with:
- cellpose >= 2.0
- scikit-image
- tifffile >= 2021.0.0
- pandas, numpy, matplotlib

See `environment.yml` for full list.

## Use Cases

- Time-lapse cell tracking
- Migration analysis
- Spatial-temporal dynamics
- High-content screening workflows

## Examples

Example data coming soon - see `examples/` folder for demonstration video.

## Attribution

Based on [Cellpose-SAM](https://www.biorxiv.org/content/10.1101/2025.04.28.651001v1) by Pachitariu et al. and original [Cellpose](https://doi.org/10.1038/s41592-020-01018-x) by Stringer et al.

Adapted from notebook by Pradeep Rajasekhar, inspired by [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic).

**Modifications**: Coordinate extraction, enhanced exports, QC features, persistent ID tracking.

## Citation
```bibtex
@software{silio2025cellpose2coords,
  author = {Silio, Virginia},
  title = {Cellpose2Coordinates: Coordinate Extraction and Tracking Export},
  year = {2025},
  url = {https://github.com/VirSicas/cellpose2coordinates}
}
```

Please also cite original Cellpose papers (see notebook documentation).

## License

Modified version: CC BY 4.0  
Original Cellpose: BSD-3-Clause

## Author

**Virginia Silio**  
UCL Centre for Cell & Molecular Dynamics  
GitHub: [@VirSicas](https://github.com/VirSicas)

---

*Version 1.0* - Cellpose segmentation → coordinate extraction → tracking export