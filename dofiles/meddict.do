import delimited $documents/codebrowser/CPRD_CodeBrowser_201603_GOLD/product.txt, clear rowrange(2:) varnames(nonames)
rename v1 prodcode
rename v4 prodname
rename v5 drugsubstance
rename v6 substancestrength
rename v7 formulation
rename v8 adminroute
rename v9 bnfcode
rename v10 bnfheader
drop v2 v3 v11 v12
save "$data/meddict.dta", replace
