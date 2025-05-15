#!/usr/bin/env python3
"""
HGVS Processing CLI Tool
Usage: python3 test.py [command] --options
"""

import argparse
import sys
import re
import logging
import pyhgvs as hgvs
import pyhgvs.utils as hgvs_utils
from pyfaidx import Fasta
import subprocess

# Create a logger
logging.basicConfig(format="%(asctime)s %(levelname)s: %(message)s")
logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)

MUTATION_TYPE_MAPPING = {"deletions": "del", "insertions": "ins", "substitution": ">"}

FORBIDEN_HGVS_GENES = [
    "chr16",
    "Hg19.Chr11g.5372677_5372678insCACCTCCACTTdup5226885_5372677",
    "NC_000011.8",
    "NC_000011.9",
    "NG_000006.1",
    "NC_000016.8",
    "NG_000007.3",
    "U01317",
    "U01317.1",
    "NC_000016.9",
]

GENE_TRANSCRIPT_MAPPING = {
    "HBA1": "NM_000558",
    "HBA2": "NM_000517",
    "HBB": "NM_000518",
    "HBD": "NM_000519",
    "HBG2": "NM_000184",
    "HBG1": "NM_000559",
    "U01317.1(HBG1)": "NM_000559",  # Same with HBG1
    "U01317.1": "NM_000559",  # Same with HBG1
}


HEADERS = {
    "hg19": [
        "##fileformat=VCFv4.2",
        '##INFO=<ID=HbVar_num,Number=1,Type=String,Description="HbVar_database_entry_ID">',
        '##INFO=<ID=Hb_name,Number=1,Type=String,Description="Hb_names_for_this_mutation">',
        '##INFO=<ID=HGVS_name,Number=1,Type=String,Description="HGVS_name">',
        '##INFO=<ID=type,Number=1,Type=String,Description="mutation_types">',
        "##contig=<ID=11,length=135006516,assembly=b37>",
        "##contig=<ID=16,length=90354753,assembly=b37>",
        "##reference=file://hs37d5.fa",
    ],
    "hg38": [],
}

fasta = None
transcripts = None

NAS = "."


def split_compound_hgvs(hgvs_string, row_mutation_type, data_mutation_type="deletions"):
    """
    Split compound HGVS notation into individual variants
    Examples:
    HBB:c.[20A>T;249G>T or 249G>C]
    """
    # Extract the gene/transcript and the variants part
    gene_part = hgvs_string.split(":")[0]
    transcript_part = GENE_TRANSCRIPT_MAPPING[gene_part]
    notation_type = hgvs_string.split(":")[1].split(".")[0]
    variants_part = (
        hgvs_string.split(":")[1].split(".")[1].replace("[", "").replace("]", "")
    )

    mutation_types = row_mutation_type.split(",")

    separator = ";"
    if separator in variants_part:
        # Split by semicolon
        variants = variants_part.split(separator)
        # If variants have the same length with mutation types
        # then get only the mutation type match with the whole data
        if len(variants) == len(mutation_types):
            variants = [
                variant
                for variant in variants
                if MUTATION_TYPE_MAPPING[data_mutation_type] in variant
            ]
    else:
        variants = [variants_part]

    # If or exist then get the first HGVSc
    separator = " or "
    variants = [item.split(separator)[0].strip() for item in variants]

    # Reconstruct individual HGVS notations
    results = []
    for variant in variants:
        variant = variant.strip()
        hgvsc = f"{transcript_part}:{notation_type}.{variant}"
        hgvsc_raw = f"{gene_part}:{notation_type}.{variant}"
        results.append({"hgvsc": hgvsc, "hgvsc_raw": hgvsc_raw})

    return results


