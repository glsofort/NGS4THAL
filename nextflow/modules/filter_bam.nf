process FILTER_BAM {
    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(bed)

    output:
    tuple val(meta), path(out_bam), path(out_bai)

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    out_bam = "${prefix}.bam"
    out_bai = "${prefix}.bam.bai"

    """
    samtools view -h -L ${bed} -b -o ${out_bam} ${in_bam}
    samtools index ${out_bam}
    """
}