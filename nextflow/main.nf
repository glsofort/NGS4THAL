def meta            = create_meta()
def ch_bam          = file(params.bam)
def ch_bai          = file(params.bai)
def ch_bed          = file(params.bed)
def ch_input        = [meta, ch_bam, ch_bai]

def sentieon_dir        = "${params.database}/sentieon/${params.sentieon_release_version}"
def references_dir      = "${params.database}/sentieon/${params.genome}/references"
def genome_ref_dir      = params.genome == 'GRCh37' ? 'hs37d5' : 'fasta'
def dbsnp               = params.genome == 'GRCh37' ? 'dbsnp_138.hg19.vcf' : 'resources-broad-hg38-v0-Homo_sapiens_assembly38.dbsnp138.vcf'

def ch_scripts_dir      = Channel.fromPath("${projectDir}/scripts/*", type: 'any', hidden: true)
def ch_references_dir   = Channel.fromPath("${references_dir}/${genome_ref_dir}/*", type: 'any', hidden: true)
def ch_dbsnp            = Channel.fromPath(["${references_dir}/${dbsnp}", "${references_dir}/${dbsnp}.idx"])
def ch_sentieon_dir     = Channel.fromPath("${sentieon_dir}", type: 'any', hidden: true)

include { FILTER_BAM        } from './modules/filter_bam'
include { REALIGNED_BAM     } from './modules/realigned_bam'
include { HAPLOTYPE_CALLER  } from './modules/haplotype_caller'

workflow NGS4THAL {
    ch_dbsnp.collect().view()
    ch_sentieon_dir.view()
    ch_references_dir.collect().view()

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

    HAPLOTYPE_CALLER(
        REALIGNED_BAM.out.bam,
        ch_dbsnp.collect(),
        ch_references_dir.collect(),
        ch_sentieon_dir
    )
}

workflow {
    NGS4THAL()
}

def create_meta () {
    // create meta map
    def meta = [:]

    meta.fasta              = params.genome == "GRCh37" ? "hs37d5.fa" : "hg38.fa"
    meta.id                 = params.sample_id
    meta.genome_name        = params.genome == "GRCh37" ? "hg19" : "hg38"

    return meta
}
