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

    def bd_config       = "BD.cfg" 

    output              = "out"

    """
    # Generate BD configure file
    perl ${bam2cfg_script} \
        -q 30 \
        -m \
        -h \
        -c 5 \
        -g \
        ${in_bam} > ${bd_config}

    touch ${output}
    """
}