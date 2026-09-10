# Focus the existing paper on recruitment crash and OM11_3; inspect the supplied
# fixed-catch run in isolation. Do not overwrite or modify the input RDS.
suppressPackageStartupMessages({library(mse);library(FLasher);library(data.table);library(ggplot2);library(ggrepel)})
out<-Sys.getenv('JMMSE_CMP_PAPER_OUT','output/cmp-working-paper-2026')
keep<-strsplit(Sys.getenv('JMMSE_CMP_FOCUS','tun43,tun47,tun44'),',',fixed=TRUE)[[1]]; labels<-c(tun29='HS+20',tun45='HSsym',tun43='HS-20',tun47='HS-30',tun44='PR-20')
palette<-setNames(c('#996029','#277b4d','#246cac'),labels[keep])
# Reuse plotting and table helpers without rerunning the original analysis.
e<-parse('R/build_cmp_screening_paper.R')
for(x in e)if(is.call(x)&&identical(x[[1]],as.name('<-'))&&as.character(x[[2]])[1] %in% c('tradeplot','md_table'))eval(x)
wide<-fread(file.path(out,'all-om-tradeoffs.csv'))
focus<-wide[code %in% keep & om %in% c('h1_0.16','h1_0.16_lowrec','h1_0.16_cycle')]
stopifnot(nrow(focus)==9)
focus[,om:=factor(om,levels=c('h1_0.16','h1_0.16_lowrec','h1_0.16_cycle'),labels=c('Reference OM','Recruitment crash (om11_2)','Recruitment cycle (om11_3)'))]
for(y in c('IACC','SBMSY'))ggsave(file.path(out,paste0('focused-robustness-',y,'.png')),
 tradeplot(focus,y,'Three CMPs: reference, recruitment crash and OM11_3',TRUE),width=11,height=8.5,dpi=160)
fwrite(focus,file.path(out,'focused-robustness-tradeoffs.csv'))
ids<-fread(file.path(out,'worm-iterations.csv'))$iter
flat<-function(q){z<-as.data.table(as.data.frame(q));z[,year:=as.integer(as.character(year))];z[,iter:=as.integer(as.character(iter))];stopifnot(!anyDuplicated(z[,.(year,iter)]));z[,.(year,iter,data)]}
checkpoints<-c(om11_2='../jmMSE-500-refine/model/candidates/robustness_500/checkpoints/om11_2.rds',om11_3='../jmMSE-500-refine/model/candidates/robustness_500/checkpoints/om11_3.rds')
wormparts<-list();riskparts<-list();input_baselines<-character()
for(scenario in names(checkpoints)) {
 message('Reading ',scenario)
 runs<-readRDS(checkpoints[[scenario]])
 for(code in keep) {
  nm<-paste0(code,'_',scenario);stopifnot(nm %in% names(runs))
  run<-runs[[nm]]; db0<-attr(run,'unfishedSSB')
  if(is.null(db0))stop('Matching stored dynamic B0 is missing: ',nm)
  ms<-metrics(om(run)); rp<-refpts(om(run))
  for(b in names(ms)) {
   m<-ms[[b]]; rr<-if(is(rp,'FLPars'))rp[[b]] else rp
   for(metric in c('SB','C')) {
    stopifnot(as.character(units(m[[metric]]))=='1000 t')
    z<-flat(m[[metric]])[year %in% 2025:2050 & iter %in% ids]
    stopifnot(nrow(z)==15*26)
    z[,`:=`(scenario=scenario,biol=b,code=code,metric=metric)]
    wormparts[[length(wormparts)+1L]]<-z
   }
   yrs<-ac(2041:2050);ss<-m$SB[,yrs];ff<-m$F[,yrs];base<-db0[[b]][,yrs]
   stopifnot(identical(dim(ss),dim(base)),all(is.finite(c(base))),all(c(base)>0),dim(ss)[6]==500)
   riskparts[[length(riskparts)+1L]]<-data.table(scenario=scenario,biol=b,code=code,
    green=mean(c(ss/((rr['SBMSY',]/rr['SB0',])*base)>=1 & ff/rr['FMSY',]<=1)),
    below8=mean(c(ss/base<.08)),iterations=dim(ss)[6],years=length(yrs))
  }
 }
 rm(runs);gc(verbose=FALSE)
}
wr<-rbindlist(wormparts);risk<-rbindlist(riskparts)
fwrite(wr,file.path(out,'focused-robustness-worms.csv'));fwrite(risk,file.path(out,'focused-robustness-risk.csv'))
md_table(risk[,.(Scenario=scenario,Component=biol,CMP=labels[code],`P(green), dynamic`=sprintf('%.1f%%',100*green),`SSB below previous Blim`=sprintf('%.1f%%',100*below8))],file.path(out,'focused-robustness-risk.md'))
for(scenario_i in names(checkpoints)) {
 z<-wr[scenario==scenario_i];z[,CMP:=factor(labels[code],levels=labels[keep])]
 z[,Panel:=factor(paste(biol,ifelse(metric=='SB','SSB (thousand t)','Catch (thousand t)'),sep=': '),levels=as.vector(t(outer(unique(biol),c('SSB (thousand t)','Catch (thousand t)'),paste,sep=': '))))]
 p<-ggplot(z,aes(year,data,group=iter,colour=factor(iter)))+geom_line(linewidth=.45,alpha=.85)+
 facet_grid(Panel~CMP,scales='free_y')+scale_colour_viridis_d(option='turbo',name='Simulation')+
 ggthemes::theme_few(base_size=10)+theme(legend.position='bottom')+labs(x='Year',y=NULL,
 title=paste('15 matched draws:',if(scenario_i=='om11_3')'recruitment cycle (om11_3)' else 'recruitment crash (om11_2)'),
 subtitle='Same 15 posterior-draw IDs across CMPs; all selected trajectories retained',
 caption='Selected simulation paths; common vertical scales within each row.')
 ggsave(file.path(out,paste0('worms-15-',scenario_i,'.png')),p,width=12,height=7.8,dpi=160)
}
writeLines(c('Focused robustness uses OM11_2 and OM11_3; saved 500-iteration checkpoints.',paste(names(tools::md5sum(checkpoints)),tools::md5sum(checkpoints))),file.path(out,'focused-robustness-provenance.txt'))
# Reuse already validated fixed-catch artifacts when only the CMP set changes.
if (Sys.getenv('JMMSE_REUSE_FIXED_CATCH')=='true') {
 stopifnot(all(file.exists(file.path(out,c('fixed-catch-summary.csv','worms-15-fixed-catch.png','robustness-fixedcatch-provenance.txt')))))
 cat('Verified selected-CMP robustness and matched trajectories; fixed-catch artifacts reused unchanged\n')
 quit(save='no',status=0)
}
# Fixed catch: its own initial state and reference points.
fixed_file<-'/Users/jim/Downloads/tunfixc.rds';hash_before<-tools::md5sum(fixed_file)
x<-readRDS(fixed_file);m<-metrics(om(x))$CJM;rp<-refpts(om(x));stopifnot(dims(om(x))$iter==500)
e<-parse('../jmMSE-500-refine/utilities.R')
for(expr in e)if(is.call(expr)&&identical(expr[[1]],as.name('<-'))&&identical(expr[[2]],as.name('unfishedMetric')))eval(expr)
db0<-unfishedMetric(om(x),metric='ssb')
saveRDS(db0,file.path(out,'fixed-catch-reconstructed-dynamic-b0.rds'))
yrs<-ac(2041:2050)
c<-flat(m$C)[order(iter,year)];c[,IACC:=100*abs(data/shift(data)-1),by=iter]
ct<-c[year %in% 2041:2050,.(catch_mean=mean(data),iacc_mean=mean(IACC)),by=iter]
fixed_summary<-data.table(indicator=c('Fixed catch advice (thousand t)','Median realized catch (thousand t)','Realized catch IQR (thousand t)','Median IACC (%)','IACC IQR (%)','P(green), reconstructed dynamic BMSY','P(green), static BMSY','SSB <8% reconstructed dynamic B0'),
 value=c(as.character(args(control(x)$hcr)$ctrg),sprintf('%.1f',median(ct$catch_mean)),paste(sprintf('%.1f',quantile(ct$catch_mean,c(.25,.75))),collapse='–'),sprintf('%.2f',median(ct$iacc_mean)),paste(sprintf('%.2f',quantile(ct$iacc_mean,c(.25,.75))),collapse='–'),
 sprintf('%.1f%%',100*mean(c(m$SB[,yrs]/((rp['SBMSY',]/rp['SB0',])*db0$CJM[,yrs])>=1 & m$F[,yrs]/rp['FMSY',]<=1))),
 sprintf('%.1f%%',100*mean(c(m$SB[,yrs]/rp['SBMSY',]>=1 & m$F[,yrs]/rp['FMSY',]<=1))),
 sprintf('%.1f%%',100*mean(c(m$SB[,yrs]/db0$CJM[,yrs]<.08)))))
