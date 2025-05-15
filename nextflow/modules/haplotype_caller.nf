process HAPLOTYPE_CALLER {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'
    label 'sentieon'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    tuple path(dbsnp), path(dbsnp_index)
    path(fasta_dir)
    path(sentieon_dir)

    output:
    tuple val(meta), path(out_vcf_gz), path(out_vcf_tbi), emit: gvcf

    script:
    def fasta       = meta.fasta
    def prefix      = task.ext.prefix ?: "${meta.id}"
    def threads     = task.cpus
    def sentieon    = "${sentieon_dir}/bin/sentieon"

    out_vcf         = "${prefix}.vcf"
    out_vcf_gz      = "${prefix}.vcf.gz"
    out_vcf_tbi     = "${prefix}.vcf.gz.tbi"

    """
    ${sentieon} driver \
        -t ${threads} \
        -r ${fasta} \
        -i ${in_bam} \
        --algo Haplotyper \
        --emit_mode gvcf \
        --dbsnp ${dbsnp} \
        ${out_vcf_gz}
    """
}