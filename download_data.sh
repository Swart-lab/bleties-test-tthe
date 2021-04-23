#!/bin/bash
set -e

case "$1" in

  "get_read_urls")
    # SRR10178226-SRR10178234
    # skip SRR10178231 which is Illumina data
    for i in {26..30} 32; do
      echo "SRR101782${i}"
      wget -O tmp "http://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR101782${i}&result=read_run"
      tail -n1 tmp >> read_pb_data.tsv
      # echo "http://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR101782${i}&result=read_run"
    done
    # Nanopore data
    for i in 33 34; do
      echo "SRR101782${i}"
      wget -O tmp "http://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR101782${i}&result=read_run"
      tail -n1 tmp >> read_ont_data.tsv
      # echo "http://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR101782${i}&result=read_run"
    done
    # Illumina data
    wget -O tmp "http://www.ebi.ac.uk/ena/portal/api/filereport?accession=SRR10178231&result=read_run"
    tail -n1 tmp >> read_ngs_data.tsv
    ;;

  "download_pb")
    mkdir -p reads-pb
    cd reads-pb
    for i in $(cut -f2 ../read_pb_data.tsv); do
      echo $i
      BN=$(basename $i)
      echo $BN
      wget --no-clobber $i
    done
    ;;

  "download_ont")
    mkdir -p reads-ont
    cd reads-ont
    for i in $(cut -f2 ../read_ont_data.tsv); do
      echo $i
      BN=$(basename $i)
      echo $BN
      wget --no-clobber $i
    done
    ;;

  "download_ngs")
    mkdir -p reads-ngs
    cd reads-ngs
    for i in $(cat ../read_ngs_data.tsv | cut -f2 | sed 's/;/ /g'); do
      echo $i
      BN=$(basename $i)
      echo $BN
      wget --no-clobber $i
    done
    ;;

  "download_ref")
    # Reference assembly Tetrahymena thermophila MAC version 2021
    mkdir -p ref
    cd ref
    wget http://www.ciliate.org/system/downloads/1-upd-Genome-assembly.fasta
    wget http://www.ciliate.org/system/downloads/2-upd-Genome-GFF3-latest-2.gff3
    wget http://www.ciliate.org/system/downloads/3-upd-cds-fasta-2021.fasta
    wget http://www.ciliate.org/system/downloads/4-upd-Protein-fasta-2021.fasta
    wget http://www.ciliate.org/system/downloads/5-upd-Gene-fasta-2021.fasta
    ;;

  *)
    echo "Subcommands:"
    echo "  get_read_urls"
    echo "  download_pb"
    echo "  download_ont"
    echo "  download_ngs"
  exit 1

esac
