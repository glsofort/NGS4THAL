## Preprocess HbVar

### Run Docker

```bash
docker run -itv .:/workspace -v /data/GL:/data/GL namxle/ubuntu-ngs4thal:22.04 bash
```

### HbVar InDel

```bash
# Deletions
python3 scripts/hbvar.py preprocess  \
    -i raw/hbvar_deletions.txt \
    -o hbvar_deletions.vcf \
    -m deletions \
    -f /data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa \
    -t refGene_nochr.txt

# Insertions
python3 scripts/hbvar.py preprocess  \
    -i raw/hbvar_insertions.txt \
    -o hbvar_insertions.vcf \
    -m insertions \
    -f /data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa \
    -t refGene_nochr.txt

# Merge InDel
bcftools concat -a hbvar_insertions.vcf.gz  hbvar_deletions.vcf.gz | \
bcftools sort -Oz -o hbvar_indel.vcf.gz && tabix -f hbvar_indel.vcf.gz

# Normalization
bcftools norm \
    -cs \
    -m -"both" \
    --fasta-ref /data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa \
    hbvar_indel.vcf.gz \
    -o hbvar_indel.normed.vcf.gz

less hbvar_indel.normed.vcf.gz > hbvar_indel.normed.vcf
```

### HbVar SNV

```bash
python3 scripts/hbvar.py preprocess  \
    -i raw/hbvar_substitution.txt \
    -o hbvar_substitution.vcf \
    -m substitution \
    -f /data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa \
    -t refGene_nochr.txt

bcftools norm \
    -cs \
    -m -"both" \
    --fasta-ref /data/GL/database/sentieon/GRCh37/references/hs37d5/hs37d5.fa \
    hbvar_substitution.vcf.gz \
    -o hbvar_snv.normed.vcf.gz

less hbvar_snv.normed.vcf.gz > hbvar_snv.normed.vcf
```

### Check diff

```bash
vcftools --vcf results/hbvar_deletions.vcf \
    --diff hbvar_deletions.vcf \
    --diff-site

vcftools --vcf results/hbvar_insertions.vcf \
    --diff hbvar_insertions.vcf \
    --diff-site
```

## Test PyHGVS

```bash
python3 test.py --hgvsc "NM_000348.4:c.680G>A"
python3 test.py --hgvsc "NM_000152:c.2065G>A"
python3 test.py --hgvsc "NM_000517:c.19G>T"

python3 test.py --hgvsc "NC_000002.12:g.31529325C>T"

python3 test.py --variant "2:31754395:C>T" --transcript NM_000348.4
```