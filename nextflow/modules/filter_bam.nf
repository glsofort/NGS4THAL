process FILTER_BAM {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(bed)

    output:
    tuple val(meta), path(out_bam), path(out_bai), emit: bam

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def threads = task.cpus

    out_bam = "${prefix}.bam"
    out_bai = "${prefix}.bam.bai"

    """
    samtools view -@ ${threads} -h -L ${bed} -b -o ${out_bam} ${in_bam}
    samtools index -@ ${threads} ${out_bam}
    """
}