process CONIFER {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(bd_pre)
    path(pindel_scripts_dir)
    path(fasta_dir)
    path(known_SV_bed)

    output:
    path(output),  emit: pd_causal

    script:
    def fasta                   = meta.fasta
    def prefix                  = task.ext.prefix ?: "${meta.id}"
    def threads                 = task.cpus
    def sample_id               = meta.id
    
    def pd_config               = "pd.cfg"
    def conifer_script          = "matching_breakpoint.py"

    pindel_causal_chr16_del     = "Pindel_Causal_chr16_Deletion.pre"
    pindel_causal_chr11_del     = "Pindel_Causal_chr11_Deletion.pre"
    output                      = "PD_Causal.pre"

    """
    Calculate RPKM using Conifer
    python $CONIFER rpkm \
        --probes $PROBE_FILE \
        --input $Raw_Bam_file_folder/"$i"/"$i".bam \
        --output $cnvf/RPKM/"$i".rpkm.txt
    """
}