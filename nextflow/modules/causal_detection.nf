process CAUSAL_DETECTION {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(snp_in_vcf_gz), path(snp_in_vcf_tbi)
    tuple val(meta), path(indel_in_vcf_gz), path(indel_in_vcf_tbi)
    path(fasta_dir)
    path(script_dir)
    path(sorted_causal_snv_vcf)
    path(sorted_causal_indel_vcf)

    output:
    path("Thalassaemia.INDEL.PRE")

    script:
    def fasta               = meta.fasta
    def prefix              = task.ext.prefix ?: "${meta.id}"
    def threads             = task.cpus
    
    def find_causal_script  = "find_causal.py"

    def high_qual_vcf       = "high_quality.vcf"
    def high_qual_norm_vcf  = "high_quality.norm.vcf"

    def out_diff_sites      = "out.diff.sites_in_files"

    def indel_norm_hq       = "indel.normed"
    def indel_norm_hq_vcf   = "${indel_norm_hq}.recode.vcf"

    def snp_position_list   = "snp.positions.txt"
    def snp_cand_prefix     = "snp.candidate"
    def snp_cand_vcf        = "${snp_cand_prefix}.recode.vcf"

    def indel_position_list   = "indel.positions.txt"
    def indel_cand_prefix     = "indel.candidate"
    def indel_cand_vcf        = "${indel_cand_prefix}.recode.vcf"

    def snp_out_prefix      = "${prefix}.snp"
    def indel_out_prefix    = "${prefix}.indel"

    def snp_outdir          = "SNP-out"
    def indel_outdir        = "INDEL-out"

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
          --diff ${sorted_causal_snv_vcf} \
          --diff-site \
          --chr 11 \
          --chr 16

    awk '{if(\$2==\$3){print \$1,\$2}}' ${out_diff_sites} > ${snp_position_list}

    vcftools --vcf ${high_qual_norm_vcf} \
        --positions ${snp_position_list} \
        --out ${snp_cand_prefix} \
        --recode \
        --recode-INFO-all

    python3 ${find_causal_script} -input ${snp_cand_vcf} -mutation "SNP" -knowncausal ${sorted_causal_snv_vcf} -outdir ${snp_outdir}

    cat ${snp_outdir}/pre* > Thalassaemia.SNP.PRE

    ######################Causal InDels####################
    vcftools --vcf ${high_qual_norm_vcf} \
            --keep-only-indels \
            --recode \
            --recode-INFO-all \
            --out ${indel_norm_hq}

    awk 'NR==FNR{if(/#/){}else {a[\$1"_"\$2]=\$3}} NR>FNR{if(/#/){}else{if(a[\$1"_"\$2]){print \$1, \$2}}}' ${sorted_causal_indel_vcf} ${indel_norm_hq_vcf} > ${indel_position_list}


    vcftools --vcf ${high_qual_norm_vcf} --positions ${indel_position_list} --out ${indel_cand_prefix} --recode --recode-INFO-all

    python3 ${find_causal_script} -input ${indel_cand_vcf} -mutation "InDel" -knowncausal ${sorted_causal_indel_vcf} -outdir ${indel_outdir}

    cat ${indel_outdir}/pre* > Thalassaemia.INDEL.PRE
    """
}