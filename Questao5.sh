#!/usr/bin/bash
echo "Evaluating NGS reads"

cd 0.raw

mkdir fastqc && fastqc *.gz -o fastqc/ #avaliar arquivos fastqc

######################################################################################################################################

#Nessa seção utilizamos os pacotes bwa e samtools para indexar nossa referencia e mapear nossos reads contra ela, alem de classificar nosso arquivo BAM.

echo "mapping sequence"

cd ../
mkdir 1.mapping_sequence
cd 1.mapping_sequence


#bwa index #nesse codigo nao foi necessario rodar, pois foi fornecido o arquivo indexado
bwa mem ../0.raw/reference/hg19.fasta ../0.raw/510-7-BRCA_S8_L001_R1_001.fastq.gz ../0.raw/510-7-BRCA_S8_L001_R2_001.fastq.gz | samtools view -h -b -o output.raw.bam

echo "sort file"

samtools flagstat output.raw.bam > stats.txt # dados estatisticos do mapeamento
samtools sort -@ 2 -n output.raw.bam -o output.sorted.n.bam
samtools fixmate -m output.sorted.n.bam output.fixmate.bam
samtools sort -@ 2 output.fixmate.bam -o output.sorted.p.bam

echo "mark and delete duplicate"

samtools markdup -r -@ 2 output.sorted.p.bam output.dedup.bam

echo "index bam file"
samtools index output.dedup.bam

######################################################################################################################################

#Nessa seçao realizamos a chamada de variantes por meio do software freebayes

echo "variant calling"

cd ../
mkdir 2.variant_calling
cd 2.variant_calling
freebayes -f ../0.raw/reference/hg19.fasta -r chr13:32890433-32973045 -r chr17:41197559-41276257 -b ../1.mapping_sequence/output.dedup.bam --vcf output.vcf

echo "variant calling"

cd ../
mkdir 3.annotation
cd 3.annotation
snpEff -v hg19 ../2.variant_calling/output.vcf > output_ann.vcf