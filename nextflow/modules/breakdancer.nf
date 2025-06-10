process BREAKDANCER {
    tag "${meta.id}-cpus:${task.cpus}"
    label 'process_large'
    label 'publish'

    input:
    tuple val(meta), path(in_bam), path(in_bai)
    path(bd_scripts_dir)

    output:
    tuple val(meta), path(output)

    script:
    def prefix          = task.ext.prefix ?: "${meta.id}"
    def threads         = task.cpus

    def bam2cfg_script          = "bam2cfg.pl"
    def modify_bd_config_script = "Modify_BD_config.py"

    def bd_config               = "BD.cfg"
    def bd_config_modified      = "BD.modified.cfg"
    def ins_histogram           = "${in_bam}.SeqCap.insertsize_histogram"
    def bd_pre_result           = "BD.pre"

    output                      = "out"

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
    breakdancer-max -q 0 ${bd_config_modified} > ${bd_pre_result}


    touch ${output}
    """
}