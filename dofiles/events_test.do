cap prog drop events_test
prog def events_test
	cap ssc install fs
	args event filetype cond

	quietly {
		if "`filetype'" == "test" {
			cd "$data/raw"
		}
		if "`filetype'" == "dated_additional" {
			cd "$data/additional"
		}
		local files ""
		fs "`filetype'_*.dta"
		foreach f in `r(files)' {
			if "`filetype'" == "test" {
				use "$data/raw/`f'",clear
			}
			if "`filetype'" == "dated_additional" {
				use "$data/additional/`f'",clear
			}
			gen filename = subinstr("`f'",".dta","",.)
			destring *data*, replace force
			keep if `cond'
			if "`filetype'" == "test" {
				tostring textid, replace
			}
			
			/*
			if "`filetype'" == "additional" {
				joinby patid adid using "$data/temp/clinical_dates.dta", unmatched(master)
				drop _merge
			}
			*/
			gen indexdate = cond(missing(eventdate),sysdate,eventdate)
			format %td indexdate
			gen `event'_type = cond(missing(eventdate),"sysdate","eventdate")
			compress
			save "$data/eventlists/`f'_eventlist_`event'.dta", replace
			local files : list  f | files		
		}
		foreach i in `files'{
			append using "$data/eventlists/`i'_eventlist_`event'.dta"
			rm "$data/eventlists/`i'_eventlist_`event'.dta"
		}
		duplicates drop
		compress
	}
	save "$data/eventlists/eventlist_`event'.dta", replace
	egen `event'_freq = count(patid), by(patid)
	egen `event'_date = min(indexdate), by(patid)
	format %td `event'_date
	drop if indexdate!=`event'_date
	sort patid `event'_type
	duplicates drop patid `event'_freq `event'_date, force
	drop indexdate
	save "$data/patlists/patlist_`event'.dta", replace
end 
