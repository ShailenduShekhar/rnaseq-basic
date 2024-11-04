#!/usr/bin/python

import sys
import os
from pathlib import Path
import re
from pydeseq2.dds import DeseqDataSet
from pydeseq2.ds import DeseqStats
import pandas as pd

import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.decomposition import PCA


def prepare_df(df):
    print(f"DataFrame Shape (before processing): {df.shape}")

    # renaming the columns
    print("Renaming columns ...")
    for col in df.columns:
        df.rename(columns = {col : re.sub(r".bam", "", os.path.basename(col))}, inplace = True)

    # getting rid of unwanted columns
    print("Filtering out unnecessary columns from the featureCounts output ...")
    df = df.loc[:, ~cmat.columns.isin(["Chr", "Start", "End", "Strand", "Length"])]

    # setting the Geneid column as index
    df = df.set_index("Geneid")

    # Excluding all rows which have only zeroes
    print("Filtering out all rows with a sum total of 0 read counts ...")
    df = df[df.sum(axis = 1) > 0]

    # transposing the count matrix
    print("Transposing the dataframe in order to make it compatible for PyDeSeq2 module ...")
    df = df.T

    print("DataFrame is ready.")
    print(f"DataFrame Shape (after processing): {df.shape}")

    return df

def deseq_analysis(cmat, md, formula, outdir):
    # creating the necessary directories
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    dds = DeseqDataSet(
        counts = cmat,
        metadata = md,
        design_factors = formula.split(","),
    )

    # running deseq2
    dds.deseq2()

    # extracting the normalized counts
    norm_df = pd.DataFrame(dds.layers["normed_counts"], columns=cmat.columns, index=cmat.index)

    # generating and saving the correlation matrix
    corr_matrics = norm_df.T.corr()
    corr_matrics.to_csv(outdir / "all_samples_correlation.matrix", index=False)

    # image quality control
    dpi=300

    # plotting the correlation matrix as a heatmap
    sns.heatmap(corr_matrics, annot=True)
    plt.savefig(outdir / "all_samples_correlation.heatmap.png", dpi=dpi, bbox_inches='tight')
    plt.clf()

    # PCA of samples using the normalized counts
    pca = PCA(n_components=2)

    pcomp = pca.fit_transform(norm_df)

    pca_df = pd.DataFrame(data=pcomp , columns = ['PC1', 'PC2'])
    pca_df['Sample'] = norm_df.index

    sns.scatterplot(data=pca_df, x="PC1", y="PC2", hue="Sample", palette='tab10')
    plt.savefig(outdir / "all_samples_norm_count.pca.png", dpi=dpi, bbox_inches='tight')
    plt.clf()

    # scatterplot across all possible combinations of the sample in pairs
    scatter_plot_dir = outdir / "scatter_plots"
    scatter_plot_dir.mkdir(parents=True, exist_ok=True)

    for i in range(norm_df.shape[0]):
        for j in range(i+1, norm_df.shape[0]):
            sns.scatterplot(x=norm_df.iloc[i], y=norm_df.iloc[j])
            plt.savefig(f"{scatter_plot_dir}/scatterplot_{norm_df.index[i]}_{norm_df.index[j]}.png", dpi=300, bbox_inches='tight')
            plt.clf()

    # generating statistical summary of differentially expressed genes
    diff_expr = outdir / "differential_expression"
    diff_expr.mkdir(parents=True, exist_ok=True)

    stat_res = DeseqStats(dds, contrast = ("Tissue", "Heart", "Liver"))
    stat_res.summary()
    stat_res.results_df.to_csv(f"{diff_expr}/Heart_vs_Liver.tsv", sep="\t", index=False)

    stat_res = DeseqStats(dds, contrast = ("Time", "0", "12"))
    stat_res.summary()
    stat_res.results_df.to_csv(f"{diff_expr}/0_vs_12.tsv", sep="\t", index=False)


if __name__ == "__main__":
    cmat = pd.read_csv(sys.argv[1], sep="\t", skiprows=[0])
    metadata = pd.read_csv(sys.argv[2])
    formula = sys.argv[3]
    outdir = sys.argv[4]

    cmat = prepare_df(cmat)
    #print(cmat.head(5))
    #print(cmat.columns)
    #print(cmat.index)
    print("Preparing the metadata file ...")
    metadata = metadata.set_index("Sample")
    #print(metadata)

    print("Initiating the deseq2 pipeline and associated statistical analysis ...")
    deseq_analysis(cmat, metadata, formula, outdir)
    print(f"Matrices and plots are saved to {outdir}")
