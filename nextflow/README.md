# NGS4THAL

## Nextflow

### Disable bam filtering

```bash
source .env && \
rm -rf outdir && \
nextflow run main.nf \
-c nextflow.config \
-profile docker \
--sample_id 3187 \
--bed assets/Thalassaemia_hg19_genome.bed \
--bam samples/3187.filtered.bam \
--bai samples/3187.filtered.bam.bai \
--genome GRCh37 \
--database ${DATABASE} \
--docker_registry namxle \
--bed_dir /data/GL/beds \
--sentieon_license ${SENTIEON_LICENSE} \
--sentieon_release_version v202308.03 \
--sentieon_auth_mech ${SENTIEON_AUTH_MECH} \
--sentieon_auth_data ${SENTIEON_AUTH_DATA} \
--outdir outdir \
--skip_filter # Disable bam filter
```

### Enable bam filtering

```bash
source .env && \
rm -rf outdir && \
nextflow run -bg main.nf \
-c nextflow.config \
-profile docker \
--sample_id 3187 \
--bed assets/Thalassaemia_hg19_genome.bed \
--bam samples/3187.deduped.bam \
--bai samples/3187.deduped.bam.bai \
--genome GRCh37 \
--database ${DATABASE} \
--docker_registry namxle \
--bed_dir /data/GL/beds \
--sentieon_license ${SENTIEON_LICENSE} \
--sentieon_release_version v202308.03 \
--sentieon_auth_mech ${SENTIEON_AUTH_MECH} \
--sentieon_auth_data ${SENTIEON_AUTH_DATA} \
--outdir outdir
```

## Steps

### Step 1

Extract hemoglobin regions records from BAM files

```bash
samtools view -h -L Thalassaemia_hg19_genome.bed -b -o output.bam input.bam
samtools index output.bam
```

### Step 2

Modify `Thala_rescue_configuration.txt`

```bash
python Thala_rescue_PBS.py
```

The `Thala_rescue_PBS.py` will create for each sample a PBS file

### Step 3

Modify submit.sh(step-by-step, change the target PBS scripts)

```bash
sh submit.sh
```

--> Overall, for each sample:

- Step 1: Run `Thalassemia.py`
- Step 2: Run `Thala_Rescue_phase2_Step1_RunHC_model.pbs`

### Step 4 (From the original repo)

Do joint genotyping & hard filtering

```bash
cd ./VCF_file
qsub Thala_Rescue_phase2_Step2_GTing.pbs
cd ./Joint
qsub Thala_Rescue_phase2_Step3_HardFiltering.pbs
```

### Step 5 (From the original repo)

Find current known thalassaemia causal mutations based on HbVar and ITHANET. We have created collections from these databases, and you just running the follwing commands to pick these mutations out.

```bash
cd ./VCF_file/Joint/
qsub Thala_Find_Causal.pbs (or sh Thala_Find_Causal.pbs for non-PBS servers)
```

## Docker

Using `registry.cn-shenzhen.aliyuncs.com/gls-nextflow/ubuntu-fastq:22.04-java11.0.22-perl5.34.0`
