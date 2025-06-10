process PINDEL {
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
    path(output),  emit: bd_causal

    script:
    def fasta                   = meta.fasta
    def prefix                  = task.ext.prefix ?: "${meta.id}"
    def threads                 = task.cpus
    def sample_id               = meta.id
    
    def pd_config               = "pd.cfg"
    def matching_bp_script      = "matching_breakpoint.py"

    def bd_pindel_chr16_output  = "BD_Pindel_chr16.out"
    def bd_pindel_chr11_output  = "BD_Pindel_chr11.out"

    def pindel_del_chr16_pre    = "Pindel_Deletion.chr16.pre"
    def pindel_del_chr11_pre    = "Pindel_Deletion.chr11.pre"


    pindel_causal_chr16_del     = "Pindel_Causal_chr16_Deletion.pre"
    pindel_causal_chr11_del     = "Pindel_Causal_chr11_Deletion.pre"
    output                      = "PD_Causal.pre"

    """
    # Generate Pindel configure file
    echo "${in_bam}\t400\t${sample_id}" > ${pd_config}

    # Run Pindel for chromosome 16
    pindel -f ${fasta} \
        -i ${pd_config} \
        -c 16 \
        -b ${bd_pre} \
        -o ${bd_pindel_chr16_output} \
        -r false \
        -t false \
        -l false \
        -k

    # Run Pindel for chromosome 11
    pindel -f ${fasta} \
        -i ${pd_config} \
        -c 11 \
        -b ${bd_pre} \
        -o ${bd_pindel_chr11_output} \
        -r false \
        -t false \
        -l false \
        -k

    # Focus on deletion only
    awk 'BEGIN{print "chr\tpos1\tpos2\tsize\tDeletion_with_support_Reads\tsample_name"}'  > ${pindel_del_chr16_pre}
    awk 'BEGIN{print "chr\tpos1\tpos2\tsize\tDeletion_with_support_Reads\tsample_name"}'  > ${pindel_del_chr11_pre}

    awk '{if(/BP_range/ && (\$11-\$10 >100)){print}}' ${bd_pindel_chr16_output}_D | \
        awk -v sname=${sample_id} '
        {
            if(\$16 >= 5){
                print \$8"\t"\$10"\t"\$11"\t"\$11-\$10"\t"\$16"\t"sname;
            }
        }' >> ${pindel_del_chr16_pre}

    awk '{if(/BP_range/ && (\$11-\$10 >100)){print}}' ${bd_pindel_chr11_output}_D | \
        awk -v sname=${sample_id} '
        {
            if(\$16 >= 5){
                print \$8"\t"\$10"\t"\$11"\t"\$11-\$10"\t"\$16"\t"sname;
            }
        }' >> ${pindel_del_chr11_pre}

    # Find exact mathed SVs
    # For chromosome 16
    python3 ${matching_bp_script} -knownbed ${known_SV_bed} -bed ${pindel_del_chr16_pre} -outbed ${pindel_causal_chr16_del}

    # For chromosome 11
    python3 ${matching_bp_script} -knownbed ${known_SV_bed} -bed ${pindel_del_chr11_pre} -outbed ${pindel_causal_chr11_del}

    touch ${output}
    """
}