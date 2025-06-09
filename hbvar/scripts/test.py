import pyhgvs as hgvs
import pyhgvs.utils as hgvs_utils
from pyfaidx import Fasta
import logging
import argparse

# Create a logger
logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s")
logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)

# fasta_file =  "/data/GL/database/autopvs1/hg19_no_chr.fa"
fasta_file = "/data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa"
# transcript_file = "/data/GL/database/UCSC/refGene_nochr.txt"
transcript_file = "out.pred"

# Load transcripts
with open(transcript_file) as infile:
    transcripts = hgvs_utils.read_transcripts(infile)

# Load fasta
fasta = Fasta(fasta_file)


def get_transcript(name):
    return transcripts.get(name)


def get_variant_from_hgvs(hgvsc):
    # Parse HGVS name

    logger.info(hgvsc)

    chrom, pos, ref, alt = hgvs.parse_hgvs_name(
        hgvsc, fasta, get_transcript=get_transcript
    )
    logger.info(f"{chrom}:{pos}:{ref}>{alt}")


def get_hgvsc_from_variant(variant, transcript):
    parts = variant.split(":")

    chrom, offset, ref, alt = (
        parts[0],
        int(parts[1]),
        parts[2].split(">")[0],
        parts[2].split(">")[1],
    )

    logger.info(f"Variant: {chrom}:{offset}:{ref}>{alt}")
    logger.info(f"Transcript: {transcript}")

    transcript = get_transcript(transcript)

    hgvs_name = hgvs.format_hgvs_name(chrom, offset, ref, alt, fasta, transcript)
    logger.info(hgvs_name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""PyHGVS""")
    parser.add_argument("--hgvsc", type=str, help="HGVSc")
    parser.add_argument("--variant", type=str, help="Variant")
    parser.add_argument("--transcript", type=str, help="Transcript")

    args = parser.parse_args()

    if args.hgvsc:
        get_variant_from_hgvs(args.hgvsc)
    elif args.variant:
        get_hgvsc_from_variant(args.variant, args.transcript)
