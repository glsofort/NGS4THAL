process HARD_FILTERING {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_vcf_gz), path(in_vcf_tbi)

    output:
    tuple val(meta), path(snp_out_vcf_gz), path(snp_out_vcf_tbi), emit: snp_vcf
    tuple val(meta), path(indel_out_vcf_gz), path(indel_out_vcf_tbi), emit: indel_vcf

    script:
    def fasta               = meta.fasta
    def prefix              = task.ext.prefix ?: "${meta.id}"
    def threads             = task.cpus

    // SNP
    def snp_prefix          = "${prefix}.snp"
    def snp_recode_vcf      = "${snp_prefix}.recode.vcf"
    def snp_filtered        = "${snp_prefix}.filtered.vcf"
    def snp_filtered_gz     = "${snp_filtered}.gz"

    // INDEL
    def indel_prefix        = "${prefix}.indel"
    def indel_recode_vcf    = "${indel_prefix}.recode.vcf"
    def indel_filtered      = "${prefix}.filtered.vcf"
    def indel_filtered_gz   = "${indel_filtered}.gz"


    def snp_out_prefix      = "${snp_prefix}.final"
    def indel_out_prefix    = "${indel_prefix}.final"

    snp_out_vcf             = "${snp_out_prefix}.recode.vcf"
    snp_out_vcf_gz          = "${snp_out_vcf}.gz"
    snp_out_vcf_tbi         = "${snp_out_vcf}.gz.tbi"

    indel_out_vcf           = "${indel_out_prefix}.recode.vcf"
    indel_out_vcf_gz        = "${indel_out_vcf}.gz"
    indel_out_vcf_tbi       = "${indel_out_vcf}.gz.tbi"

    """
    # Split joint VCF
    vcftools --gzvcf ${in_vcf_gz} \
        --remove-indels \
        --recode \
        --recode-INFO-all \
        --out ${snp_prefix}

    vcftools --gzvcf ${in_vcf_gz} \
        --keep-only-indels \
        --recode-INFO-all \
        --recode \
        --out ${indel_prefix}

    # SNP hard filtering
    bcftools filter \
        -e "QD < 2.0 || MQ < 40.0 || FS > 60.0 || SOR > 3.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
        -s "FAILED" \
        -m+ \
        -Ov \
        -o ${snp_filtered} \
        ${snp_recode_vcf}

    # INDEL hard filtering
    bcftools filter \
        -e "QD < 2.0 || ReadPosRankSum < -8.0 || FS > 200.0 || SOR > 10.0" \
        -s "FAILED" \
        -m+ \
        -Ov \
        -o ${indel_filtered} \
        ${indel_recode_vcf}

    # Create final result
    vcftools --vcf ${snp_filtered} \
        --remove-filtered-all \
        --recode \
        --recode-INFO-all \
        --out ${snp_out_prefix}

    bgzip -cf ${snp_out_vcf} > ${snp_out_vcf_gz}
    tabix ${snp_out_vcf_gz}

    vcftools --vcf ${indel_filtered} \
        --remove-filtered-all \
        --recode \
        --recode-INFO-all \
        --out ${indel_out_prefix}

    bgzip -cf ${indel_out_vcf} > ${indel_out_vcf_gz}
    tabix ${indel_out_vcf_gz}
    """
}