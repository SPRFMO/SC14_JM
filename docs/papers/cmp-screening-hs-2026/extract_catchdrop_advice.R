suppressPackageStartupMessages({library(mse);library(data.table)})
source('R/catchdrop_advice.R')
out <- 'output/catchdrop19';dir.create(out,recursive=TRUE,showWarnings=FALSE)
files <- c(om11='../jmMSE-500-refine/model/tune/refine_500_from_100/runs.rds',
 setNames(list.files('../jmMSE-500-refine/model/candidates/robustness_500/checkpoints',pattern='\\.rds$',full.names=TRUE),
 tools::file_path_sans_ext(list.files('../jmMSE-500-refine/model/candidates/robustness_500/checkpoints',pattern='\\.rds$'))))
parts<-list()
for(i in seq_along(files)){
 message('Extract advice: ',names(files)[i]);runs<-readRDS(files[i])
 z<-rbindlist(lapply(seq_along(runs),function(j)extract_advice_events(runs[[j]],sub('_om.*$','',names(runs)[j]))))
 stopifnot(uniqueN(z$mp)==8,identical(sort(unique(z$iter)),1:500))
 z[,om_code:=names(files)[i]];parts[[i]]<-z;rm(runs);gc(verbose=FALSE)
}
x<-readRDS('/Users/jim/Downloads/tunfixc.rds')
z<-extract_advice_events(x,'fixedcatch');z[,om_code:='om11'];parts[[length(parts)+1L]]<-z
all<-rbindlist(parts);fwrite(all,file.path(out,'advice-events.csv'))
s<-all[,summarize_advice_events(.SD),by=om_code]
stopifnot(all(s$iterations==500),all(s$available_records==12500))
fwrite(s,file.path(out,'advice-summary.csv'))
fwrite(data.table(path=c(unname(files),'/Users/jim/Downloads/tunfixc.rds'),md5=unname(tools::md5sum(c(files,'/Users/jim/Downloads/tunfixc.rds')))),file.path(out,'provenance.csv'))
print(s[om_code=='om11']);cat('Checked',nrow(s),'OM/CMP advice series\n')
