process CASUAL_DETECTION {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(snp_in_vcf_gz), path(snp_in_vcf_tbi)
    tuple val(meta), path(indel_in_vcf_gz), path(indel_in_vcf_tbi)
    path(fasta_dir)
    path(script_dir)
    path(sorted_casual_snv_vcf)
    path(sorted_casual_indel_vcf)

    output:
    path("123")

    script:
    def fasta               = meta.fasta
    def prefix              = task.ext.prefix ?: "${meta.id}"
    def threads             = task.cpus
    
    def find_casual_script  = "find_casual.py"

    def high_qual_vcf       = "high_quality.vcf"
    def high_qual_norm_vcf  = "high_quality.norm.vcf"

    def out_diff_sites      = "out.diff.sites_in_files"

    def snp_position_list   = "snp.positions.txt"
    def snp_cand_prefix     = "snp.candidate"
    def snp_cand_vcf        = "${snp_cand_prefix}.recode.vcf"

    def snp_out_prefix      = "${prefix}.snp"
    def indel_out_prefix    = "${prefix}.indel"

    snp_out_vcf             = "${snp_out_prefix}.recode.vcf"
    snp_out_vcf_gz          = "${snp_out_vcf}.gz"
    snp_out_vcf_tbi         = "${snp_out_vcf}.gz.tbi"

    indel_out_vcf           = "${indel_out_prefix}.recode.vcf"
    indel_out_vcf_gz        = "${indel_out_vcf}.gz"
    indel_out_vcf_tbi       = "${indel_out_vcf}.gz.tbi"

    """
    # Merge SNP & INDEL to get the high quality variants
    bcftools concat -a ${snp_in_vcf_gz} ${indel_in_vcf_gz} | \
    bcftools sort -o ${high_qual_vcf}

    # Normalization
    bcftools norm \
        -m -"both" \
        --fasta-ref ${fasta} \
        ${high_qual_vcf} \
        -o ${high_qual_norm_vcf}
    
    #############Causal SNV mutation################
    vcftools --vcf ${high_qual_norm_vcf} \
          --diff ${sorted_casual_snv_vcf} \
          --diff-site \
          --not-chr 2 \
          --not-chr 6 \
          --not-chr X \
          --not-chr 19

    awk '{if(\$2==\$3){print \$1,\$2}}' ${out_diff_sites} > ${snp_position_list}

    vcftools --vcf ${high_qual_norm_vcf} \
        --positions ${snp_position_list} \
        --out ${snp_cand_prefix} \
        --recode \
        --recode-INFO-all

    python3 ${find_casual_script} -input ${snp_cand_vcf} -mutation "SNP" -knowncasual ${sorted_casual_snv_vcf}

    touch 123
    """
}