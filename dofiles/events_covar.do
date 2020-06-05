

local csvfiles : dir "$path/covariates/csv" files "*.csv"

foreach file in `csvfiles' {
	import delimited using "$path/covariates/csv/`file'", clear
	local noextension=subinstr("`file'",".csv","",.)
	keep medcode readterm
	drop if missing(medcode)
	label var medcode "Medical Code"
	label var readterm "Read Term"
	save "$path/covariates/stata/`noextension'", replace
}
	
local dtafiles : dir "$path/covariates/stata" files "*.dta"
	
qui foreach file in `dtafiles' {
	local event=subinstr("`file'",".dta","",.)
	cd "$data/raw"
	local files ""
	foreach j in clinical referral test immunisation {	
		fs "*`j'*"		
		foreach f in `r(files)' {
			use "$data/raw/`f'",clear
			gen filename = subinstr("`f'",".dta","",.)
			gen index_date = cond(missing(eventdate),sysdate,eventdate)
			gen datetype = cond(missing(eventdate),"sysdate","eventdate")
			joinby medcode using "$path/covariates/stata/`event'.dta"
			tostring textid filename readterm, replace
			compress
			save "$path/covariates/eventlists/`f'_eventlist_`event'.dta", replace
			local files : list  f | files
		}
	}

	foreach i in `files'{
		append using "$path/covariates/eventlists/`i'_eventlist_`event'.dta"
		rm "$path/covariates/eventlists/`i'_eventlist_`event'.dta"
	}

	duplicates drop
	compress
	format %15.0g staffid consid patid
	format %td *date

	save "$path/covariates/eventlists/eventlist_`event'.dta", replace
	egen index_count = count(patid), by(patid)
	egen min_date = min(index_date), by(patid)
	format %td min_date
	keep patid index_count min_date
	rename min_date index_date
	duplicates drop *, force
	save "$path/covariates/patlists/patlist_`event'.dta", replace
}
