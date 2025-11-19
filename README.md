# Cellpose Tracking Export Pipeline

Complete workflow for cell segmentation and tracking with persistent cell IDs.

## Workflow

### Step 1: Segmentation with Cellpose
**Notebook:** `01_cellpose_ultrack_qc_colab.ipynb`

- Cellpose-SAM segmentation with QC
- Export for TrackMate and ultrack
- Quality control visualizations

### Step 2: Persistent ID Tracking
**Notebook:** `02_cellpose_persistent_id_tracking.ipynb`


- Persistent Cell IDs
- Centroid-Based Tracking
- Hungarian Algorithm
- Cell Event Detection
- Trajectory Analysis



## Use Cases

- Time-lapse microscopy analysis
- Cell division tracking
- Migration pattern studies
- Fourier analysis of cell dynamics
- Spatial-temporal analysis



# Cellpose Enhanced QC & Tracking Export Pipeline

Modified Cellpose-SAM workflow with quality control features and enhanced export compatibility for tracking tools (TrackMate-FIJI and ultrack).

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/YOUR-USERNAME/cellpose-tracking-export/blob/main/notebooks/cellpose_enhanced_qc.ipynb)

## Overview

This pipeline extends the Cellpose-SAM segmentation workflow with specialized outputs for downstream tracking analysis. It maintains the powerful segmentation capabilities of Cellpose while adding structured data export formats required by modern tracking tools.

## 🆕 Key Modifications & Improvements

### 1. TrackMate-FIJI Compatible Export
- **3D TIFF stack generation** (`masks_stack.tif`) with proper ImageJ metadata
- Correct TYX axis ordering for time-series analysis
- Individual mask frames preserved for flexibility
- Direct import into TrackMate without additional preprocessing

### 2. ultrack Pipeline Preparation
Complete data package for ultrack tracking workflow:

**Generated outputs:**
- **Segmentation masks** - 3D stack format for temporal analysis
- **Detection properties CSV** - Centroids, areas, bounding boxes per object
- **Raw image stack** - Original data for appearance-based tracking
- **Optical flow fields** - Motion vectors derived from Cellpose flows
- **Detection confidence scores** - From Cellpose probability maps

These files provide ultrack with:
- Object centroids and morphological properties for linking
- Motion prediction vectors for trajectory optimization
- Confidence metrics for handling detection uncertainty
- Appearance features for robust identity assignment

### 3. Quality Control Enhancements
- Interactive parameter adjustment and re-segmentation
- Side-by-side visualization (raw image vs. segmentation overlay)
- Comprehensive analysis plots (cell count, size distributions, quality metrics)
- Detailed summary statistics and export information
- Visual inspection tools for segmentation validation

### 4. Robustness Improvements
- Enhanced file sorting to ensure correct temporal order
- Error handling for various image formats
- Metadata preservation across processing steps
- Automated directory organization for downstream analysis

## Output Structure

After processing, the pipeline generates:
```
output_folder/
├── masks/                          # Individual segmentation frames
│   ├── frame_000_masks.tif
│   ├── frame_001_masks.tif
│   └── ...
├── masks_stack.tif                # 3D stack (TrackMate-ready)
├── ultrack_data/                  # Complete ultrack inputs
│   ├── masks_stack.tif           # Segmentation
│   ├── detections.csv            # Object properties
│   ├── raw_stack.tif             # Original images
│   ├── flow_stack.tif            # Motion vectors
│   ├── confidence_stack.tif      # Detection scores
│   └── ultrack_config_info.txt   # Data summary
└── qc_plots/                      # Quality control visualizations
    ├── segmentation_overlay.png
    ├── object_counts.png
    └── size_distributions.png
```

## Usage

### Option 1: Google Colab (Recommended - No Installation)

1. Click the "Open in Colab" badge above
2. Connect your Google Drive (for image access)
3. Follow the step-by-step notebook instructions
4. Download results back to your computer

**Advantages:**
- Free GPU acceleration
- No local installation required
- Easy sharing with collaborators

### Option 2: Local Jupyter Notebook
```bash
# Create conda environment
conda env create -f environment.yml
conda activate cellpose-tracking

# Launch notebook
jupyter notebook notebooks/cellpose_enhanced_qc.ipynb
```

### Option 3: Command Line (Advanced)
```bash
# For batch processing (if you create a script version)
python scripts/run_cellpose_tracking.py \
    --input images/ \
    --output results/ \
    --model cyto2 \
    --diameter 30
```

## Requirements

### For Google Colab:
- Google account (free tier sufficient)
- Images stored on Google Drive or available for upload
- ~2-5GB Drive space for outputs (depending on dataset size)

### For Local Installation:

**Python 3.8-3.10** with the following packages:
```yaml
# See environment.yml for complete specification
- cellpose>=2.0
- numpy
- scipy
- scikit-image
- tifffile>=2021.0.0
- matplotlib
- pandas
- jupyter
```

**Optional for tracking:**
- TrackMate (FIJI plugin)
- ultrack (`pip install ultrack`)

## Workflow

1. **Upload/Load Images**
   - Time-series or z-stacks
   - Supported formats: TIFF, ND2, PNG, etc.

