# Reproduce the 500-draw CMP working-paper data and figures from saved outputs.
suppressPackageStartupMessages({library(data.table); library(ggplot2); library(ggrepel); library(mse)})
out <- Sys.getenv('JMMSE_CMP_PAPER_OUT', 'output/cmp-working-paper-2026')
dir.create(out, recursive=TRUE, showWarnings=FALSE)
labels <- c(tun29='HS+20',tun43='HS-20',tun45='HSsym',tun47='HS-30',tun32='PR+20',tun44='PR-20',tun46='PRsym',tun48='PR-30')
keep <- strsplit(Sys.getenv('JMMSE_CMP_FOCUS','tun43,tun47,tun44'),',',fixed=TRUE)[[1]]
stopifnot(length(keep)==3,all(keep %in% names(labels)))
q <- fread('doc/data/candidates/candidate_quilt_reference_summary.csv')
q[, code := paste0('tun', sub('.*MP([0-9]+).*','\\1',mp))]
w <- dcast(q, code~statistic,value.var='value')
primary <- c('C','IACC','PC270','SSBbelow8dB0','CatchDrop20')
tolerances <- c(C=40,IACC=.6,PC270=.01,SSBbelow8dB0=.01,CatchDrop20=.01)
direction <- c(C=1,IACC=-1,PC270=-1,SSBbelow8dB0=-1,CatchDrop20=-1)
screen <- data.table(code=c('tun29','tun45','tun32','tun46','tun48'),
  comparator=c('tun43','tun43','tun43','tun44','tun47'),
  disposition=c('Close alternative','Close alternative','Poorer within screening tolerances','Close alternative','Poorer within screening tolerances'))
