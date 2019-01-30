* EVENTS

global ht_treat "ht_aab ht_ace ht_ace_ccb ht_ace_thi ht_anb ht_arb ht_arb_ccb ht_arb_ccb_thi ht_arb_thi ht_bab ht_bab_ccb ht_bab_ld ht_bab_ld_thi ht_bab_psd_thi ht_bab_thi ht_caa ht_ccb ht_ccb_thi ht_ld ht_ld_psd ht_psd ht_psd_thi ht_ren ht_thi ht_vad"

global ht_proto "ht_bab ht_aab ht_ace ht_arb ht_caa ht_ccb ht_ld ht_psd ht_thi ht_vad"

global ht_base "ht_bab"

global ht_paper "ht_aab ht_arb ht_ace ht_bab ht_ccb ht_diu ht_vad"

global hc_treat "hc_bas hc_eze hc_eze_sta hc_fib hc_nag hc_om3 hc_sta"

global hc_proto "hc_sta hc_fib hc_bas hc_om3 hc_eze hc_nag"

global hc_base "hc_sta"

global dm_treat "dm_big dm_big_oad dm_oad dm_sul"

global dm_proto "dm_big dm_sul dm_oad"

global dm_base "dm_big"

global dem_cond "dem_adposs dem_adprob dem_ns dem_oth dem_vas"

global dem_treat "dem_don dem_gal dem_mem dem_riv"

global dem_diag "dem_adprob dem_adposs dem_vas dem_oth dem_mixadprob dem_mixadposs dem_mixnoad dem_undiag" // order must match definition of var dementia_diagnosis

* DATE & FREQ

foreach z in date freq type staff {

	local event_global = "ht_treat hc_treat dm_treat ht_proto ht_paper hc_proto dm_proto dem_cond dem_treat"
	foreach y in `event_global' {
		local `y'_`z' = ""
		foreach x in $`y' {
			local `y'_`z' "``y'_`z'' `x'_`z'"
		}
		global `y'_`z' = "``y'_`z''"
	}
		
}
