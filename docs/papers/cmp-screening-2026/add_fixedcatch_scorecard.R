suppressPackageStartupMessages({library(mse);library(data.table);library(jsonlite)})
out<-'output/cmp-working-paper-2026';x<-readRDS('/Users/jim/Downloads/tunfixc.rds');m<-metrics(om(x))$CJM;rp<-refpts(om(x));db<-readRDS(file.path(out,'fixed-catch-reconstructed-dynamic-b0.rds'))$CJM
flat<-function(q){z<-as.data.table(as.data.frame(q));z[,year:=as.integer(as.character(year))];z[,iter:=as.integer(as.character(iter))];z[,.(year,iter,data)]}
c<-flat(m$C);sb<-flat(m$SB);f<-flat(m$F);base<-flat(db)
a<-data.table(year=c$year,iter=c$iter,C=c$data,SB=sb$data,F=f$data,db0=base$data)
stopifnot(identical(c$year,base$year),identical(c$iter,base$iter),nrow(a)==27*500)
a<-merge(a,data.table(iter=1:500,sbmsy=as.numeric(rp['SBMSY',]),fmsy=as.numeric(rp['FMSY',]),sb0=as.numeric(rp['SB0',])),by='iter')
setorder(a,iter,year);a[,`:=`(ssb_db0=SB/db0,SBMSY=SB/sbmsy,FMSY=F/fmsy)]
a[,`:=`(previous_catch=shift(C),previous_ssb_db0=shift(ssb_db0)),by=iter]
a[,reduction:=1-C/previous_catch];a[,IACC:=100*abs(reduction)]
core<-melt(a[year %in% 2041:2050,.(C=mean(C),SBMSY=mean(SBMSY),FMSY=mean(FMSY),IACC=mean(IACC)),by=iter],id.vars='iter')[,.(raw_value=median(value)),by=.(statistic=variable)]
extra<-a[year %in% 2041:2050,.(SB0red=mean(SB/((sbmsy/sb0)*db0)<1 & FMSY>1),SSBbelow8dB0=mean(ssb_db0<.08),PC270=mean(C<270))]
extra<-melt(extra,measure.vars=names(extra),variable.name='statistic',value.name='raw_value')
cr<-a[year %in% 2027:2050,.(v=mean(pmax(reduction,0)*100)),by=iter][,.(raw_value=median(v))][,statistic:='Creduction']
cuts<-fread('output/catchdrop19/advice-summary.csv')[mp=='fixedcatch',.(statistic='CatchDrop20',raw_value)]
r<-rbindlist(list(core,extra,cr,cuts),use.names=TRUE)
meta<-unique(fread('doc/data/candidates/candidate_quilt_reference_summary.csv')[,.(statistic,metric,direction,years,summary)])
r<-merge(r,meta,by='statistic');stopifnot(nrow(r)==9,all(is.finite(r$raw_value)))
r<-r[,.(mp='Fixed catch (1,525 kt)',statistic,metric,raw_value,preferred_direction=direction,include=statistic %in% c('C','IACC','PC270','SSBbelow8dB0','CatchDrop20'),weight=1,years,summary,om_code='om11',om_label='Reference (om11)',component='CJM',n_iter=500L)]
all<-fread(file.path(out,'scorecards-all-oms.csv'))[mp!='Fixed catch (1,525 kt)'];all<-rbind(all,r)
fwrite(all,file.path(out,'scorecards-all-oms.csv'));write_json(all,file.path(out,'scorecards-all-oms.json'),dataframe='rows',auto_unbox=TRUE,pretty=FALSE,digits=16)
fwrite(r,file.path(out,'fixed-catch-scorecard.csv'))
cat('Added fixed catch to reference OM only; 9 available indicators, no fabricated robustness runs or VB metrics\n')
