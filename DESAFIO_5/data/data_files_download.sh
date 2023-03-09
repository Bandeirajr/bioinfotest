
#Download the sample file (R1 e R2 FASTQs)

wget -c https://bioinfotest.s3.amazonaws.com/510-7-BRCA_S8_L001_R1_001.fastq.gz
wget -c https://bioinfotest.s3.amazonaws.com/510-7-BRCA_S8_L001_R2_001.fastq.gz



#Download the human genome hg19 fasta file and the indexed file to use with BWA.

mkdir -p ./bwa

wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.fai
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.amb
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.bwt
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.pac
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.sa
wget -c https://bioinfotest.s3.amazonaws.com/bwa/hg19.fasta.ann







