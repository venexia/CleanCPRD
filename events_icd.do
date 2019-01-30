local files : dir "$codelists" files "icd*.dta"

foreach f in `files' {

	local event = subinstr(subinstr("`f'","icd_","",.),".dta","",.)

	* Extract events from ONS death data

	use "$data/link/link_c_death_patient.dta", clear
	rename dod indexdate
	rename cause cause0
	drop *_neonatal*
	keep patid cause* indexdate
	reshape long cause, i(patid) j(cause_no)
	rename cause icdcode
	by patid: gen cause_tot = _N
	drop if missing(icdcode)
	joinby icdcode using "$codelists/icd_`event'.dta"
	keep patid icdcode indexdate icdname
	if _N==0 {
		di "No observations in the file eventlist_death_`event'.dta"
	}
	else {
		duplicates drop
		compress
		save "$data/link/eventlists/eventlist_death_`event'.dta", replace
		egen index_count = count(patid), by(patid)
		egen index_date = min(indexdate), by(patid)
		format %td  index_date
		keep patid index_*
		duplicates drop *, force
		save "$data/link/patlists/patlist_death_`event'.dta", replace
	}
	
	
	* Extract events from HES inpatient data
	
	use "$data/link/link_c_hes_diagnosis_hosp.dta", clear
	rename discharged indexdate
	rename icd icdcode
	joinby icdcode using "$codelists/icd_`event'.dta"
	keep patid icdcode indexdate icdname
	if _N==0 {
		di "No observations in the file eventlist_hesip_`event'.dta"
	}
	else {
		duplicates drop
		compress
		save "$data/link/eventlists/eventlist_hesip_`event'.dta", replace
		egen index_count = count(patid), by(patid)
		egen index_date = min(indexdate), by(patid)
		format %td index_date
		keep patid index_*
		duplicates drop *, force
		save "$data/link/patlists/patlist_hesip_`event'.dta", replace
	}
	
	* Extract events from HES outpatient data
	
	use "$data/link/link_c_hesop_clinical.dta", clear
	merge 1:1 patid attendkey using "$data/link/link_c_hesop_patient_pathway.dta", keepusing(subdate)
	rename subdate indexdate
	foreach v of varlist diag* {
		local temp = substr("`v'",6,1)
		local num = cond("`temp'"=="0",substr("`v'",7,1),substr("`v'",6,2))
		rename `v' diag`num'
	}
	keep patid diag* attendkey indexdate
	sort patid attendkey
	gen tempid = _n
	save "$data/hesop_id.dta", replace
	egen diag_tot = rownonmiss(diag*), strok
	drop if diag_tot==1 & (diag1=="R96X" | diag1=="R69X6" | diag1=="R69X8")
	reshape long diag, i(tempid) j(diag_no)
	rename diag icdcode
	drop if missing(icdcode)
	joinby icdcode using "$codelists/icd_`event'.dta"
	keep patid icdcode indexdate icdname
	if _N==0 {
		di "No observations in the file eventlist_hesop_`event'.dta"
	}
	else {
		duplicates drop
		compress
		save "$data/link/eventlists/eventlist_hesop_`event'.dta", replace
		egen index_count = count(patid), by(patid)
		egen index_date = min(indexdate), by(patid)
		format %td index_date
		keep patid index_*
		duplicates drop *, force
		save "$data/link/patlists/patlist_hesop_`event'.dta", replace
	}

}
