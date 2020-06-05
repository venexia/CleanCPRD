* Missing treatment duration
/*This do file calculates the length of time a prescription is issued for, 
	deals with missing data, and replaces values that are implausable (outliers).
	It can be run from any of the outcome files (e.g. statins, etc.)
 Based on 'ISAC protocol by Adrian Root' 
 Documents\CPRD\Useful do files\Documentation\NSAID_Antidep_ISAC.doc
 Ignoring numdays 
 Date created : 24th Oct 2016

* Missing data imputation approach where patients are missing ndd or quantity, use 
  model scriptlength for :-
	1. 	Patient’s other prescriptions for the same drug (prodcode then drug substance);
	2.	Patient's concurrent prescription for other medication
	3. 	Other patients in the practice of similar age in the same year and 
		prescribed the same drug by the same staff member
	4. 	Other patients in the practice of similar age in the same year and 
		prescribed any long-term oral drug by the same staff member
	5.	Any long-term oral medication prescribed to other patients in the 
		practice of similar age in the same year regardless of issuing staff 
		member
	6.	Any long-term oral medication prescribed to other patients of any age in 
		practice in the same year
	7.	Any long-term oral medication prescribed to any patient from any practice 
		issued in the same year
*/
********************************************************************************

/* VMW: Index date variable named differently */

gen event_date = index_date

*Calculate number of days each prescription is for (qty/ndd)
*qty and ndd take into account whether its a liquid or not
*0 represents infrequent/as and when required (99% 0-90 days)
capture drop scriptlength
gen scriptlength=qty/ndd
tab scriptlength, m 
sum scriptlength, d
gen end_date = event_date+scriptlength
format end_date %td

* Using MODE scriptlength
*Option 1: *Patient’s other prescriptions for the same drug (prodcode then drug substance)
sort patid prodcode
capture drop scriptlength_patprod_mode
capture drop scriptlength_patsub_mode
egen scriptlength_patprod_mode  = mode(scriptlength), by(patid prodcode)
egen scriptlength_patsub_mode = mode(scriptlength), by(patid drugsubstance)
lab var scriptlength_patprod_mode "Option 1a: Patid & prodcode"
lab var scriptlength_patsub_mode "Option 1b: Patid & drug substance"
sum scriptlength_patsub_mode, d

*Option 2: Patient's concurrent prescription for other medication (same quarter)
gen year = year(event_date)
gen quarter = quarter(event_date)
gen year_quarter = yq(year, quarter)
format year_quarter %tq
drop quarter
sort patid year_quarter
capture drop scriptlength_patmed_mode
egen scriptlength_patmed_mode  = mode(scriptlength), by(patid year_quarter)
lab var scriptlength_patmed_mode "Option 2: Patid & concurrent med"
sum scriptlength_patmed_mode, d

/* VMW: Year of birth required */

merge m:1 patid using "$data/raw/patient_001.dta", keepusing(patid yob) keep(match master)
drop _merge
gen year_birth = yob + 1800

/* Option 3: Other patients in the practice of similar age in the same year and 
			 prescribed the same drug by the same staff member */
tostring patid, replace
gen pracid = substr(patid,-3,.)
destring patid pracid, replace
order pracid, after(patid)

gen age = year-year_birth
egen age_group = cut(age), at(6,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,108)

sort pracid staffid year age_group drugsubstance
capture drop scriptlength_pracsubstaff_mode
egen scriptlength_pracsubstaff_mode  = mode(scriptlength), by(pracid staffid year age_group drugsubstance)
lab var scriptlength_pracsubstaff_mode "Option 3: Pracid, staff, year, age & drug"
sum scriptlength_pracsubstaff_mode, d
			 
/* Option 4: Other patients in the practice of similar age in the same year and 
			 prescribed any long-term oral drug by the same staff member */			 
sort pracid staffid year age_group
capture drop scriptlength_pracstaff_mode
egen scriptlength_pracstaff_mode  = mode(scriptlength), by(pracid staffid year age_group)
lab var scriptlength_pracstaff_mode "Option 4: Pracid, staff, year & age"
sum scriptlength_pracstaff_mode, d

