echo "Evaluating NGS reads"

cd 0.raw

mkdir fastqc && fastqc *.gz -o fastqc/

gzip -d Amostra01_R1_001.fastq.gz
gzip -d Amostra01_R2_001.fastq.gz

######################################################################################################################################


echo "Trimming first 18 pb and last 3 pb"

cd ../
mkdir 1.trimmed
cd 1.trimmed
mkdir fastx
cd fastx

fastx_trimmer -f 18 -i ../../0.raw/Amostra01_R1_001.fastq -o R1_18.fastq -Q 33 
fastx_trimmer -f 18 -i ../../0.raw/Amostra01_R2_001.fastq -o R2_18.fastq -Q 33

fastx_trimmer -z -t 3 -i R1_18.fastq -o R1.fastq.gz -Q 33
fastx_trimmer -z -t 3 -i R2_18.fastq -o R2.fastq.gz -Q 33

cd ../

echo "Filtering reads L 17 Q 20"

sickle pe -g -f fastx/R1_18.fastq.gz -r fastx/R2_18.fastq.gz -t sanger -o R1.fastq.gz -p R2.fastq.gz -s s.fastq.gz -l 17 -q 20 > log.txt

mkdir fastqc && fastqc *.fastq.gz -o fastqc

######################################################################################################################################

cd ../

echo "SPADES assembly"


spades.py -o spadesout -1 1.trimmed/R1.fastq.gz -2 1.trimmed/R2.fastq.gz -s 1.trimmed/s.fastq.gz -t 4

######################################################################################################################################

