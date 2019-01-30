
* Convert all CPRD txt files to raw files --------------------------------------

quietly {
	local files : dir "$data/txt" files "venexia_15_246r_ext_extract_*.txt"
	foreach file in `files' {
		import delim "$data/txt/`file'", varn(1) clear
		foreach date in chsdate frd crd tod deathdate lcd uts eventdate sysdate linkdate start end discharged dod perend perstart subdate apptdate dnadate reqdate {
			capture confirm variable `date'
			if !_rc {
				gen `date'1 = date(`date',"DMY")
				format %td `date'1
				drop `date'
				rename `date'1 `date'
			}
		}
		local name = subinstr(subinstr(strlower("`file'"),".txt","",.),"venexia_15_246r_ext_extract_","",.)
		compress
		save "$data/raw/`name'", replace
	}
	local testfiles : dir "$data/raw" files "test*.dta"
	foreach file in `testfiles' {
		use "$data/raw/`file'", clear
		foreach x of varlist data1 data2 data3 data4 data5 data6 data7 data8 {
			rename `x' test_`x'
		}
		save "$data/raw/`file'", replace
	}
}

* Convert all linked data txt files to raw files -------------------------------

quietly {
	local files : dir "$data/txt" files "link*.txt"
	foreach file in `files' {
		import delim "$data/txt/`file'", varn(1) clear
		foreach date in apptdate discharged dnadate dod linkdate perend perstart reqdate subdate {
			capture confirm variable `date'
			if !_rc {
				gen `date'1 = date(`date',"DMY")
				format %td `date'1
				drop `date'
				rename `date'1 `date'
			}
		}
		local name = subinstr("`file'",".txt","",.)
		compress
		save "$data/raw/`name'", replace
	}
}

* Convert active patient file --------------------------------------------------

quietly {
	local files : dir "$data/txt" files "GP_Practice_Active*.txt"
	foreach file in `files' {
		import delim "$data/txt/`file'", varn(1) clear
		rename lcd_date lcd
		rename uts_date uts
		foreach date in lcd uts {
			capture confirm variable `date'
			if !_rc {
				gen `date'1 = date(`date',"DMY")
				format %td `date'1
				drop `date'
				rename `date'1 `date'
			}
		}
		local name = subinstr("`file'",".txt","",.)
		compress
		save "$data/raw/`name'", replace
	}
}

* Add dates to additional detail files -----------------------------------------

local clinicalfiles : dir "$path/data/raw" files "clinical_*.dta"
local addfiles : dir "$path/data/raw" files "additional_*.dta"

mkdir "$path/data/tmp"

qui foreach clinical in `clinicalfiles' {
	use patid adid eventdate sysdate using "$path/data/raw/`clinical'" ,clear
	drop if adid==0
	save "$path/data/tmp/tmp_`clinical'", replace
}

local clinicalfiles : dir "$path/data/raw" files "clinical_*.dta"
local addfiles : dir "$path/data/raw" files "additional_*.dta"
	
foreach add in `addfiles' {
	local clinicalfiles : dir "$path/data/raw" files "clinical_*.dta"
	use "$path/data/raw/`add'" ,clear
	save "$path/data/additional/dated_`add'", replace
	qui foreach clinical in `clinicalfiles' {
		use "$path/data/additional/dated_`add'", clear
		merge 1:1 patid adid using "$path/data/tmp/tmp_`clinical'", update keep(1 3 4)
		drop _merge
		save "$path/data/additional/dated_`add'", replace
	}
}

!rmdir "$path/data/tmp" /s /q
