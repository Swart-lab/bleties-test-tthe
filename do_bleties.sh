#!/bin/bash
set -e

# Map PacBio and Nanopore long reads and run BleTIES with Tetrahymena MIC
# enrichment libraries to benchmark BleTIES with real model organism data

# Environment variables -------------------------------------------------------
# Path to working folder
WD=/ebio/abt2_projects/small_projects/kbseah/tetrahymena_test_bleties
# Conda environment for BleTIES
ENV=${WD}/envs/bleties_env
# Path to Minimap2 binary
MINIMAP2=/ebio/abt2_projects/small_projects/kbseah/paramecium_simreads_test_bleties/opt/minimap2/minimap2
# Path to ParaFly
PARAFLY=/ebio/abt2_projects/ag-swart-blepharisma/software/parafly-r2013-01-21/bin/ParaFly
# Path to MAC reference genome
MAC_REF=ref/1-upd-Genome-assembly.fasta
# Num threads for tasks
THREADS=16

# ------------------------------------------------------------------------------

case "$1" in

  "minimap_ont")
    source activate $ENV
    for LIB in SRR10178233 SRR10178234; do
      $MINIMAP2 -ax map-ont -t 16 \
      $MAC_REF reads_ont/${LIB}_1.fastq.gz \
      | samtools view -u \
      | samtools sort --reference $MAC_REF \
      > mapping_ont/${LIB}_1.Tthe_MAC_upd.minimap2.sort.bam
      samtools index mapping_ont/${LIB}_1.Tthe_MAC_upd.minimap2.sort.bam
    done
  ;;

  "merge_mapped_ont")
    source activate $ENV
    ls mapping_ont/SRR*.Tthe_MAC_upd.minimap2.sort.bam > mapping_ont/mapping_ont.fofn
    samtools merge -b mapping_ont/mapping_ont.fofn mapping_ont/ont.Tthe_MAC_upd.minimap.bam
    samtools sort mapping_ont/ont.Tthe_MAC_upd.minimap.bam \
      > mapping_ont/ont.Tthe_MAC_upd.minimap.sort.bam
    samtools index mapping_ont/ont.Tthe_MAC_upd.minimap.sort.bam
  ;;

  "minimap_pb")
    source activate $ENV
    for LIB in SRR10178226 SRR10178227 SRR10178228 SRR10178229 SRR10178230 SRR10178232; do
      $MINIMAP2 -ax map-pb -t 16 \
      $MAC_REF reads_pb_clr/${LIB}_subreads.fastq.gz \
      | samtools view -u \
      | samtools sort --reference $MAC_REF \
      > mapping_pb/${LIB}_subreads.Tthe_MAC_upd.minimap2.sort.bam
      samtools index mapping_pb/${LIB}_subreads.Tthe_MAC_upd.minimap2.sort.bam
    done
  ;;

  "merge_mapped_pb")
    source activate $ENV
    ls mapping_pb/SRR*.Tthe_MAC_upd.minimap2.sort.bam > mapping_pb/mapping_pb.fofn
    samtools merge -b mapping_pb/mapping_pb.fofn mapping_pb/pb_subreads.Tthe_MAC_upd.minimap.bam
    samtools sort mapping_pb/pb_subreads.Tthe_MAC_upd.minimap.bam \
      > mapping_pb/pb_subreads.Tthe_MAC_upd.minimap.sort.bam
    samtools index mapping_pb/pb_subreads.Tthe_MAC_upd.minimap.sort.bam
  ;;


  "make_cmds_pb")
    # Make commands for BleTIES per contig to parallelize
    for CTG in $(grep '>' $MAC_REF | sed 's/>//'); do
    echo "bleties --log bleties_pb/logs/bleties_milraa.${CTG}.log \
     milraa --bam ${WD}/mapping_pb/pb_subreads.Tthe_MAC_upd.minimap.sort.bam \
     --ref $MAC_REF --contig $CTG --type subreads \
     --min_break_coverage 10 --min_del_coverage 10 --subreads_pos_max_cluster_dist 5 \
     --dump --out ${WD}/bleties_pb/tthe_pb_clr.milraa_subreads.$CTG \
     > ${WD}/bleties_pb/logs/bleties_pb.${CTG}.stdout \
     2> ${WD}/bleties_pb/logs/bleties_pb.${CTG}.stderr" >> bleties_cmds
    done
    ;;

  "run_parafly_pb")
    # Run BleTIES in parallel with ParaFly
    source activate $ENV
    $PARAFLY -c bleties_cmds -CPU $THREADS \
      -shuffle -failed_cmds bleties_cmds.failed
    ;;

  "merge_bleties_pb")
    cat bleties_pb/tthe_pb_clr.milraa_subreads.*.milraa_ies.fasta > tthe_pb_clr.milraa_subreads.comb.milraa_ies.fasta
    cat bleties_pb/tthe_pb_clr.milraa_subreads.*.milraa_ies.gff3 | grep -v '#' > tthe_pb_clr.milraa_subreads.comb.milraa_ies.gff3
    ;;

  "make_cmds_ont")
    # Make commands
    for CTG in $(grep '>' $MAC_REF | sed 's/>//'); do
    echo "bleties --log bleties_ont/logs/bleties_milraa.${CTG}.log \
     milraa --bam ${WD}/mapping_ont/ont.Tthe_MAC_upd.minimap.sort.bam \
     --ref $MAC_REF --contig $CTG --type subreads \
     --min_break_coverage 10 --min_del_coverage 10 --subreads_pos_max_cluster_dist 5 \
     --dump --out ${WD}/bleties_ont/tthe_ont.milraa_subreads.$CTG \
     > ${WD}/bleties_ont/logs/bleties_ont.${CTG}.stdout \
     2> ${WD}/bleties_ont/logs/bleties_ont.${CTG}.stderr" >> bleties_ont_cmds
    done
    ;;

  "run_parafly_ont")
    source activate $ENV
    $PARAFLY -c bleties_ont_cmds -CPU $THREADS \
      -shuffle -failed_cmds bleties_ont_cmds.failed
    ;;

  "merge_bleties_ont")
    cat bleties_ont/tthe_ont.milraa_subreads.*.milraa_ies.fasta > tthe_ont.milraa_subreads.comb.milraa_ies.fasta
    cat bleties_ont/tthe_ont.milraa_subreads.*.milraa_ies.gff3 | grep -v '#' > tthe_ont.milraa_subreads.comb.milraa_ies.gff3
    ;;

  "cleanup")
    tar -czf bleties_pb.tar.gz bleties_pb
    tar -czf bleties_ont.tar.gz bleties_ont
    ;;

  *)
    echo "Subcommands:"
    echo "  minimap_ont"
    echo "  merge_mapped_ont"
    echo "  minimap_pb"
    echo "  merge_mapped_pb"
    echo "  make_cmds_pb"
    echo "  run_parafly_pb"
    echo "  merge_bleties_pb"
    echo "  make_cmds_ont"
    echo "  run_parafly_ont"
    echo "  merge_bleties_ont"
    exit 1

esac
