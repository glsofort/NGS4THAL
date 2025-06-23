process BREAKDANCER {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(bd_scripts_dir)
    path(known_SV_bed)

    output:
    path(output),  emit: bd_causal
    path(bd_pre),  emit: bd_pre

    script:
    def prefix          = task.ext.prefix ?: "${meta.id}"
    def threads         = task.cpus
    def sample_id       = meta.id

    def bam2cfg_script          = "bam2cfg.pl"
    def modify_bd_config_script = "Modify_BD_config.py"
    def find_mrange_bd_script   = "Find_minimum_range_BreakDancer.py"

    def bd_config               = "BD.cfg"
    def bd_config_modified      = "BD.modified.cfg"
    def ins_histogram           = "${in_bam}.SeqCap.insertsize_histogram"
    def bd_del_pre              = "BreakDancer_Deletion.pre"
    def bd_del_pre_sorted       = "BreakDancer_Deletion.sorted.pre"
    def bd_causal_mid_bed       = "BD_Causal.mid.bed"
    def bd_causal_mid_pre       = "BD_Causal_mid.pre"


    bd_pre                      = "BD.pre"
    output                      = "BD_Causal.pre"

    """
    # Generate BD configure file
    perl ${bam2cfg_script} \
        -q 30 \
        -m \
        -h \
        -c 5 \
        -g \
        ${in_bam} > ${bd_config}


    # Check if the configue file match the symmetric distribution
    # If yes, run BreakDancer
    # If no, modify the configure file, then run Breakdancer
    if grep -Fq infinity ${bd_config}; then
        # Create new config
        python3 ${modify_bd_config_script} ${ins_histogram} ${bd_config} ${bd_config_modified}
    else
        cp ${bd_config} ${bd_config_modified}
    fi

    # Run BreakDancer on the modified config file
    breakdancer-max -q 0 ${bd_config_modified} > ${bd_pre}

    # Filtering
    awk -v sname=${sample_id} '
    {
        if(\$7=="DEL" && \$10 >= 4 && \$8 >= 100){
            print \$1"\t"\$2"\t"\$5"\t"\$8"\t"\$10"\t"sname;
        }
    }' ${bd_pre} > ${bd_del_pre}

    # awk -F"\t" 'BEGIN{print "chr\tpos1\tpos2\tsize\tDeletion_with_support_Reads\tsample_name"}{ print }'
    sort -k1,1 -k2,2n ${bd_del_pre} > ${bd_del_pre_sorted}

    # If no deletion is found, create an empty output file
    total_lines=\$(wc -l ${bd_del_pre_sorted} | awk '{print \$1}')
    if [ \$total_lines -eq 1 ]; then
        touch ${output}
        exit 0
    fi

    # If deletion is found, continue processing
    bedtools closest -a ${bd_del_pre_sorted} -b ${known_SV_bed} -d | awk 'BEGIN{FS=OFS="\t"}{if(\$14=="0"){print}}' > ${bd_causal_mid_bed}

    python3 ${find_mrange_bd_script} --bed ${bd_causal_mid_bed} -minbed ${bd_causal_mid_pre}

    sort -k6 ${bd_causal_mid_pre} > ${output}
    """
}