/* Option 5: Any long-term oral medication prescribed to other patients in the 
			 practice of similar age in the same year regardless of issuing staff 
			 member */					 
sort pracid year age_group
capture drop scriptlength_prac_mode
egen scriptlength_prac_mode  = mode(scriptlength), by(pracid year age_group)
lab var scriptlength_prac_mode "Option 5: Pracid, year & age"
sum scriptlength_prac_mode, d

/* Option 6: Any long-term oral medication prescribed to other patients of any age in 
			 practice in the same year */					 
sort pracid year 
capture drop scriptlength_pracyr_mode
egen scriptlength_pracyr_mode  = mode(scriptlength), by(pracid year)
lab var scriptlength_pracyr_mode "Option 6: Pracid & year"
sum scriptlength_pracyr_mode, d

/* Option 7: Any long-term oral medication prescribed to any patient from any practice 
			 issued in the same year */
sort year 
capture drop scriptlength_yr_mode
egen scriptlength_yr_mode  = mode(scriptlength), by(year)
lab var scriptlength_yr_mode "Option 7: Year"
sum scriptlength_yr_mode, d	

*Replacement scriptlength by ascending order of options (if replacement > 1 day and < 1 year)
gen scriptlength_final = scriptlength_patprod_mode ///
	if (scriptlength_patprod_mode>0.9999 & scriptlength_patprod_mode<365.25999) 
gen scriptlength_method = 1 if scriptlength_final!=.

replace scriptlength_final = scriptlength_patsub_mode ///
	if scriptlength_final==. & (scriptlength_patsub_mode>0.9999 & scriptlength_patsub_mode<365.25999) 
replace scriptlength_method = 2 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_patmed_mode ///
	if scriptlength_final==. & ///			
	(scriptlength_patmed_mode>0.9999 & scriptlength_patmed_mode<365.25999) 
replace scriptlength_method = 3 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_pracsubstaff_mode ///
	if scriptlength_final==. & ///
	(scriptlength_pracsubstaff_mode>0.9999 & scriptlength_pracsubstaff_mode<365.25999) 
replace scriptlength_method = 4 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_pracstaff_mode ///
	if scriptlength_final==. & ///
	(scriptlength_pracstaff_mode>0.9999 & scriptlength_pracstaff_mode<365.25999) 
replace scriptlength_method = 5 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_prac_mode ///
	if 	scriptlength_final==. & ///
	(scriptlength_prac_mode>0.9999 & scriptlength_prac_mode<365.25999) 
replace scriptlength_method = 6 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_pracyr_mode ///
	if scriptlength_final==. & ///
	(scriptlength_pracyr_mode>0.9999 & scriptlength_pracyr_mode<365.25999) 
replace scriptlength_method = 7 if scriptlength_final!=. & scriptlength_method==. 

replace scriptlength_final = scriptlength_yr_mode ///
	if scriptlength_final==. & ///
	(scriptlength_yr_mode>0.9999 & scriptlength_yr_mode<365.25999) 
replace scriptlength_method = 8 if scriptlength_final!=. & scriptlength_method==. 
 
gen scriptlength_flag = 1 if scriptlength==.
lab var scriptlength_flag "Scriptlength imputed from scriptlength_final"
replace scriptlength = scriptlength_final if scriptlength==. | scriptlength>365.25    
sum scriptlength, d
lab var scriptlength_method "Imputed scriptlength method"
lab var scriptlength "qty/ndd, or imputed method"

drop scriptlength_yr_mode scriptlength_pracyr_mode scriptlength_prac_mode ///
scriptlength_pracstaff_mode scriptlength_pracsubstaff_mode age_group age ///
scriptlength_patmed_mode year_quarter year scriptlength_patsub_mode ///
scriptlength_patprod_mode

/* VMW: Generate output */

keep patid consid prodcode staffid textid bnfcode qty ndd numdays numpacks packtype issueseq eventdate sysdate filename index_date datetype prodname drugsubstance scriptlength_final scriptlength_method scriptlength_flag
bysort patid: egen duration = total(scriptlength_final)
replace duration = duration/365.25
