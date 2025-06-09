# NGS4THAL

## Snv/InDel

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

```bash
docker run -itv .:/workspace -v /data/GL:/data/GL namxle/ubuntu-ngs4thal:22.04 bash
```

## SV

### Original

BreakDancer should go before Pindel, since results from BreakDancer are used as one of the input for Pindel
After BreakDancer and Pindel, we run Conifer: first calculate RPKM, then run the Conifer main process.

```bash
cd /home/data/Thala/SV/Screening_stage/BreakDancer
qsub BreakDancer_Run.pbs
cd /home/data/Thala/SV/Screening_stage/Pindel
qsub Pindel_Run.pbs
cd /home/data/Thala/SV/Screening_stage/Conifer
qsub RPKM_cal.pbs
qsub Conifer_Run.pbs
```
