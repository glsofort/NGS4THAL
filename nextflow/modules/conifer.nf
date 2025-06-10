process CONIFER {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(conifer_scripts_dir)
    path(probe_bed)
    path(known_SV_bed)

    output:
    path(output_del_causal_pre),  emit: conifer_del_causal
    path(output_dup_alpha_rpre),  emit: conifer_dup_region

    script:
    def fasta                   = meta.fasta
    def prefix                  = task.ext.prefix ?: "${meta.id}"
    def threads                 = task.cpus
    def sample_id               = meta.id
    
    def conifer_script          = "conifer.py"
    def find_mr_conifer_script  = "Find_minimum_range_Conifer.py"

    def rpkm_dir                = "RPKM"
    def rpkm_output             = "rpkm.txt"

    def cf_analysis_hdf5        = "analysis.hdf5"
    def cf_analysis_svals       = "analysis.s.v.txt"
    def cf_analysis_plot        = "analysis.screeplot.png"
    def cf_analysis_sd          = "analysis.sd_values.txt"

    def cf_cnv_call_03          = "CNVcalls.05.txt"
    def cf_cnv_call_03          = "CNVcalls.03.txt"

    def cf_del_pre              = "Conifer_Deletion.pre"
    def cf_del_pre_sorted       = "Conifer_Deletion.sorted.pre"

    def cf_del_causal_bed       = "Conifer_Deletion_Causal.bed"
    def cf_del_causal_pre_mid   = "Conifer_Deletion_Causal.pre.mid"

    def cf_dup_pre              = "Conifer_Duplication.pre"
    
    output_del_causal_pre       = "Conifer_Deletion_Causal.pre"
    output_dup_alpha_rpre       = "Alpha_region_Conifer_Duplication.pre"


    """
    # Calculate RPKM using Conifer
    python3 ${conifer_script} rpkm \
        --probes ${probe_bed} \
        --input ${in_bam} \
        --output ${rpkm_dir}/${rpkm_output}

    # Analyze the RPKM data with Conifer
    python3 ${conifer_script} analyze \
        --probes ${probe_bed} \
        --rpkm_dir ${rpkm_dir} \
        --output ${cf_analysis_hdf5} \
        --svd 3 \
        --write_svals ${cf_analysis_svals} \
        --plot_scree ${cf_analysis_plot} \
        --write_sd ${cf_analysis_sd}

    # Call CNVs using Conifer with a threshold of 0.5
    python3 ${conifer_script} call \
    --input ${cf_analysis_hdf5} \
    --threshold 0.5 \
    --output ${cf_cnv_call_05}

    # Call CNVs using Conifer with a threshold of 0.3
    python3 ${conifer_script} call \
        --input ${cf_analysis_hdf5} \
        --threshold 0.3 \
        --output ${cf_cnv_call_03}

    # Find causal varaints
    awk 'BEGIN{print "chr\tpos1\tpos2\tsize\tDeletion_with_support_Reads\tsample_name"}'  > ${cf_del_pre}
    awk '{
        if(\$4-\$3>500 && \$5=="del"){
            print \$2"\t"\$3"\t"\$4"\t"\$4-\$3"\tNA\t"\$1;
        }
    }' ${cf_cnv_call_03} >> ${cf_del_pre}

    sort -k1,1 -k2,2n ${cf_del_pre} > ${cf_del_pre_sorted}
    bedtools closest -a ${cf_del_pre_sorted} -b ${known_SV_bed} -d > ${cf_del_causal_bed}

    python3 ${find_mr_conifer_script} --bed ${cf_del_causal_bed} -minbed ${cf_del_causal_pre_mid}
    sort -k6 ${cf_del_causal_pre_mid} > ${output_del_causal_pre}

    # For duplication
    awk 'BEGIN{print "chr\tpos1\tpos2\tsize\tDeletion_with_support_Reads\tsample_name"}'  > ${cf_dup_pre}
    awk '{
        if(\$4-\$3>2500  && \$5=="dup"){
            print \$2"\t"\$3"\t"\$4"\t"\$4-\$3"\tNA\t"\$1;
        }
    }' ${cf_cnv_call_03} >> ${cf_dup_pre}

    awk '{
        if(\$2>219000 && \$3<228000){
            print;
        }
    }' ${cf_dup_pre}  | sort -k6 > ${output_dup_alpha_rpre}
    """
}