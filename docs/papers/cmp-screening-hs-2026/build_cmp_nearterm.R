# Near-term figures from saved 500-iteration outputs; no model fits.
suppressPackageStartupMessages({library(mse);library(data.table);library(ggplot2);library(ggrepel)})
labels<-c(tun29='HS+20',tun45='HSsym',tun43='HS-20',tun47='HS-30',tun44='PR-20',tun32='PR+20',tun46='PRsym',tun48='PR-30')
sets<-list('cmp-working-paper-2026'=c('tun43','tun47','tun44'),'cmp-working-paper-hs-2026'=c('tun29','tun45','tun43'))
ommap<-data.table(om=c('h1_0.16','h1_0.16_lowrec','h1_0.16_cycle'),scenario=c('om11','om11_2','om11_3'),panel=c('Reference (OM11)','Recruitment crash (OM11_2)','Recruitment cycle (OM11_3)'),file=c('om11_h1_0.16_065.rds','om11_2_h1_0.16_065.rds','om11_3_h1_0.16_065.rds'))
files<-c('output/candidate-performance-500/reference/performance_with_vb.rds','output/candidate-performance-500/robustness/performance_with_vb.rds')
d<-rbindlist(lapply(files,function(f){x<-as.data.table(readRDS(f));x[om %in% ommap$om & year %in% 2026:2035 & statistic %in% c('C','IACC','SBMSY','FMSY')]}))
d[,code:=sub('_om.*$','',mp)]
stopifnot(all(d$biol=='CJM'),!anyNA(d$data),all(is.finite(d$data)),!anyDuplicated(d[,.(om,code,iter,year,statistic)]))
iv<-d[,.(value=mean(data),n_years=.N),by=.(om,code,iter,statistic)]
stopifnot(all(iv$n_years==10),all(iv[,uniqueN(iter),by=.(om,code,statistic)]$V1==500))
s<-iv[,.(median=median(value),q25=quantile(value,.25),q75=quantile(value,.75)),by=.(om,code,statistic)]
w<-dcast(s,om+code~statistic,value.var=c('median','q25','q75'))
w<-merge(w,ommap[,.(om,scenario,panel)],by='om')
flat<-function(x){z<-as.data.table(as.data.frame(x));z[,.(year=as.integer(as.character(year)),iter=as.integer(as.character(iter)),db0=data)]}
annual<-list()
for(i in 1:nrow(ommap)){
 b<-readRDS(file.path('../jmMSE-500-refine/data',ommap$file[i]));rp<-refpts(b$om)
 a<-dcast(d[om==ommap$om[i] & statistic %in% c('SBMSY','FMSY')],code+iter+year~statistic,value.var='data')
 a<-merge(a,flat(b$unfishedSSB$CJM),by=c('year','iter'),all.x=TRUE)
 a<-merge(a,data.table(iter=seq_along(as.numeric(rp['SB0',])),sb0=as.numeric(rp['SB0',]),sbmsy=as.numeric(rp['SBMSY',])),by='iter',all.x=TRUE)
 stopifnot(!anyNA(a),all(a$db0>0))
 a[,`:=`(sb_dynamic_msy=SBMSY*sb0/db0,ssb_db0=SBMSY*sbmsy/db0,scenario=ommap$scenario[i],panel=ommap$panel[i])]
 annual[[i]]<-a
}
a<-rbindlist(annual)
kiv<-a[,.(sb=mean(sb_dynamic_msy),f=mean(FMSY)),by=.(scenario,panel,code,iter)]
k<-kiv[,.(sb=median(sb),f=median(f),iterations=.N),by=.(scenario,panel,code)]
stopifnot(all(k$iterations==500))
# Match independently generated reference-OM near-term Kobe values.
old<-fread('doc/data/candidates/kobe_reference_periods_summary.csv')[grepl('Near term',period)]
check<-merge(k[scenario=='om11'],old,by.x='code',by.y='mp')
stopifnot(nrow(check)==8,max(abs(check$sb-check$sb_sbmsy))<1e-10,max(abs(check$f-check$f_fmsy))<1e-10)
risk<-a[,.(Pgreen=mean(sb_dynamic_msy>=1 & FMSY<=1),Pred=mean(sb_dynamic_msy<1 & FMSY>1),Pbelow8=mean(ssb_db0<.08),n_comparisons=.N),by=.(scenario,panel,code)]
stopifnot(all(risk$n_comparisons==5000))
rects<-data.table(xmin=c(0,1,0,1),xmax=c(1,Inf,1,Inf),ymin=c(1,1,0,0),ymax=c(Inf,Inf,1,1),fill=c('#D97B72','#F2D46F','#E7A35B','#8BCB88'))
for(folder in names(sets)){
 out<-file.path('output',folder);keep<-sets[[folder]];pal<-setNames(c('#996029','#277b4d','#246cac'),labels[keep])
 z<-w[code %in% keep];z[,`:=`(CMP=factor(labels[code],levels=labels[keep]),panel=factor(panel,levels=ommap$panel))]
 for(y in c('IACC','SBMSY')){
  p<-ggplot(z,aes(median_C,.data[[paste0('median_',y)]],colour=CMP,shape=CMP))+
   geom_segment(aes(x=q25_C,xend=q75_C,yend=.data[[paste0('median_',y)]]),linewidth=.55)+
   geom_segment(aes(y=.data[[paste0('q25_',y)]],yend=.data[[paste0('q75_',y)]],xend=median_C),linewidth=.55)+geom_point(size=3)+
   facet_wrap(~panel,nrow=1,scales='free')+scale_colour_manual(values=pal)+ggthemes::theme_few(base_size=11)+theme(legend.position='bottom')+
   labs(title='Near term (2026–2035)',subtitle='500 iterations: medians of period means; horizontal and vertical bars are interquartile ranges',x='Median annual catch (thousand t)',y=if(y=='IACC')'Median interannual catch change (%)' else 'Median SSB / static SSBMSY',caption='OMs remain separate. IACC uses the previous-year catch, including 2025 for the 2026 change.')
  ggsave(file.path(out,paste0('near-term-',y,'.png')),p,width=14,height=4.9,dpi=170)
 }
 z<-k[code %in% keep];z[,`:=`(CMP=factor(labels[code],levels=labels[keep]),panel=factor(panel,levels=ommap$panel))]
 p<-ggplot()+geom_rect(data=rects,aes(xmin=xmin,xmax=xmax,ymin=ymin,ymax=ymax,fill=fill),alpha=.16)+scale_fill_identity()+
  geom_vline(xintercept=1,colour='grey40')+geom_hline(yintercept=1,colour='grey40')+
  geom_point(data=z,aes(sb,f,colour=CMP,shape=CMP),size=3)+geom_text_repel(data=z,aes(sb,f,label=CMP,colour=CMP),seed=42,size=3.5,max.overlaps=Inf,min.segment.length=0,show.legend=FALSE)+
  facet_wrap(~panel,nrow=1)+scale_colour_manual(values=pal)+ggthemes::theme_few(base_size=11)+theme(legend.position='none')+
  coord_cartesian(xlim=c(0,max(1.9,max(z$sb)*1.15)),ylim=c(0,max(1.35,max(z$f)*1.15)),expand=FALSE)+
  labs(title='Near term (2026–2035): Kobe status',subtitle='Points are medians across 500 iterations of each iteration’s period mean',x='Spawning biomass relative to dynamic SSBMSY',y='Fishing mortality relative to FMSY',caption='Biomass and fishing-pressure reference lines equal 1. Point locations are not probabilities of a quadrant outcome.')
 ggsave(file.path(out,'near-term-kobe.png'),p,width=14,height=5.2,dpi=170)
 fwrite(w[code %in% keep],file.path(out,'near-term-tradeoffs.csv'));fwrite(k[code %in% keep],file.path(out,'near-term-kobe.csv'));fwrite(risk[code %in% keep],file.path(out,'near-term-risk.csv'))
 rr<-risk[code %in% keep,.(OM=panel,CMP=labels[code],`P(green)`=sprintf('%.1f%%',100*Pgreen),`P(red)`=sprintf('%.1f%%',100*Pred),`SSB below previous Blim`=sprintf('%.1f%%',100*Pbelow8))]
 writeLines(c(paste0('| ',paste(names(rr),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(rr)),collapse=' | '),' |'),apply(rr,1,function(x)paste0('| ',paste(x,collapse=' | '),' |'))),file.path(out,'near-term-risk.md'))
 inputs<-c(files,file.path('../jmMSE-500-refine/data',ommap$file))
 writeLines(c('Near-term period: 2026-2035. Existing saved outputs; no model fitting.',paste(names(tools::md5sum(inputs)),tools::md5sum(inputs)),'Reference Kobe medians independently match the established reference plot to <1e-10.'),file.path(out,'near-term-provenance.txt'))
}
cat('PASS near-term data: 500 iterations, 10 years; independently verified reference Kobe values; both sets generated\n')