for(i in seq_len(nrow(screen))) {
  from <- unlist(w[code==screen$code[i],..primary]); to <- unlist(w[code==screen$comparator[i],..primary])
  benefit <- (to-from)*direction
  similar <- all(abs(to-from)<=tolerances)
  poorer <- all(benefit>=-tolerances) && any(benefit>tolerances)
  screen$disposition[i] <- if(similar) 'Close alternative' else if(poorer) 'Poorer within screening tolerances' else 'Trade-off; review all CMPs'
}
screen[, `:=`(CMP=labels[code], comparator_label=labels[comparator])]
fwrite(screen,file.path(out,'screening.csv'))
fwrite(data.table(statistic=primary,tolerance=as.numeric(tolerances)),file.path(out,'screening-tolerances.csv'))
fwrite(q,file.path(out,'all-cmp-quilt-values.csv'))
md_table <- function(x,file) {
  writeLines(c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),apply(x,1,function(r)paste0('| ',paste(r,collapse=' | '),' |'))),file)
}
md_table(screen[,.(CMP,Disposition=disposition,Representative=comparator_label)],file.path(out,'screening.md'))
compact <- dcast(q[statistic %in% primary],mp~statistic,value.var='display_value')
md_table(compact,file.path(out,'all-cmp-values.md'))
files <- c(reference='output/candidate-performance-500/reference/performance_with_vb.rds',robustness='output/candidate-performance-500/robustness/performance_with_vb.rds')
byiter <- rbindlist(lapply(names(files),function(mode) {
  x<-as.data.table(readRDS(files[[mode]])); x[,code:=sub('_om.*$','',mp)]
  x[year %in% 2041:2050 & statistic %in% c('C','IACC','SBMSY'),.(value=mean(data)),by=.(om,biol,code,iter,statistic)][,set:=mode]
}))
stopifnot(!anyNA(byiter$value),all(byiter[,uniqueN(iter),by=.(om,biol,code,statistic)]$V1==500))
s <- byiter[,.(median=median(value),q25=quantile(value,.25),q75=quantile(value,.75)),by=.(set,om,biol,code,statistic)]
s[,CMP:=labels[code]]
fwrite(s,file.path(out,'tradeoff-summary-all-cmps.csv'))
wide <- dcast(s,set+om+biol+code+CMP~statistic,value.var=c('median','q25','q75'))
palette <- setNames(c('#996029','#277b4d','#246cac'),labels[keep])
tradeplot <- function(dat,y,title,facet=FALSE) {
 p<-ggplot(dat,aes(x=median_C,y=.data[[paste0('median_',y)]],colour=CMP,shape=CMP))+
  geom_segment(aes(x=q25_C,xend=q75_C,yend=.data[[paste0('median_',y)]]),linewidth=.55)+
  geom_segment(aes(y=.data[[paste0('q25_',y)]],yend=.data[[paste0('q75_',y)]],xend=median_C),linewidth=.55)+
  geom_point(size=2.8)+scale_colour_manual(values=palette)+ggthemes::theme_few(base_size=11)+
  labs(x='Median annual catch (thousand t)',y=if(y=='IACC')'Median interannual catch change (%)' else 'Median SSB / static SSBMSY',
    title=title,subtitle='2041–2050 means within simulations; points are medians; bars are interquartile ranges',
    caption='500 simulations per CMP and OM/component. Crash trajectories are retained in these trade-offs.')+
  theme(legend.position='bottom',plot.caption=element_text(size=9))
 if(facet) {
  floor_panels <- dat[,.(floor=all(median_C < .001)),by=.(om,biol)][floor==TRUE]
  if(nrow(floor_panels)) {
    anchors <- floor_panels[,.(x=c(0,1),y=c(0,1)),by=.(om,biol)]
    p <- p+geom_blank(data=anchors,aes(x,y),inherit.aes=FALSE)+
      geom_text(data=floor_panels,aes(x=.5,y=.65,label='Near-zero catch; no meaningful ranking'),
        inherit.aes=FALSE,size=3,colour='grey35')
  }
  p<-p+facet_wrap(~om+biol,scales='free',ncol=2)
 }
 else p<-p+geom_text_repel(aes(label=CMP),show.legend=FALSE,seed=42)
 p
}
for(y in c('IACC','SBMSY')) {
 p<-tradeplot(wide[set=='reference' & code %in% keep],y,'Reference OM: retained CMPs')
 ggsave(file.path(out,paste0('reference-',y,'.png')),p,width=9,height=5.8,dpi=160)
 for(group in c('single','two')) {
  d<-wide[set=='robustness' & code %in% keep & if(group=='single')biol=='CJM' else biol!='CJM']
  p<-tradeplot(d,y,paste(if(group=='single')'Single-stock' else 'Two-stock','robustness OMs'),TRUE)
  ggsave(file.path(out,paste0('robustness-',group,'-',y,'.png')),p,width=11,height=if(group=='single')10 else 12,dpi=160)
 }
}
# Diagnostic: no retained CMP can be declared best across OMs from this screen.
fwrite(wide,file.path(out,'all-om-tradeoffs.csv'))
ids <- fread('doc/data/candidates/catch_spaghetti_reference_iterations.csv')$iter
stopifnot(length(ids)==15,uniqueN(ids)==15)
runsfile <- '../jmMSE-500-refine/model/tune/refine_500_from_100/runs.rds'
runs <- readRDS(runsfile)
worms <- rbindlist(lapply(keep,function(code) {
 met<-metrics(om(runs[[code]]))$CJM
 rbindlist(lapply(c('SB','C'),function(metric) {
  stopifnot(as.character(units(met[[metric]]))=='1000 t')
  z<-as.data.table(as.data.frame(met[[metric]]))
  z[,year:=as.integer(as.character(year))]; z[,iter:=as.integer(as.character(iter))]
  z[year %in% 2025:2050 & iter %in% ids,.(code,year,iter,metric,data)]
 }))
}))
stopifnot(nrow(worms)==3*2*15*26,!anyNA(worms$data),!anyDuplicated(worms[,.(code,year,iter,metric)]))
worms[,`:=`(CMP=factor(labels[code],levels=labels[keep]),Metric=factor(ifelse(metric=='SB','Spawning biomass (thousand t)','Catch (thousand t)'),levels=c('Spawning biomass (thousand t)','Catch (thousand t)')))]
fwrite(worms,file.path(out,'worm-trajectories.csv')); fwrite(data.table(iter=ids),file.path(out,'worm-iterations.csv'))
p<-ggplot(worms,aes(year,data,group=iter,colour=factor(iter)))+geom_line(linewidth=.5,alpha=.85)+
 facet_grid(Metric~CMP,scales='free_y')+scale_colour_viridis_d(option='turbo',name='Simulation')+
 ggthemes::theme_few(base_size=11)+theme(legend.position='bottom')+labs(x='Year',y=NULL,title='15 matched simulation trajectories',
 subtitle='Same iteration IDs in every CMP and metric panel; all selected trajectories retained',
 caption='Selected simulation paths; uncertainty summaries use all 500 simulations. Values are thousand tonnes; scales are shared across CMPs within each row.')
ggsave(file.path(out,'worms-15.png'),p,width=12,height=7.8,dpi=170)
inputs<-c(files,runsfile,'doc/data/candidates/candidate_quilt_reference_summary.csv','doc/data/candidates/catch_spaghetti_reference_iterations.csv')
writeLines(c(paste(names(tools::md5sum(inputs)),tools::md5sum(inputs)),capture.output(sessionInfo())),file.path(out,'provenance.txt'))
cat('Working-paper figures, screening, and data verified\n')

for (f in c("candidate_quilt_catch_cut_diagnostics_reference.csv", "candidate_quilt_event_counts_reference.csv")) file.copy(file.path("doc/data/candidates",f),file.path(out,f),overwrite=TRUE)
file.copy("output/catchdrop19/advice-summary.csv",file.path(out,"catchdrop19-advice-summary.csv"),overwrite=TRUE)