2. **Configure Cellpose Parameters**
   - Select model (cyto, cyto2, nuclei, or custom)
   - Set approximate cell diameter
   - Adjust detection sensitivity

3. **Run Segmentation**
   - Automated processing with Cellpose-SAM
   - GPU acceleration (Colab) or CPU (local)

4. **Quality Control**
   - Visual inspection of segmentation overlays
   - Review statistics (cell counts, size distributions)
   - Adjust parameters if needed and re-run

5. **Export for Tracking**
   - Automatic generation of tracking-ready formats
   - Choose TrackMate and/or ultrack outputs

6. **Downstream Tracking**
   - **TrackMate:** Import `masks_stack.tif` directly
   - **ultrack:** Use complete `ultrack_data/` folder

## Downstream Analysis

### Using with TrackMate (FIJI)
```
1. Open FIJI
2. Plugins → Tracking → TrackMate
3. Import as: "Label image"
4. Select: masks_stack.tif
5. Continue with standard TrackMate workflow
```

### Using with ultrack
```python
import ultrack

# All required inputs are in ultrack_data/
config = ultrack.load_config("ultrack_data/ultrack_config_info.txt")
tracks = ultrack.track(
    masks="ultrack_data/masks_stack.tif",
    detections="ultrack_data/detections.csv",
    flows="ultrack_data/flow_stack.tif"
)
```

## Example Dataset

[Optional: Link to example images or demonstrate with sample data]
```python
# Test with Cellpose example data
from cellpose import utils
images = utils.download_example_data('example_cytoplasm')
```

## Troubleshooting

### Common Issues:

**"Out of memory" errors:**
- Reduce image size or process fewer frames at once
- Use Colab for GPU memory
- Lower model resolution

**Segmentation quality issues:**
- Adjust `diameter` parameter (critical!)
- Try different models (cyto vs. cyto2 vs. nuclei)
- Check image quality (contrast, noise)

**Export errors:**
- Verify sufficient disk space
- Check file permissions
- Ensure temporal ordering of input files

## Original Work & Attribution

This notebook is based on:

**Cellpose-SAM** by Marius Pachitariu, Michael Rariden, and Carsen Stringer  
📄 [Paper](https://www.biorxiv.org/content/10.1101/2025.04.28.651001v1) | 💻 [Code](https://github.com/MouseLand/cellpose)

**Adapted from:** Notebook by Pradeep Rajasekhar  
**Inspired by:** [ZeroCostDL4Mic](https://github.com/HenriquesLab/ZeroCostDL4Mic/wiki) notebook series

**Modifications:** Enhanced export formats, QC features, and tracking pipeline integration

## Citation

If you use this modified workflow in your research, please cite:

### This Modified Version:
```bibtex
@software{yourname2025cellpose_tracking,
  author = {Your Name},
  title = {Cellpose Enhanced QC and Tracking Export Pipeline},
  year = {2025},
  url = {https://github.com/YOUR-USERNAME/cellpose-tracking-export}
}
```

### Original Cellpose-SAM:
```bibtex
@article{pachitariu2025cellpose,
  title        = {Cellpose-SAM: superhuman generalization for cellular segmentation},
  author       = {Pachitariu, Marius and Rariden, Michael and Stringer, Carsen},
  journal      = {bioRxiv},
  year         = {2025},
  doi          = {10.1101/2025.04.28.651001},
  url          = {https://www.biorxiv.org/content/10.1101/2025.04.28.651001v1},
  publisher    = {Cold Spring Harbor Laboratory},
  note         = {bioRxiv preprint}
}
```

### Original Cellpose
```bibtex
@article{stringer2021cellpose,
  title        = {Cellpose: a generalist algorithm for cellular segmentation},
  author       = {Stringer, Carsen and Wang, Tim and Michaelos, Michalis and Pachitariu, Marius},
  journal      = {Nature Methods},
  volume       = {18},
  number       = {1},
  pages        = {100--106},
  year         = {2021},
  doi          = {10.1038/s41592-020-01018-x},
  publisher    = {Springer Nature}
}

## License

**This modified version:** CC BY 4.0  
**Original Cellpose code:** BSD-3-Clause ([see Cellpose repository](https://github.com/MouseLand/cellpose/blob/main/LICENSE))

This project builds upon open-source software. Modifications are shared under CC BY 4.0 to facilitate scientific collaboration while respecting the original BSD-3-Clause license of the underlying Cellpose codebase.

## Acknowledgments

- **Cellpose team** for the foundational segmentation algorithm
- **ZeroCostDL4Mic** for inspiration on accessible deep learning tools
- **Pradeep Rajasekhar** for the original Colab adaptation
- **TrackMate and ultrack developers** for excellent tracking frameworks

## Contributing

Found a bug or have a suggestion? Please open an issue!

Improvements welcome:
- Additional export formats
- New QC metrics
- Integration with other tracking tools
- Documentation improvements

## Author

**Your Name**  
[Your Institution]  
[Contact - optional: email or Twitter/LinkedIn]

Project Link: https://github.com/YOUR-USERNAME/cellpose-tracking-export

---

## Changelog

### Version 1.0.0 (2025-11)
- Initial release with TrackMate and ultrack export
- QC visualization enhancements
- Structured output organization
- Comprehensive documentation
