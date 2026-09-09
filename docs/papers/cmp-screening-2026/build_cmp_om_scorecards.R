# Build OM/component-aware scorecard snapshots from matched saved 500-draw outputs.
suppressPackageStartupMessages({library(mse);library(data.table);library(jsonlite)})
out<-'output/cmp-working-paper-2026'
labels<-c(tun29='HS+20 (MP29)',tun43='HS-20 (MP43)',tun45='HSsym (MP45)',tun47='HS-30 (MP47)',tun32='PR+20 (MP32)',tun44='PR-20 (MP44)',tun46='PRsym (MP46)',tun48='PR-30 (MP48)')
lookup<-data.table(om_code=c('om11','om11_2','om21','om11_1','om11_3','om12','om13','om21_1','om22','om23'),
 om=c('h1_0.16','h1_0.16_lowrec','h2_0.16','h1_0.16_selex','h1_0.16_cycle','h1_0.16h','h1_1.14','h2_0.16_mov','h2_0.16h','h2_1.14'),
 om_label=c('Reference (om11)','Recruitment crash (om11_2)','Two stocks (om21)','Alternative selectivity (om11_1)','Recruitment cycle (om11_3)','Higher steepness (om12)','Alternative assessment (om13)','Movement (om21_1)','Two stocks, higher steepness (om22)','Two stocks, alternative assessment (om23)'),
 file=c('om11_h1_0.16_065.rds','om11_2_h1_0.16_065.rds','om21_h2_0.16_065.rds','om11_1_h1_0.16_065.rds','om11_3_h1_0.16_065.rds','om12_h1_0.16h_080.rds','om18_h1_1.14_065.rds','om21_1_h2_0.16_065.rds','om22_h2_0.16h_080.rds','om28_h2_1.14_065.rds'))
