def meta                = create_meta()
def ch_bam              = file(params.bam)
def ch_bai              = file(params.bai)
def ch_input            = [meta, ch_bam, ch_bai]

def ch_bed              = Channel.fromPath("${projectDir}/assets/Thalassaemia_${meta.genome_name}_genome.bed")
def ch_known_SV_bed     = Channel.fromPath("${projectDir}/assets/known_SV_Deletion_100bp.sorted.bed")
def ch_probe_bed        = Channel.fromPath("${projectDir}/assets/${meta.genome_name}_probe_coverage.bed")

def sentieon_dir        = "${params.database}/sentieon/${params.sentieon_release_version}"
def references_dir      = "${params.database}/sentieon/${params.genome}/references"
def genome_ref_dir      = params.genome == 'GRCh37' ? 'hs37d5' : 'fasta'
def dbsnp               = params.genome == 'GRCh37' ? 'dbsnp_138.hg19.vcf' : 'resources-broad-hg38-v0-Homo_sapiens_assembly38.dbsnp138.vcf'

def ch_scripts_dir      = Channel.fromPath("${projectDir}/scripts/*", type: 'any', hidden: true)
def ch_references_dir   = Channel.fromPath("${references_dir}/${genome_ref_dir}/*", type: 'any', hidden: true)
def ch_dbsnp            = Channel.fromPath(["${references_dir}/${dbsnp}", "${references_dir}/${dbsnp}.idx"])
def ch_sentieon_dir     = Channel.fromPath("${sentieon_dir}", type: 'any', hidden: true)
def ch_bd_scripts_dir   = Channel.fromPath("${projectDir}/scripts/BreakDancer/*", type: 'any', hidden: true)
def ch_pd_scripts_dir   = Channel.fromPath("${projectDir}/scripts/Pindel/*", type: 'any', hidden: true)
def ch_cf_scripts_dir   = Channel.fromPath("${projectDir}/scripts/Conifer/*", type: 'any', hidden: true)

def ch_causal_snv_vcf   = Channel.fromPath("${projectDir}/assets/hbvar_snv.${meta.genome_name}.normed.vcf", type: 'any', hidden: true)
def ch_causal_indel_vcf = Channel.fromPath("${projectDir}/assets/hbvar_indel.${meta.genome_name}.normed.vcf", type: 'any', hidden: true)
// def ch_causal_snv_vcf   = Channel.fromPath("${projectDir}/assets/sorted_causal_snv.vcf", type: 'any', hidden: true)
// def ch_causal_indel_vcf = Channel.fromPath("${projectDir}/assets/sorted_causal_indel.vcf", type: 'any', hidden: true)

include { FILTER_BAM        } from './modules/filter_bam'
include { REALIGNED_BAM     } from './modules/realigned_bam'
include { HAPLOTYPE_CALLER  } from './modules/haplotype_caller'
include { GENOTYPING        } from './modules/genotyping'
include { HARD_FILTERING    } from './modules/hard_filtering'
include { CAUSAL_DETECTION  } from './modules/causal_detection'
include { BREAKDANCER       } from './modules/breakdancer'
include { PINDEL            } from './modules/pindel'
include { CONIFER           } from './modules/conifer'

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

    // For SNV/InDel
    // REALIGNED_BAM(
    //     ch_filtered_bam,
    //     ch_scripts_dir.collect()
    // )

    // HAPLOTYPE_CALLER(
    //     REALIGNED_BAM.out.bam,
    //     ch_dbsnp.collect(),
    //     ch_references_dir.collect(),
    //     ch_sentieon_dir
    // )

    // GENOTYPING(
    //     HAPLOTYPE_CALLER.out.gvcf,
    //     ch_dbsnp.collect(),
    //     ch_references_dir.collect(),
    //     ch_sentieon_dir
    // )

    // HARD_FILTERING(
    //     GENOTYPING.out.vcf
    // )

    // CAUSAL_DETECTION(
    //     HARD_FILTERING.out.snp_vcf,
    //     HARD_FILTERING.out.indel_vcf,
    //     ch_references_dir.collect(),
    //     ch_scripts_dir.collect(),
    //     ch_causal_snv_vcf,
    //     ch_causal_indel_vcf
    // )

    // For SV
    BREAKDANCER(
        ch_filtered_bam,
        ch_bd_scripts_dir.collect(),
        ch_known_SV_bed
    )

    PINDEL(
        ch_filtered_bam,
        BREAKDANCER.out.bd_pre,
        ch_pd_scripts_dir.collect(),
        ch_references_dir.collect(),
        ch_known_SV_bed
    )

    // CONIFER(
    //     ch_filtered_bam,
    //     ch_cf_scripts_dir.collect(),
    //     ch_probe_bed,
    //     ch_known_SV_bed
    // )


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
