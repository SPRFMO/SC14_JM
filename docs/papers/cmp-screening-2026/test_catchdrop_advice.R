library(data.table)
source('R/catchdrop_advice.R')
x<-data.table(mp='test',iter=rep(1:2,each=4),year=rep(1:4,2),
 advice=c(100,81,64.8,0,100,120,NA,50),advice_stock='CJM')
z<-advice_drop_events(x)
stopifnot(identical(z$flag,c(NA_integer_,0L,1L,1L,NA_integer_,0L,NA_integer_,NA_integer_)))
s<-summarize_advice_events(z)
# Pooled 2/4, rather than mean of iteration rates (2/3 + 0/1)/2.
stopifnot(s$events==2,s$valid_comparisons==4,s$raw_value==.5)
y<-advice_drop_events(data.table(mp='edge',iter=1,year=c(1,2,4,5,6),advice=c(100,0,100,-1,90)))
stopifnot(y$flag[2]==1L,all(is.na(y$flag[c(1,3,4,5)])))
cat('PASS: strict threshold, increases, full cuts, missing/invalid values, gaps, and pooled denominator\n')
