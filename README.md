# Validation of qiagen brca pipeline

* Pipeline version (WDL): **1.0.0-rc2** (<https://github.com/Varstation/wdl-qiagen-dna-germline/releases/tag/v1.0.0-rc2>)
* Docker image: `776722213159.dkr.ecr.us-east-1.amazonaws.com/qiagen-dna:0.1.0`
* Resources: `s3://bioinfo-resources-us-east-1/library-prep-kits/Qiagen/qiaseq-dna/`

HIAE documentation: (<https://github.com/Varstation/procedimentos/wiki/Executar-rotinas-de-qiagen-somatic-e-Nextera>)

Upload routine files from HIAE server to S3.
Routine files are a SampleSheet describing all samples and relates paired-end FASTQ files.

* Routine folder: `s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/20211207_MS3262052-300V2/`
* Original results folder: `s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/output/`
* Validation results: `s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL-v1.0.0-rc2/`
* Hap.py summary tables: <https://docs.google.com/spreadsheets/d/15dus8SOiZsp-frYq9OsBTd4ttoeteWSSRfyv27uolWM/edit?usp=sharing>

## Runnning tests with kakuna

### Bastion with Varstation account (prod) credentials

```bash
kakuna \
    --workflow workflows/qiagen-dna-germline_v1.0.0-rc2.wdl \
    --imports workflows/qiagen-dna-germline_v1.0.0-rc2.zip \
    --template templates/qiagen-germline-brca.json \
    --labels templates/qiagen.labels.json \
    --key-column sampleName \
    --inputs-dir inputs \
    --cromwell-server https://192.168.61.226 \
    --disable-ssl \
    sample_sheets/sample-sheet-qiagen.csv \
    s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL-v1.0.0-rc2
```

Output path: `s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL-v1.0.0-rc2/`

### Submission list

```bash
INFO:kakuna:20210545-008        917ba7b7-0613-4727-984a-9bb2b882eac5    Succeeded
INFO:kakuna:20210545-010        cc26e2d7-36f7-4364-b7e0-3d7af63c5f40    Succeeded
INFO:kakuna:20210545-011        61fe1fe7-0eb1-4db5-802d-1c902d6dfc0d    Succeeded
```

## Evaluate against last validation results

### Copy files from aws

```bash
#get outputs from previous release
mkdir v1.0.0-rc1
aws s3 cp s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL/ v1.0.0-rc1/ --recursive

#get outputs from new release
mkdir v1.0.0-rc2
aws s3 cp s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL-v1.0.0-rc2/ v1.0.0-rc2/ --recursive
```

### Compare variants

```bash
#extract variants from multianno of previous release and remove the "chr" from chromossome
for file in $(ls v1.0.0-rc1/*multianno.tsv.gz);do gunzip -c $file | cut -f 1,2,3,4 | sed -e "s/chr//g" > $file.variants.tsv;done

#extract variants from multianno of new release
for file in $(ls v1.0.0-rc2/*/*multianno.tsv.gz);do gunzip -c $file | cut -f 1,2,3,4 > $file.variants.tsv;done

#get differences
diff v1.0.0-rc1/20210545-008.multianno.tsv.gz.variants.tsv v1.0.0-rc2/20210545-008/20210545-008.multianno.tsv.gz.variants.tsv > 20210545-008_rc1_rc2.diff
diff v1.0.0-rc1/20210545-010.multianno.tsv.gz.variants.tsv v1.0.0-rc2/20210545-010/20210545-010.multianno.tsv.gz.variants.tsv > 20210545-010_rc1_rc2.diff
diff v1.0.0-rc1/20210545-011.multianno.tsv.gz.variants.tsv v1.0.0-rc2/20210545-011/20210545-011.multianno.tsv.gz.variants.tsv > 20210545-011_rc1_rc2.diff
```

#### Whats changed?

All variants are the same in both releases, one changed was noticed in files of sample `20210545-010`, where in the v1.0.0-rc1 release, the variant at position `41219853` is duplicated and in the new release (v1.0.0.0-rc2), not.
:
```
17      41219853        41219853        -
17      41219853        41219853        -
```

The diff files were uploaded to `s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/`

### Evaluation with hap.py

First of all, the merged.vcf.gz files with the truth calls are recovered for each sample from `s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-VARS/`.

The files were unziped, and lifted over to `hs37d5`:

```bash
for i in $(ls *merged.vcf | cut -f1 -d.);do
    java -jar ~/Downloads/picard.jar LiftoverVcf \
        I=$i".vcf" \
        O=$i"_hs37d5.vcf" \
        CHAIN=hg19tob37.chain \
        REJECT=$i"_rejected.vcf" \
        R=hs37d5.fa;done
```

The lifted files were compressed with bgzip, indexed with tabix, and copied to: `s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/truth_calls_lifted/`

```bash
kakuna \
    --workflow workflows/happy.wdl \
    --template templates/happy.template.json \
    --labels templates/happy.labels.json \
    --key-column outputPrefix \
    --inputs-dir inputs \
    --cromwell-server https://192.168.61.226 \
    --disable-ssl \
    sample_sheets/sample-sheet-happy.csv \
    s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/happy_valid_WDL-v1.0.0-rc2
```

#### Submission list

```bash
INFO:automation:20210545-008    8157ed86-0d5f-4ded-b153-02f3e227d657    Succeeded
INFO:automation:20210545-010    86b3692f-eb94-4961-bbae-032750a94233    Succeeded
INFO:automation:20210545-011    8d8bec1a-4639-4bf7-9960-e5512187d38e    Succeeded
```

The comparrison with Hap.py results of the previous validation are available in [this table](https://docs.google.com/spreadsheets/d/15dus8SOiZsp-frYq9OsBTd4ttoeteWSSRfyv27uolWM/edit?usp=sharing).

Both Hap.py results (from v1.0.0-rc1 and v1.0.0-rc2) showed precision metrics bellow of 0.95 (the minimum treshold expected), to understand if those variants impacts the variants of CAP, a manual curation was performed, and the results are available in [this table](https://docs.google.com/spreadsheets/d/1jvevCaG9VPoV8PqALHsrxyvWWJ37P8nUvvXH9ex-VXY/edit?usp=sharing)

After the manual curation, we noticed that some variants in intronic regions are present in results of qiagen-dna-germline of varstation 2.0 (considered as truth variants) and absent in the new proposed release, and vice-versa.

## Evaluate Vars3 aplication results

The qiagen-dna-germline was implemented on varstation 3.0 homolog application, in the `chazanas-enterprises` organization, as the `QIAGEN_BRCA_hg19` pipeline. The routine [qiagen_brca](http://homolog.varstation.com.s3-website-sa-east-1.amazonaws.com/#/routines/227/samples) was created.

### CAP

According to CAP, each of three samples should have a specific pathogen variant, according the following table:

| CAP-sample | HIAE-sample  | expected variant                    | hs37d5-locus |
| ---------- | ------------ | ----------------------------------- | ------------ |
| BRCA-04    | 20210545-008 | BRCA1:c.1204delG:p.(Glu402Serfs*8)  | 17:41246344  |
| BRCA-05    | 20210545-010 | BRCA2:c.581G>A:p.(Trp194Ter)        | 13:32900700  |
| BRCA-06    | 20210545-011 | BRCA1:c.2071delA:p.(Arg691Aspfs*10) | 17:41245477  | 

### Vars3 app

The three samples presented the CAP expected variants in Vars3 application, the difference from Vars2 is that the variant `BRCA1:c.1204delG:p.(Glu402Serfs*8)` from BRCA-04 sample is considered `Vus PVS1` in Vars3 and in Vars2 is considered `Pathogenic PVS1, PS4, PM2`, the same occurs with the variant `BRCA1:c.2071delA:p.(Arg691Aspfs*10` from BRCA-06 sample.

Moreover, the platform showed the same number of variants of merged.vcf files of each sample.

| HIAE-sample  | variants in merged.vcf | variants in front |
| ------------ | ---------------------- | ----------------- |
| 20210545-008 | 54                     | 54                |
| 20210545-010 | 111                    | 111               |
| 20210545-011 | 102                    | 102               |

### Metrics

The metrics were compared of samples processed in vars2 and vars3, in a general manner (all genes) and specific manner (BRCA1 and BRCA2 only).

#### General comparrison
| sample       | platform | mean cov depth | uniformity | mean cov breadth (50x) | Q30    |
| ------------ | -------- | -------------- | ---------- | ---------------------- | ------ |
| 20210545-008 | vars2    | 696x           | 100%       | 100%                   | 94.15% |
| 20210545-008 | vars3    | 592.4x         | 96.04%     | 96.82%                 | 94.15% |
| 20210545-010 | vars2    | 1316x          | 100%       | 100%                   | 94.48% |
| 20210545-010 | vars3    | 1122.72x       | 95.05%     | 97.57%                 | 94.48% |
| 20210545-011 | vars2    | 1597x          | 99.97%     | 100%                   | 94.49% |
| 20210545-011 | vars3    | 1363.86x       | 95.1       | 98.09                  | 94.49% |

#### BRCA1 and BRCA2 comparrison
| BRCA1/2 sample | Platform | Média    | 10x     | 20x     | 30x     | 40x   | 50x     | 100x    | 200x    | 300x    | 400x  | 500x   |
| -------------- | -------- | -------- | ------- | ------- | ------- | ----- | ------- | ------- | ------- | ------- | ----- | ------ |
| 20210545-008   | vars2    | 676      | 100     | 100     | 100     | -     | 100     | 100     | 100     | 97      | -     | 73     |
| 20210545-008   | vars3    | 334.3    | 99.44   | 98.88   | 98.58   | 98.48 | 98.38   | 96.8    | 93.72   | 90.78   | 84.05 | 66.05  |
| 20210545-010   | vars2    | 1.280.47 | 100.00% | 100.00% | 100.00% | -     | 100.00% | 100.00% | 100.00% | 99.91%  | -     | 97.95% |
| 20210545-010   | vars3    | 639.06   | 99.56   | 99.47   | 98.99   | 98.8  | 98.68   | 98.33   | 97.27   | 94.88   | 93.45 | 91.66  |
| 20210545-011   | vars2    | 1.549.55 | 100.00% | 100.00% | 100.00% | -     | 100.00% | 100.00% | 100.00% | 100.00% | -     | 99.36% |
| 20210545-011   | vars3    | 768.12   | 99.55   | 99.52   | 99.42   | 99.25 | 99.07   | 98.53   | 97.71   | 96.35   | 95.25 | 94.02  |

We can notice a slight decrease in `mean covs` and `uniformity` (depth and breadth) when comparing vars3 with vars2 general metrics, as well as breath cov by different depth tresholds when comparing vars3 with vars2 platforms.

The major decrease was identified en mean of BRCA1 and BRCA2 comparrison, it can occur, owing the number of transcripts of BRCA1 in vars2 platform (only the NM_007294.4) and the 5 transcripts in BRCA1 in vars3 platform (NM_007294.4, NM_007297.4, NM_007298.3, NM_007299.4, NM_007300.4).

### UMI Metrics

* Pipeline version (WDL): **v1.1.0-rc1** (<https://github.com/Varstation/wdl-qiagen-dna-germline/releases/tag/v1.1.1-rc1>)

After the development of UMI metrics on Varstation 3.0, the functions specifically related to UMI informations were developed on wdl workflow. The full development registry can be [accessed here](https://github.com/Varstation/pipeline-validation/issues/53).

The rutine [validacao qiagen brca umi cap](https://web.varstation.com/#/routines/874/samples) with cap samples to compare with Vars2 values was created on `HIAE-GNMK Validação` organization.

| sample       | aplication | umi_depth | umi_target_cov |
| ------------ | ---------- | --------- | -------------- |
| 20210545-008 | vars2      | 194       | 100            |
| 20210545-008 | vars3      | 193.99    | 100            |
| 20210545-009 | vars2      | 1         | 0              |
| 20210545-009 | vars3      | 0         | 0              |
| 20210545-010 | vars2      | 477       | 100            |
| 20210545-010 | vars3      | 476.82    | 100            |
| 20210545-011 | vars2      | 618       | 100            |
| 20210545-011 | vars3      | 617.8     | 100            |



# Update version v1.2.0-rc1


After the analysis team observed DP values lower than DP_UMI in the 3.0 test samples, it was necessary to make corrections in the wdl workflow. The full development log can be [accessed here](https://github.com/Varstation/wdl-qiagen-dna-germline/pull/18)

* The routine in Vars 3 prod, chazanas-enterprises organization: [teste qiagen germline new metrics](https://web.varstation.com/#/routines/912/samples) with cap samples to compare with Vars2 values was created on `HIAE-GNMK Validação` organization.

* Pipeline version (WDL): **v1.2.0-rc1** (https://github.com/Varstation/wdl-qiagen-dna-germline/releases/tag/v1.2.0)

HIAE documentation: (<https://github.com/Varstation/procedimentos/wiki/Executar-rotinas-de-qiagen-somatic-e-Nextera>)


# Runnning tests with Kakuna

## Homolog environment


```bash
kakuna --workflow workflows/qiagen-dna-germline_v1.2.0.wdl \
--imports workflows/qiagen-dna-germline_v1.2.0.zip \
--template templates/qiagen-germline-brca.template.json \
--labels templates/qiagen.labels.json \
--key-column sampleName \
--inputs-dir inputs/ \
--cromwell-server https://3.209.91.65 \
--disable-ssl sample_sheets/sample-sheet-qiagen.csv 
s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/revalid_germline
```
Output path: `s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/revalid_germline`


## Evaluate against last validation results

### Copy files from aws

```bash
#get outputs from previous release
mkdir v1.0.0-rc2
aws s3 cp s3://cromwell-dragen-us-east-1/validation/Qiagen-germline/results/20211207_MS3262052-300V2_BRCA_20210545-GNMK-WDL/ v1.0.0-rc2/ --recursive

#get outputs from new release
mkdir v1.2.0-rc1
aws s3 cp s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/revalid_germline v1.2.0-rc1/ --recursive
```

### Compare variants

```bash
#extract variants from multianno of previous release and remove the "chr" from chromossome
for file in $(ls v1.0.0-rc2/*/*multianno.tsv.gz);do gunzip -c $file | cut -f 1,2,3,4 | sed -e "s/chr//g" > $file.variants.tsv;done

#extract variants from multianno of new release
for file in $(ls v1.2.0-rc2/*/*multianno.tsv.gz);do gunzip -c $file | cut -f 1,2,3,4 > $file.variants.tsv;done

#get differences
diff v1.0.0-rc2/20210545-008.multianno.tsv.gz.variants.tsv v1.2.0-rc1/20210545-008/20210545-008.multianno.tsv.gz.variants.tsv > diffs/20210545-008_v1.0.0_v1.2.0.diff
diff v1.0.0-rc2/20210545-010.multianno.tsv.gz.variants.tsv v1.2.0-rc1/20210545-010/20210545-010.multianno.tsv.gz.variants.tsv > diffs/20210545-010_v1.0.0_v1.2.0.diff
diff v1.0.0-rc2/20210545-011.multianno.tsv.gz.variants.tsv v1.2.0-rc1/20210545-011/20210545-011.multianno.tsv.gz.variants.tsv > diffs/20210545-011_v1.0.0_v1.2.0.diff
```
#### Whats changed?

All variants are the same in both releases.

The diff files were uploaded to `s3://bioinfo-resources-us-east-1/test-data/CAP/BRCA/revalid_test_diffs`

## Evaluate against Vars2 and Vars3

The qiagen-dna-germline was implemented on varstation 3.0 homolog application, in the `chazanas-enterprises` organization, as the `QIAGEN_BRCA_hg19` pipeline. The routine [qiagen_brca](https://web.varstation.com/#/routines/912/samples) was created.

### CAP

According to CAP, each of three samples should have a specific pathogen variant, according the following table:

| CAP-sample | HIAE-sample  | expected variant                    | hs37d5-locus |
| ---------- | ------------ | ----------------------------------- | ------------ |
| BRCA-04    | 20210545-008 | BRCA1:c.1204delG:p.(Glu402Serfs*8)  | 17:41246344  |
| BRCA-05    | 20210545-010 | BRCA2:c.581G>A:p.(Trp194Ter)        | 13:32900700  |
| BRCA-06    | 20210545-011 | BRCA1:c.2071delA:p.(Arg691Aspfs*10) | 17:41245477  | 

### Copy files from aws

```bash
#get outputs from Vars2
mkdir vars2
aws s3 cp s3://varstation-static/media/parquet/2021-12-8/GNMK_20210545-008_B_CTRLSEQ_2021-12-08_204212.annovar.hg19_multianno.parquet vars2/
aws s3 cp s3://varstation-static/media/parquet/2021-12-8/GNMK_20210545-009_CNS_CTRLSEQ_2021-12-08_200219.annovar.hg19_multianno.parquet vars2/
aws s3 cp s3://varstation-static/media/parquet/2021-12-8/GNMK_20210545-010_B_CTRLSEQ_2021-12-08_212216.annovar.hg19_multianno.parquet vars2/
aws s3 cp s3://varstation-static/media/parquet/2021-12-8/GNMK_20210545-011_B_CTRLSEQ_2021-12-08_213550.annovar.hg19_multianno.parquet vars2/

#get outputs from Vars3
mkdir vars3
aws s3 ls s3://vars-static-prod/HIAE-GNMK_Validacao_-_17/pipelines/Qiagen_Dna_Germline_BRCA_hs37d5-23/2023-04/teste_qiagen_germline_new_metrics vars3/ --recursive
```

### Vars3 app

The three samples presented the CAP expected variants in Vars3 application, Moreover, the platform showed the same number of variants of merged.vcf files of each sample.

| HIAE-sample  | variants in merged.vcf | variants in front |
| ------------ | ---------------------- | ----------------- |
| 20210545-008 | 54                     | 54                |
| 20210545-010 | 111                    | 111               |
| 20210545-011 | 103                    | 103               |

### Metrics

The metrics were compared of samples processed in vars2 and vars3, in a general manner (all genes) and specific manner (BRCA1 and BRCA2 only).

| Sample          | Mean cov depth Vars 2.0 | Mean cov depth Vars 3.0 | Uniformity Vars 2.0 | Uniformity Vars 3.0   | Mean cov breadth (50x)| Mean cov breadth (50x)| Q30 Vars2 | Q30 Vars 3    |
| ------------    | ----------------------- | --------------------    | ------------------- | -------------------   | ----------------------| ----------------------| ----------| ------------  |
| 20210545-008    | 696                     | 695.81                  | 100%                | 100%                  | 100%                  | 100%                  | 94.15%    | 94.15%        |
| 20210545-009    | 0                       | 0.09                    | 22.39%              | 22.39%                | 0%                    | 0%                    | 88.33%    | 88.33%        | 
| 20210545-010    | 1316                    | 1316.11                 | 100%                | 100%                  | 100%                  | 100%                  | 94.48%    | 94.48%        |
| 20210545-011    | 1597                    | 1597.46                 | 99.97%              | 99.97%                | 100%                  | 100%                  | 94.49%    | 94.49%        |


#### BRCA1 and BRCA2 comparrison
| BRCA1/2 sample | Platform | Média    | 10x     | 20x     | 30x     | 40x   | 50x     | 100x    | 200x    | 300x    | 400x  | 500x   |
| -------------- | -------- | -------- | ------- | ------- | ------- | ----- | ------- | ------- | ------- | ------- | ----- | ------ |
| 20210545-008   | Vars 2.0 | 647.86   | 100%    | 100%    | 99.97%  |       | 99.91%  | 99.81%  | 99.11%  | 95.62%  |       | 70.50% | 
| 20210545-008   | Vars 3.0 | 647.86   | 100%    | 100%    | 99.97%  | 99.93%| 99.91%  | 99.81%  | 99.11%  | 95.62%  | 88.66%| 70.5%  |
| 20210545-009   | Vars 2.0 | 0.03     | 0.00%   | 0.00%   | 0.00%   | -     | 0.00%   | 0.00%   | 0.00%   | 0.00%   | -     | 0.00%  | 
| 20210545-009   | Vars 3.0 | 0.03     | 0.00%   | 0.00%   | 0.00%   | 0.00% | 0.00%   | 0.00%   | 0.00%   | 0.00%   | 0.00% | 0.00%  |
| 20210545-010   | Vars 2.0 | 1,280.47 | 100.00% | 100.00% | 100.00% | -     | 100.00% | 100.00% | 100.00% | 99.91%  | -     | 97.95% |
| 20210545-010   | Vars 3.0 | 1,238.22 | 100%    | 100%    | 100%    | 100%  | 99.98%  | 99.91%  | 99.79%  | 99.37%  | 98.98%| 96.96% |
| 20210545-011   | Vars 2.0 | 1,486.79 | 100.00% | 100.00% | 100.00% | -     | 100.00% | 99.94%  | 99.79%  | 99.71%  | -     | 98.59% |
| 20210545-011   | Vars 3.0 | 1,486.78 | 100%    | 100%    | 100%    | 100%  | 100%    | 99.94%  | 99.79%  | 99.71%  | 99.4% | 98.59% |


### New UMI metrics for each variant per sample

The UMI metrics for all variants per sample processed in Vars 2 and Vars 3 can be found in the (link)[https://sbibae-my.sharepoint.com/:x:/r/personal/jose_bnj_einstein_br/Documents/Metrics_UMI_qiagen_germline.xlsx?d=w6857af667e49427fb4b8ee1610286c35&csf=1&web=1&e=LOrHe8].

