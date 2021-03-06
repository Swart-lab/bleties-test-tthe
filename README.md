Benchmarking BleTIES with Tetrahymena read data
===============================================

MIC enrichment from Tetrahymena thermophila, used to test performance of
BleTIES with both PacBio Sequel I subreads and Nanopore MinION long reads, and
compared against published IES sequences.

This repository supplements our
[preprint](https://www.biorxiv.org/content/10.1101/2021.05.18.444610v1)
describing the [BleTIES](https://github.com/Swart-lab/bleties) software.


Source data and setup
---------------------

Read metadata are listed in files `read_*_data.tsv`.

Run script `download_data.sh` to prepare directories and download reads and
reference genomes.

Install BleTIES with Conda:

```bash
git clone git@github.com:Swart-lab/bleties.git
conda env create -f bleties/env.yaml -p ./envs/bleties_env
conda activate ./envs/bleties_env
cd bleties
pip install .
```


Analysis
--------

Run script `do_bleties.sh` to map long reads to reference MAC genome with
minimap2, and use BleTIES to reconstruct IESs. Edit script to specify paths on
your system.

Analysis is documented in the following Jupyter notebooks: 

 * `Compare_BleTIES_PacBio_Nanopore_predictions.ipynb` - Main notebook
 * `Check_reported_intragenic_IESs.ipynb` - Check whether intragenic IESs
   reported by Hamilton et al. (2016) are also assembled by BleTIES
 * `Clips_vs_inserts_at_non-predicted_IESs.ipynb` - Look for clips/inserts at
   known IES junctions where BleTIES did not predict an IES
