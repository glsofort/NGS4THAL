import argparse
import logging
import os
import concurrent.futures
import csv
import time

# Create a logger
logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s")
logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)


def run(vcf, af_output, output, sample_id):
    pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="""Process HbVar data"""
    )
    parser.add_argument("--vcf", type=str, help="Original VCF file", required=True)
    parser.add_argument(
        "-a", "--af-output", type=str, help="Output AF VCF file", required=True
    )
    parser.add_argument(
        "-s", "--sample-id", dest="sample_id", type=str, help="Sample Id", required=True
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output",
        type=str,
        help="Output file in tsv format",
        required=True,
    )

    args = parser.parse_args()
    run(
        vcf=args.vcf,
        af_output=args.af_output,
        output=args.output,
        sample_id=args.sample_id,
    )
