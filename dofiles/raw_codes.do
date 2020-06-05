local excelfiles : dir "$path/codelists/excel" files "*.xlsx"

foreach file in `excelfiles' {
	import excel using "$path/codelists/excel/`file'", first clear
	local noextension=subinstr("`file'",".xlsx","",.)
	capture confirm variable medcode
	if !_rc {	
		drop readcode
		label var medcode "Medical Code"
		label var readterm "Read Term"
		save "$codelists/`noextension'", replace
	}
	capture confirm variable prodcode
	if !_rc {
		rename productname prodname
		label var prodcode "Product Code"
		label var prodname "Product Name"
		save "$codelists/`noextension'", replace
	}
	capture confirm variable icdcode
	if !_rc {
		label var icdcode "ICD10 Code"
		label var icdname "ICD10 Name"
		gen icd_hesop = subinstr(icdcode,".","",.)
		replace icd_hesop = icd_hesop + "X" if strlen(icd_hesop)==3
		label var icd_hesop "ICD10 Code for HES Outpatient Data"
		save "$codelists/`noextension'", replace
	}
}
