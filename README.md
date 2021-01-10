# Stardust
Stardust is distributed as a method of the R package rCASC. The main reason is the ability to expoit its built-in stability score computation feature. In this workflow we well see how to set up the environment end execute an example.



## Installation
```bash
#check if docker is installed
docker -v
docker pull giovannics/spatial2020seuratpermutation
docker pull repbioinfo/seuratanalysis
mkdir -p example/scratch && cd example
wget https://github.com/GiovanniCS/StardustData/raw/main/Datasets/MouseKidney/filtered_expression_matrix.txt.zip
wget https://raw.githubusercontent.com/GiovanniCS/StardustData/main/Datasets/MouseKidney/spot_coordinates.txt
unzip filtered_expression_matrix.txt.zip
rm -rf __MACOSX
rm filtered_expression_matrix.txt.zip
R
```
```R
install.packages("devtools")
library(devtools)
install_github("GiovanniCS/rCASC")
library(rCASC)
scratch.folder <- paste(getwd(),"/scratch",sep="")
file <- paste(getwd(),"/filtered_expression_matrix.txt",sep="")
tissuePosition <- paste(getwd(),"/spot_coordinates.txt",sep="")
StardustPermutation(group="docker",scratch.folder = scratch.folder,nPerm=80,
    file=file, tissuePosition=tissuePosition, spaceWeight=j, permAtTime=8, 
    percent=10, separator="\t", logTen=0, pcaDimensions=5, seed=111)
cluster.path <- paste(data.folder=dirname(file), "Results", strsplit(basename(file),"\\.")[[1]][1], sep="/")
cluster <- as.numeric(list.dirs(cluster.path, full.names = FALSE, recursive = FALSE))
permAnalysisSeurat(group="docker",scratch.folder = scratch.folder,file=file, nCluster=cluster,separator="\t",sp=0.8)
```

## Results 
You can now explore the content of example/Results to find the stability scores and
cluster id assignments.