fwrite(fixed_summary,file.path(out,'fixed-catch-summary.csv'));md_table(fixed_summary,file.path(out,'fixed-catch-summary.md'))
fw<-flat(m[['SB']])[year %in% 2025:2050 & iter %in% ids][,metric:='SSB (thousand t)']
stopifnot(nrow(fw)==15*26,uniqueN(fw$iter)==15,!anyDuplicated(fw[,.(iter,year)]),!anyNA(fw$data))
fwrite(fw,file.path(out,'fixed-catch-worms.csv'))
p<-ggplot(fw,aes(year,data,group=iter,colour=factor(iter)))+geom_line(linewidth=.5)+scale_colour_viridis_d(option='turbo',name='Simulation')+ggthemes::theme_few(base_size=11)+theme(legend.position='bottom')+
 labs(x='Year',y='SSB (thousand t)',title='Fixed catch: 15 unique SSB simulations',subtitle='Advice = 1,525 thousand t; supplied reference-OM run, dynamic-BMSY tuning',caption='Display IDs match the other figures; recruitment paths and implementation assumptions differ between the supplied runs.')
ggsave(file.path(out,'worms-15-fixed-catch.png'),p,width=11,height=6,dpi=160)
basefile<-'../jmMSE-500-refine/data/om11_h1_0.16_065.rds';base<-readRDS(basefile)
cmp<-rbindlist(lapply(dimnames(rp)$params,function(par) {
 a<-as.numeric(rp[par,]);b<-as.numeric(refpts(base$om)[par,]);data.table(parameter=par,fixed_median=median(a),current_median=median(b),equal=isTRUE(all.equal(a,b)))
}))
fwrite(cmp,file.path(out,'fixed-catch-reference-point-check.csv'))
iem<-as.data.table(x@tracking)[as.character(metric)=='iem',.(year,iter,data)]
fwrite(iem,file.path(out,'fixed-catch-implementation-targets.csv'))
stopifnot(identical(hash_before,tools::md5sum(fixed_file)))
inputs<-c(checkpoints,fixed_file,basefile)
writeLines(c('Dynamic B0 for fixed catch reconstructed with the repository zero-catch projection, from the supplied run initial state and parameters.',paste(names(tools::md5sum(inputs)),tools::md5sum(inputs)),capture.output(sessionInfo())),file.path(out,'robustness-fixedcatch-provenance.txt'))
cat('Verified focused robustness, matched worm panels, fixed-catch input unchanged\n')
