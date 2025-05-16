def meta            = create_meta()
def ch_bam          = file(params.bam)
def ch_bai          = file(params.bai)
def ch_bed          = file(params.bed)
def ch_input        = [meta, ch_bam, ch_bai]

def ch_scripts_dir  = Channel.fromPath("${projectDir}/scripts/*", type: 'any', hidden: true)

include { FILTER_BAM    } from './modules/filter_bam'
include { REALIGNED_BAM } from './modules/realigned_bam'

workflow NGS4THAL {
    if (params.skip_filter) {
        ch_filtered_bam = ch_input
    } else {
        FILTER_BAM(
            ch_input,
            ch_bed
        )
        ch_filtered_bam = FILTER_BAM.out.bam
    }

    REALIGNED_BAM(
        ch_filtered_bam,
        ch_scripts_dir.collect()
    )
}

workflow {
    NGS4THAL()
}

def create_meta () {
    // create meta map
    def meta = [:]
    meta.id                 = params.sample_id
    meta.genome_name        = params.genome == "GRCh37" ? "hg19" : "hg38"

    return meta
}