def format_hbvar_data(input_file, mutation_type):
    # Determine input source
    with open(input_file, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    # Process each HGVS
    line_count = 0
    final_results = []
    for line in lines:
        line_count += 1
        if line.find("#") == 0:
            continue
        line_data = line.split("\t")
        hbvar_id = line_data[3]
        hbvar_name = line_data[4]
        hbvar_hgvsname = line_data[5]
        hbvar_mutation_type = line_data[6]

        # Remove some notation in hgvsc name
        hbvar_hgvsc = hbvar_hgvsname.split(" (or")[0]

        # Filter out mutation types
        if mutation_type not in hbvar_mutation_type.split(","):
            logger.warning(
                f"Skip line: {line_count}; Mutation type: {hbvar_mutation_type}"
            )
            continue

        if hbvar_hgvsname.split(":")[0] in FORBIDEN_HGVS_GENES:
            logger.warning(
                f"Skip line: {line_count}; Forbiden HGVS genes: {hbvar_hgvsname.split(':')[0]}"
            )

            continue

        # Split result
        hgvs_splited = split_compound_hgvs(
            hbvar_hgvsc,
            row_mutation_type=hbvar_mutation_type,
            data_mutation_type=mutation_type,
        )
        results = [
            {
                "hbvar_id": hbvar_id,
                "hbvar_name": hbvar_name,
                "hbvar_hgvsname": hbvar_hgvsname,
                "hbvar_hgvsc": hbvar_hgvsc,
                "hbvar_mutation_type": hbvar_mutation_type,
                "hgvsc": item["hgvsc"],
                "hgvsc_raw": item["hgvsc_raw"],
            }
            for item in hgvs_splited
        ]
        final_results.extend(results)

    duplicate_results = [
        logger.info(f"[Formating] Multiple HGSVc: {item}")
        for item in final_results
        if item["hbvar_hgvsc"] != item["hgvsc_raw"]
    ]

    logger.info(f"[Formating] Total multiple HGSVc: {len(duplicate_results)}")
    logger.info(f"[Formating] Total final result: {len(final_results)}")

    return final_results


def get_transcript(name):
    return transcripts.get(name)


def get_variant_from_hgvs(hbvar_data):
    results = []

    logger.info(f"[Retrieving variants] Total input: {len(hbvar_data)}")
    for item in hbvar_data:
        # Parse HGVS name
        try:
            chrom, pos, ref, alt = hgvs.parse_hgvs_name(
                item["hgvsc"], fasta, get_transcript=get_transcript
            )
            item["variant"] = {"chrom": chrom, "pos": pos, "ref": ref, "alt": alt}
            results.append(item)
        except:
            logger.error(
                f"[Retrieving variants] Find variant error for: {item['hgvsc']}"
            )
    logger.info(f"[Retrieving variants] Total output: {len(results)}")

    return results


def export_vcf(data, output, genome="hg19"):

    header_lines = HEADERS[genome]

    with open(output, "w") as vcf_file:
        # Write header lines
        for header in header_lines:
            vcf_file.write(header + "\n")

        # Write column header
        vcf_file.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")

        # Write variants
        for item in data:
            variant = item["variant"]

            # Build INFO string
            info_parts = [
                f'HbVar_num={item["hbvar_id"].strip().replace(" ", "_").replace(";",",")}',
                f'Hb_name={item["hbvar_name"].strip().replace(" ", "_").replace(";",",")}',
                f'HGVS_name={item["hbvar_hgvsname"].strip().replace(" ", "_").replace(";",",")}',
                f'type={item["hbvar_mutation_type"].strip().replace(" ", "_").replace(";",",")}',
            ]
            info_str = ";".join(info_parts) if info_parts else NAS

            line = "\t".join(
                [
                    str(variant["chrom"]),
                    str(variant["pos"]),
                    item["hbvar_id"].strip().replace(" ", "<s>").replace(";", ","),  # ID
                    variant["ref"],
                    variant["alt"],
                    NAS,  # QUAL
                    NAS,  # FILTER
                    info_str,
                ]
            )
            vcf_file.write(line + "\n")
    logger.info(f"[Exporting] Results written to '{output}' ({len(data)} variants)")


def sorting_indexing(vcf_file, output_file):
    command = f"bcftools sort {vcf_file} > {output_file} && bgzip -cf {output_file} > {output_file}.gz && tabix {output_file}.gz"
    subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        check=True,  # Raises exception on non-zero exit code
    )


def run_preprocess(args):
    """Handle the split command"""

    global transcripts, fasta

    input_file = args.input_file
    output_file = args.output_file
    tmp_file = args.output_file + ".tmp"
    mutation_type = args.mutation_type
    fasta_file = args.fasta_file
    transcript_file = args.transcript_file

    # Load fasta
    fasta = Fasta(fasta_file)

    # Load transcripts
    with open(transcript_file) as infile:
        transcripts = hgvs_utils.read_transcripts(infile)

    # Format HbVar data
    formated_data = format_hbvar_data(input_file, mutation_type)

    # Mapping HGVSc to variant
    final_data = get_variant_from_hgvs(formated_data)

    # Export VCF
    export_vcf(final_data, tmp_file)

    # Sorting & Indexing
    sorting_indexing(tmp_file, output_file)

    logger.info("Done")


def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(
        description="HGVS Processing Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # Create subparsers for commands
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    subparsers.required = True

    # Split command
    preprocess_parser = subparsers.add_parser(
        "preprocess", help="Preprocess HbVar mutation data"
    )
    preprocess_parser.add_argument(
        "--input-file",
        "-i",
        required=True,
        help="Input file with HGVS notations (one per line)",
    )
    preprocess_parser.add_argument(
        "--output-file",
        "-o",
        required=True,
    )
    preprocess_parser.add_argument(
        "--mutation-type",
        "-m",
        default="deletions",
        required=True,
    )

    preprocess_parser.add_argument(
        "--fasta-file",
        "-f",
        required=True,
    )

    preprocess_parser.add_argument(
        "--transcript-file",
        "-t",
        required=True,
    )

    # Parse arguments
    args = parser.parse_args()

    # Route to appropriate command handler
    try:
        if args.command == "preprocess":
            return run_preprocess(args)
        else:
            parser.print_help()
            return 1
    except KeyboardInterrupt:
        logger.info("Operation cancelled by user")
        return 1
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
