# Commands

## Nextflow

### Disable bam filtering

```bash
source .env && \
rm -rf outdir/3187 && \
nextflow run main.nf \
-c nextflow.config \
-profile docker \
--sample_id 3187 \
--bam samples/3187.filtered.bam \
--bai samples/3187.filtered.bam.bai \
--genome GRCh37 \
--database ${DATABASE} \
--docker_registry ${REGISTRY} \
--sentieon_license ${SENTIEON_LICENSE} \
--sentieon_release_version ${SENTIEON_RELEASE} \
--sentieon_auth_mech ${SENTIEON_AUTH_MECH} \
--sentieon_auth_data ${SENTIEON_AUTH_DATA} \
--outdir outdir/3187 \
--skip_filter # Disable bam filter
```

### Enable bam filtering

```bash
source .env && \
rm -rf outdir/SRR30128989-v3 && \
nextflow run main.nf \
-c nextflow.config \
-profile docker \
--sample_id SRR30128989 \
--bam samples/SRR30128989.deduped.bam \
--bai samples/SRR30128989.deduped.bam.bai \
--genome GRCh37 \
--database ${DATABASE} \
--docker_registry ${REGISTRY} \
--sentieon_license ${SENTIEON_LICENSE} \
--sentieon_release_version ${SENTIEON_RELEASE} \
--sentieon_auth_mech ${SENTIEON_AUTH_MECH} \
--sentieon_auth_data ${SENTIEON_AUTH_DATA} \
--outdir outdir/SRR30128989-v3

source .env && \
rm -rf outdir/SRR32024429 && \
nextflow run main.nf \
-c nextflow.config \
-profile docker \
--sample_id SRR32024429 \
--bam samples/SRR32024429.bwa.bam \
--bai samples/SRR32024429.bwa.bam.bai \
--genome GRCh37 \
--database ${DATABASE} \
--docker_registry ${REGISTRY} \
--sentieon_license ${SENTIEON_LICENSE} \
--sentieon_release_version ${SENTIEON_RELEASE} \
--sentieon_auth_mech ${SENTIEON_AUTH_MECH} \
--sentieon_auth_data ${SENTIEON_AUTH_DATA} \
--outdir outdir/SRR32024429
```

## VEP

```bash
# Run docker
docker run -itv /data/GL/database:/database -v .:/workspace namxle/ensembl-vep:110.1 bash

# Run VEP
vep --input_file hgvs.txt \
    --output_file output.vcf \
    --vcf \
    --dir /database/VEP/ \
    --dir_cache /database/VEP/ \
    --dir_plugins /database/VEP/Plugins \
    --force_overwrite \
    --fork 16 \
    --species homo_sapiens \
    --fasta /database/VEP/homo_sapiens_merged/110_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
    --cache \
    --assembly GRCh37
```
