process REALIGNED_BAM {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(scripts_dir)

    output:
    tuple val(meta), path(out_bam), path(out_bai), emit: bam

    script:
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def threads = task.cpus
    def script  = "Thalassemia.py"

    out_bam = "${prefix}.bam"
    out_bai = "${prefix}.bam.bai"

    """
    python3 ${script} --bamfile ${in_bam} --output ${out_bam}
    """
}