cap prog drop events_codes
prog def events_codes
	cap ssc install fs
	args codetype event
	quietly {
		cd "$data/raw"
		if "`codetype'"=="med"{
			local files ""
			foreach j in clinical referral test immunisation {	
				fs "*`j'*"		
				foreach f in `r(files)' {
					use "$data/raw/`f'",clear
					gen filename = subinstr("`f'",".dta","",.)
					gen index_date = cond(missing(eventdate),sysdate,eventdate)
					gen datetype = cond(missing(eventdate),"sysdate","eventdate")
					joinby medcode using "$codelists/`event'.dta"
					tostring textid filename readterm, replace
					compress
					save "$data/eventlists/`f'_eventlist_`event'.dta", replace
					local files : list  f | files
				}
			}
			foreach i in `files'{
				append using "$data/eventlists/`i'_eventlist_`event'.dta"
				rm "$data/eventlists/`i'_eventlist_`event'.dta"
			}
		}
		if "`codetype'"=="prod"{
			local files ""
			foreach j in therapy {
				fs "*`j'*"	
				foreach f in `r(files)' {
					use "$data/raw/`f'",clear
					gen filename = subinstr("`f'",".dta","",.)
					gen index_date = cond(missing(eventdate),sysdate,eventdate)
					gen datetype = cond(missing(eventdate),"sysdate","eventdate")
					joinby prodcode using "$codelists/`event'"
					tostring textid filename prodname drugsubstance, replace
					compress
					format %15.0g staffid consid patid
					format %td *date
					save "$data/eventlists/`f'_eventlist_`event'.dta", replace
					local files : list  f | files		
				}
			}
			foreach i in `files'{
				append using "$data/eventlists/`i'_eventlist_`event'.dta"
				rm "$data/eventlists/`i'_eventlist_`event'.dta"
			}
		}
		duplicates drop
		compress
		format %15.0g staffid consid patid
		format %td *date
	}
	save "$data/eventlists/eventlist_`event'.dta", replace
	if "`codetype'"=="prod"{
		run "$dofiles/events_drugduration.do"
		save "$data/eventlists/eventlist_`event'.dta", replace
	}
	egen index_count = count(patid), by(patid)
	egen min_date = min(index_date), by(patid)
	format %td min_date
	if "`codetype'"=="prod"{
		egen tot_duration = total(duration), by(patid)
		keep patid index_count min_date tot_duration
		rename tot_duration duration
	} 
	else {
		keep patid index_count min_date
	}
	rename min_date index_date
	duplicates drop *, force
	save "$data/patlists/patlist_`event'.dta", replace
end 
