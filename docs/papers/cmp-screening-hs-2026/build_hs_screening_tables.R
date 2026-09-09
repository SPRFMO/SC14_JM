suppressPackageStartupMessages(library(data.table))
out<-'output/cmp-working-paper-hs-2026'
q<-fread('doc/data/candidates/candidate_quilt_reference_summary.csv')
q[,code:=paste0('tun',sub('.*MP([0-9]+).*','\\1',mp))]
keep<-c('tun29','tun45','tun43');primary<-c('C','IACC','PC270','SSBbelow8dB0','CatchDrop20')
tol<-c(C=40,IACC=.6,PC270=.01,SSBbelow8dB0=.01,CatchDrop20=.01)
direction<-c(C=1,IACC=-1,PC270=-1,SSBbelow8dB0=-1,CatchDrop20=-1)
w<-dcast(q[code %in% keep],code~statistic,value.var='value')
rows<-rbindlist(lapply(keep,function(a)rbindlist(lapply(setdiff(keep,a),function(b){
 va<-unlist(w[code==a,..primary]);vb<-unlist(w[code==b,..primary]);benefit<-(va-vb)*direction
 data.table(CMP=q[code==a,unique(mp)],Comparator=q[code==b,unique(mp)],
 Result=if(all(abs(va-vb)<=tol))'Within all tolerances' else if(all(benefit>=-tol)&&any(benefit>tol))'Better within tolerances' else if(all(benefit<=tol)&&any(benefit< -tol))'Poorer within tolerances' else 'Trade-off',
 Basis=paste(primary[abs(va-vb)>tol],collapse=', '))
}))))
write_table<-function(x,p)writeLines(c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),apply(x,1,function(r)paste0('| ',paste(r,collapse=' | '),' |'))),p)
fwrite(rows,file.path(out,'screening.csv'));write_table(rows,file.path(out,'screening.md'))
compact<-dcast(q[code %in% keep & statistic %in% primary],mp~statistic,value.var='display_value');write_table(compact,file.path(out,'all-cmp-values.md'))
fwrite(q[code %in% keep],file.path(out,'selected-cmp-quilt-values.csv'))
print(rows)