q<-fread('doc/data/candidates/candidate_quilt_reference_summary.csv')
meta<-unique(q[,.(statistic,metric,direction,years,summary)])
primary<-c('C','IACC','PC270','CatchDrop20','SSBbelow8dB0')
rows<-list(q[,.(mp,statistic,metric,raw_value=value,preferred_direction=direction,include=statistic %in% primary,weight=1,years,summary,om_code='om11',om_label='Reference (om11)',component='CJM',n_iter=500L)])
perf_file<-'output/candidate-performance-500/robustness/performance_with_vb.rds'
perf<-as.data.table(readRDS(perf_file));perf[,code:=sub('_om.*$','',mp)]
flat<-function(q){z<-as.data.table(as.data.frame(q));z[,year:=as.integer(as.character(year))];z[,iter:=as.integer(as.character(iter))];stopifnot(!anyDuplicated(z[,.(year,iter)]));z[,.(year,iter,data)]}
advice_summary<-fread('output/catchdrop19/advice-summary.csv')
risks<-list()
for(i in 2:nrow(lookup)) {
 message('Scorecards: ',lookup$om_code[i]);sel<-lookup[i]
 b<-readRDS(file.path('../jmMSE-500-refine/data',sel$file));stopifnot(as.character(name(b$om))==sel$om)
 for(biol_code in unique(perf[om==sel$om,biol])) {
  d<-perf[om==sel$om & biol==biol_code]
  stopifnot(uniqueN(d$code)==8,identical(sort(unique(d$iter)),1:500))
  rp<-refpts(b$om);rp<-if(is(rp,'FLPars'))rp[[biol_code]] else rp
  db<-flat(b$unfishedSSB[[biol_code]]);setnames(db,'data','db0')
  rpt<-data.table(iter=seq_along(as.numeric(rp['SBMSY',])),rp_sbmsy=as.numeric(rp['SBMSY',]),rp_sb0=as.numeric(rp['SB0',]))
  annual<-dcast(d[statistic %in% c('C','SBMSY','FMSY')],code+iter+year~statistic,value.var='data')
  annual<-merge(merge(annual,db,by=c('year','iter'),all.x=TRUE),rpt,by='iter',all.x=TRUE)
  stopifnot(!anyNA(annual),all(annual$db0>0))
  annual[,ssb_db0:=SBMSY*rp_sbmsy/db0]
  annual[,sb_dynamic_msy:=SBMSY*rp_sb0/db0]
  setorder(annual,code,iter,year)
  annual[,`:=`(previous_catch=shift(C),previous_ssb_db0=shift(ssb_db0)),by=.(code,iter)]
  annual[,reduction:=1-C/previous_catch]
  core<-d[year %in% 2041:2050,.(iv=mean(data)),by=.(code,iter,statistic)][,.(raw_value=median(iv)),by=.(code,statistic)]
  risk<-annual[year %in% 2041:2050,.(SB0red=mean(sb_dynamic_msy<1 & FMSY>1),SSBbelow8dB0=mean(ssb_db0<.08),green=mean(sb_dynamic_msy>=1 & FMSY<=1)),by=code]
  risks[[length(risks)+1L]]<-risk[,.(scenario=sel$om_code,biol=biol_code,code,green,below8=SSBbelow8dB0)]
  risklong<-melt(risk[,.(code,SB0red,SSBbelow8dB0)],id.vars='code',variable.name='statistic',value.name='raw_value')
  cuts<-advice_summary[om_code==sel$om_code,.(code=mp,raw_value)][,statistic:='CatchDrop20']
  # Match the legacy mean-reduction window, whose first comparison is 2027.
  reductions<-annual[year %in% 2027:2050,.(iv=mean(pmax(reduction,0)*100)),by=.(code,iter)][,.(raw_value=median(iv)),by=code][,statistic:='Creduction']
  combined<-rbindlist(list(core,risklong,cuts,reductions),use.names=TRUE)
  # 270 kt is a whole single-stock catch threshold, not a component quota.
  if(biol_code=='CJM')combined<-rbind(combined,annual[year %in% 2041:2050,.(raw_value=mean(C<270)),by=code][,statistic:='PC270'])
  combined<-merge(combined,meta,by='statistic',all.x=TRUE)
  stopifnot(!anyNA(combined),all(is.finite(combined$raw_value)))
  rows[[length(rows)+1L]]<-combined[,.(mp=unname(labels[code]),statistic,metric,raw_value,preferred_direction=direction,include=statistic %in% primary,weight=1,years,summary,om_code=sel$om_code,om_label=sel$om_label,component=biol_code,n_iter=500L)]
 }
 rm(b);gc(verbose=FALSE)
}
allrows<-rbindlist(rows)
stopifnot(!anyDuplicated(allrows[,.(om_code,component,mp,statistic)]),all(allrows[,uniqueN(mp),by=.(om_code,component)]$V1==8))
# Validate compact-data reconstruction against independently read run attributes.
rv<-rbindlist(risks);focus<-fread(file.path(out,'focused-robustness-risk.csv'))
check<-merge(focus,rv,by=c('scenario','biol','code'),suffixes=c('_runs','_compact'))
stopifnot(nrow(check)==9,max(abs(check$green_runs-check$green_compact))<1e-12,max(abs(check$below8_runs-check$below8_compact))<1e-12)
fwrite(allrows,file.path(out,'scorecards-all-oms.csv'))
jsonlite::write_json(allrows,file.path(out,'scorecards-all-oms.json'),dataframe='rows',auto_unbox=TRUE,pretty=FALSE,digits=16)
fwrite(rv,file.path(out,'scorecards-robustness-risk-check.csv'))
writeLines(c('OM/component scorecards; 500 simulations each; no cross-OM pooling. Fixed catch is excluded because its supplied setup differs.',paste(names(tools::md5sum(c(perf_file,file.path('../jmMSE-500-refine/data',lookup$file)))),tools::md5sum(c(perf_file,file.path('../jmMSE-500-refine/data',lookup$file))))),file.path(out,'scorecards-om-provenance.txt'))
cat('Verified',uniqueN(allrows$om_code),'OMs,',nrow(unique(allrows[,.(om_code,component)])),'OM/components; independent risk calculations agree\n')
