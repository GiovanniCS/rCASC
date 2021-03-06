#' @title Scanpy Permutation
#' @description This function executes a ubuntu docker that produces a specific number of permutation to evaluate clustering.
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param file, a character string indicating the path of the file, with file name and extension included
#' @param nPerm, number of permutations to perform the pValue to evaluate clustering
#' @param permAtTime, number of permutations that can be computes in parallel
#' @param percent, percentage of randomly selected cells removed in each permutation
#' @param separator, separator used in count file, e.g. '\\t', ','
#' @param perplexity, perplexity number for tsne projection, default 10
#' @param pca_number, 	0 for automatic selection of PC elbow.
#' @param seed, important value to reproduce the same results with same input
#' @param sparse, boolean for sparse matrix
#' @param format, output file format csv or txt

#' @author Luca Alessandri, alessandri [dot] luca1991 [at] gmail [dot] com, University of Torino
#'
#' @return To write
#' @examples
#' \dontrun{
#'  system("wget http://130.192.119.59/public/section4.1_examples.zip")
#'  unzip("section4.1_examples.zip")
#'  setwd("section4.1_examples")

#'  system("wget ftp://ftp.ensembl.org/pub/release-94/gtf/homo_sapiens/Homo_sapiens.GRCh38.94.gtf.gz")
#'  system("gzip -d Homo_sapiens.GRCh38.94.gtf.gz")
#'  system("mv Homo_sapiens.GRCh38.94.gtf genome.gtf")
#'  scannobyGtf(group="docker", file=paste(getwd(),"bmsnkn_5x100cells.txt",sep="/"),
#'              gtf.name="genome.gtf", biotype="protein_coding", 
#'              mt=TRUE, ribo.proteins=TRUE,umiXgene=3)
#'  
#'  seuratBootstrap(group="docker",scratch.folder="/data/scratch/",
#'       file=paste(getwd(), "annotated_bmsnkn_5x100cells.txt", sep="/"), 
#'       nPerm=160, permAtTime=8, percent=10, separator="\t",
#'       logTen=0, pca_number=6, seed=111)
#'}

#' @export
scanpyPermutation <- function(group=c("sudo","docker"), scratch.folder, file, nPerm, permAtTime, percent, separator, perplexity,pca_number,seed=1111,sparse=TRUE,format="NULL"){

if(!sparse){
  data.folder=dirname(file)
positions=length(strsplit(basename(file),"\\.")[[1]])
matrixNameC=strsplit(basename(file),"\\.")[[1]]
matrixName=paste(matrixNameC[seq(1,positions-1)],collapse="")
format=strsplit(basename(basename(file)),"\\.")[[1]][positions]
}else{
  matrixName=strsplit(dirname(file),"/")[[1]][length(strsplit(dirname(file),"/")[[1]])]
  data.folder=paste(strsplit(dirname(file),"/")[[1]][-length(strsplit(dirname(file),"/")[[1]])],collapse="/")
  if(format=="NULL"){
  stop("Format output cannot be NULL for sparse matrix")
  }
}

  #running time 1
  ptm <- proc.time()
  #setting the data.folder as working folder
  if (!file.exists(data.folder)){
    cat(paste("\nIt seems that the ",data.folder, " folder does not exist\n"))
    system("echo 2 > ExitStatusFile 2>&1")
    return(2)
  }

  #storing the position of the home folder
  home <- getwd()
  setwd(data.folder)
  #initialize status
  system("echo 0 > ExitStatusFile 2>&1")

  #testing if docker is running
  test <- dockerTest()
  if(!test){
    cat("\nERROR: Docker seems not to be installed in your system\n")
    system("echo 10 > ExitStatusFile 2>&1")
    setwd(home)
    return(10)
  }



  #check  if scratch folder exist
  if (!file.exists(scratch.folder)){
    cat(paste("\nIt seems that the ",scratch.folder, " folder does not exist\n"))
    system("echo 3 > ExitStatusFile 2>&1")
    setwd(data.folder)
    return(3)
  }
  tmp.folder <- gsub(":","-",gsub(" ","-",date()))
  scrat_tmp.folder=file.path(scratch.folder, tmp.folder)
  writeLines(scrat_tmp.folder,paste(data.folder,"/tempFolderID", sep=""))
  cat("\ncreating a folder in scratch folder\n")
  dir.create(file.path(scrat_tmp.folder))
  #preprocess matrix and copying files

if(separator=="\t"){
separator="tab"
}

 dir.create(paste(scrat_tmp.folder,"/",matrixName,sep=""))
 dir.create(paste(data.folder,"/Results",sep=""))
 if(sparse==FALSE){
system(paste("cp ",data.folder,"/",matrixName,".",format," ",scrat_tmp.folder,"/",sep=""))
}else{
system(paste("cp -r ",data.folder,"/",matrixName,"/ ",scrat_tmp.folder,"/",sep=""))

}

  #executing the docker job
    params <- paste("--cidfile ",data.folder,"/dockerID -v ",scrat_tmp.folder,":/scratch -v ", data.folder, ":/data -d docker.io/repbioinfo/scanpypermutation python3 /home/main2.py ",matrixName," ",nPerm," ",percent," ",format," ",separator," ",perplexity," ",pca_number," ",seed," ",permAtTime,sep="")

resultRun <- runDocker(group=group, params=params)

  #waiting for the end of the container work
  if(resultRun==0){
    #system(paste("cp ", scrat_tmp.folder, "/* ", data.folder, sep=""))
  }
  #running time 2
  ptm <- proc.time() - ptm
  dir <- dir(data.folder)
  dir <- dir[grep("run.info",dir)]
  if(length(dir)>0){
    con <- file("run.info", "r")
    tmp.run <- readLines(con)
    close(con)
    tmp.run[length(tmp.run)+1] <- paste("scanpyPermutation user run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("scanpyPermutation system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("scanpyPermutation elapsed run time mins ",ptm[3]/60, sep="")
    writeLines(tmp.run,"run.info")
  }else{
    tmp.run <- NULL
    tmp.run[1] <- paste("scanpyPermutation run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("scanpyPermutation system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("scanpyPermutation elapsed run time mins ",ptm[3]/60, sep="")

    writeLines(tmp.run,"run.info")
  }

  #saving log and removing docker container
  container.id <- readLines(paste(data.folder,"/dockerID", sep=""), warn = FALSE)
  system(paste("docker logs ", substr(container.id,1,12), " &> ",data.folder,"/", substr(container.id,1,12),"_scanpyPermutation.log", sep=""))
  system(paste("docker rm ", container.id, sep=""))


  #Copy result folder
  cat("Copying Result Folder")
  system(paste("cp -r ",scrat_tmp.folder,"/* ",data.folder,"/Results",sep=""))
  #removing temporary folder
  cat("\n\nRemoving the temporary file ....\n")
  system(paste("rm -R ",scrat_tmp.folder))
  system("rm -fR out.info")
  system("rm -fR dockerID")
#  system("rm  -fR tempFolderID")
  system(paste("cp ",paste(path.package(package="rCASC"),"containers/containers.txt",sep="/")," ",data.folder, sep=""))
  setwd(home)
} 
