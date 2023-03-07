from Bio import SeqIO
import io

import shutil, tempfile


def incluir_linha(nome_arquivo):
    with open("input.txt") as orig, \
         tempfile.NamedTemporaryFile('w', delete=False) as out:
        for i, line in enumerate(orig):
            out.write(f'>nome_{i}\n')
            out.write(line)

    shutil.move(out.name, nome_arquivo)

    # incluir o texto "xyz" na terceira linha do arquivo
incluir_linha('arquivo.fasta')

def get_superstring(reads_list, superstring=''):
    if len(reads_list) == 0:
        return superstring

    elif len(superstring) == 0:
        superstring = reads_list.pop(0)
        return get_superstring(reads_list, superstring)

    else:
        for current_read_index in range(len(reads_list)):
            current_read = reads_list[current_read_index]
            current_read_length = len(current_read)

            for trial in range(current_read_length // 2):
                overlap_length = current_read_length - trial         
                
                if superstring.startswith(current_read[trial:]):
                    reads_list.pop(current_read_index)
                    return get_superstring(reads_list, current_read[:trial] + superstring)          

                if superstring.endswith(current_read[:overlap_length]):
                    reads_list.pop(current_read_index)
                    return get_superstring(reads_list, superstring + current_read[overlap_length:])

with open('resultado_desafio_4.txt', 'w') as arquivo:
    if __name__ == "__main__":
    
        substrings = open("arquivo.fasta", "r")

        reads = []
        for record in SeqIO.parse(substrings, 'fasta'):
            reads.append(str(record.seq))
        print(reads)
        substrings.close()
        cromossomo = get_superstring(reads)
        arquivo.write(cromossomo)
        print(cromossomo)