#! /usr/bin/python

import sys
import os
from Bio import SeqIO


def cal_records_size(records):
    return sum([len(x.seq) for x in records])


def parseFastaFile(size_limit, fasta, out):
    # output file prefix
    fasta_out = out + "/" + os.path.basename(fasta)[:-3]

    # calculating size_limit in bytes from MiB
    size_limit = size_limit * (1024 ** 2)
    print(f"size limit requested - {size_limit}")
    
    # print message on stdout
    print(f"Generating split fasta files for the reference sequence {os.path.basename(fasta)} ...")

    with open(fasta) as f:
        split_count = 1
        records_to_write = []
        for record in SeqIO.parse(f, "fasta"):
            records_to_write.append(record)
            if cal_records_size(records_to_write) >= size_limit:
                with open(f"{fasta_out}_split_{split_count}.fa", "w") as w:
                    SeqIO.write(records_to_write[:-1], w, "fasta")
                records_to_write = [records_to_write.pop()]
                split_count += 1
        with open(f"{fasta_out}_split_{split_count}.fa", "w") as w:
                    SeqIO.write(records_to_write, w, "fasta")


if __name__ == "__main__":
    fasta = sys.argv[1]
    limit = float(sys.argv[2])
    out = sys.argv[3]
    parseFastaFile(limit, fasta, out)
