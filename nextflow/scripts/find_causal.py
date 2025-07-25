import sys
import os
import argparse
import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-input", "--inputvcf")
parser.add_argument("-output", "--outputtxt")
parser.add_argument("-mutation", "--mutationtype")
parser.add_argument("-outdir", "--outdir")
parser.add_argument("-knowncausal")
args = parser.parse_args()


def F_Create_pseudo_vcf(inputvcf, outputvcf):
    alt_allele = [None] * 4
    with open(inputvcf, "r") as fp, open(outputvcf, "w") as fout:
        for line in fp:
            if line.startswith("##"):
                pass
            elif line.startswith("#"):
                div = line.rstrip("\n").split("\t")
                samplenamelists = line.strip("\n").split("\t")[9:]
                samplecount = len(samplenamelists)
                newline = (
                    div[0]
                    + "\t"
                    + div[1]
                    + "\t"
                    + div[3]
                    + "\t"
                    + div[4]
                    + "\t"
                    + "\t".join(samplenamelists)
                    + "\n"
                )
                fout.write(newline)
            else:
                div = line.rstrip("\n").split("\t")
                alt_num = len(line.strip("\n").split("\t")[4].split(","))
                chrom = div[0]
                pos = div[1]
                ref = div[3]
                alt = div[4]

                if alt_num == 1 and alt != "*":
                    newline = chrom + "\t" + pos + "\t" + ref + "\t" + alt
                    # Flag to track if we have any non-reference genotypes
                    has_non_ref = False

                    for i in range(9, samplecount + 9):
                        raw_GT = div[i].split(":")[0]
                        if raw_GT == "0/0" or raw_GT == "0|0":
                            pass
                        elif raw_GT == "0/1" or raw_GT == "0|1":
                            new_GT = ref + "_" + alt
                            newline = newline + "\t" + new_GT
                            has_non_ref = True
                        elif raw_GT == "1/1" or raw_GT == "1|1":
                            new_GT = alt + "_" + alt
                            newline = newline + "\t" + new_GT
                            has_non_ref = True
                        else:
                            pass
                    # Only write if we found at least one non-reference genotype
                    if has_non_ref:
                        newline = newline + "\n"
                        fout.write(newline)
    return 1


def F_split_pseudovcf_by_sample(vcffile, outputfolder):
    GT_matrix = pd.read_csv(vcffile, sep="\t", header=0)
    with open(vcffile, "r") as fp:
        line = fp.readline()
        div = line.rstrip("\n").split("\t")
        samplenamelists = line.strip("\n").split("\t")[4:]
        samplecount = len(samplenamelists)
    for sample in samplenamelists:
        outputfilename = str(sample) + ".txt"
        filepath = outputfolder + "/" + outputfilename
        df = GT_matrix.loc[:, ["#CHROM", "POS", "REF", "ALT", sample]]
        df.to_csv(filepath, index=False, sep="\t")
    return samplenamelists, samplecount


def F_match_causal(samplefile, knowncausal, outputfile):
    db_dict = {}
    with open(knowncausal, "r") as fp:
        for line in fp:
            if not line.startswith("#"):
                div = line.rstrip("\n").split("\t")
                key = div[0] + "_" + str(div[1]) + "_" + div[3] + "_" + div[4]
                value = div[7]
                db_dict[key] = value
    with open(samplefile, "r") as fp, open(outputfile, "w") as fout:
        for line in fp:
            if line.startswith("#"):
                fout.write(line)
            else:
                div = line.rstrip("\n").split("\t")
                current_key = (
                    div[0] + "_" + str(div[1]) + "_" + str(div[2]) + "_" + str(div[3])
                )
                if current_key in db_dict.keys():
                    newline = line.rstrip("\n") + "\t" + db_dict[current_key] + "\n"
                    fout.write(newline)
    return 1


if __name__ == "__main__":
    MutationType = args.mutationtype
    code_F = os.getcwd()
    inputvcf = args.inputvcf

    if MutationType == "SNP":
        # SNP
        pseudo_vcf_file = "pseudo_candidate_SNP.recode.vcf"
        F_Create_pseudo_vcf(inputvcf=inputvcf, outputvcf=pseudo_vcf_file)
        Causal_SNV_F = args.outdir
        os.mkdir(Causal_SNV_F)
        samplenamelists = []
        samplecount = []
        samplenamelists, samplecount = F_split_pseudovcf_by_sample(
            vcffile=pseudo_vcf_file, outputfolder=Causal_SNV_F
        )

        knowncausalSNV = args.knowncausal
        for i in samplenamelists:
            samplefile = Causal_SNV_F + "/" + i + ".txt"
            outputfile = Causal_SNV_F + "/" + "pre." + i
            F_match_causal(
                samplefile=samplefile, knowncausal=knowncausalSNV, outputfile=outputfile
            )
    if MutationType == "InDel":
        # indel
        pseudo_vcf_file = "pseudo_candidate_INDEL.recode.vcf"
        F_Create_pseudo_vcf(inputvcf=inputvcf, outputvcf=pseudo_vcf_file)
        Causal_INDEL_F = args.outdir
        os.mkdir(Causal_INDEL_F)
        samplenamelists = []
        samplecount = []
        samplenamelists, samplecount = F_split_pseudovcf_by_sample(
            vcffile=pseudo_vcf_file, outputfolder=Causal_INDEL_F
        )

        knowncausalINDEL = args.knowncausal
        for i in samplenamelists:
            samplefile = Causal_INDEL_F + "/" + i + ".txt"
            outputfile = Causal_INDEL_F + "/" + "pre." + i
            F_match_causal(
                samplefile=samplefile,
                knowncausal=knowncausalINDEL,
                outputfile=outputfile,
            )
else:
    pass
