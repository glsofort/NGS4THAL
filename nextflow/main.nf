def meta = create_meta()
def ch_bam = Channel.fromPath(params.bam, checkIfExists: true)
def ch_bai = Channel.fromPath(params.bai, checkIfExists: true)
def ch_bed = file(params.bed)
def ch_input = [meta, ch_bam, ch_bai]

include { FILTER_BAM } from './modules/filter_bam'

workflow NGS4THAL {
    FILTER_BAM(
        ch_input,
        ch_bed
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
