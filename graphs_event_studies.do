*Author: Bruna Mirelle

*********** Gráficos Event Studies ************************8

********* Gráfico com IC horizontal


*GRAFICO 
*ssc install  eclplot
*ssc install parmest
*ssc install dsconcat



*Event Studies 
	forv ano=2003/2017{
	gen dum_`ano' = (ano==`ano')
	gen treat_`ano' = dum_`ano'*status
	}
	order *, alphabetic
	
gen omitted = 0

 	forv ano=2003/2017{
	gen sexo_`ano' = (sexo_final==1)*dum_`ano'
	}

 	forv ano=2003/2017{
	gen idade_`ano' = idade_fixa*dum_`ano'
	}


  	forv ano=2003/2017{
	gen idade2_`ano' = idade_fixa*idade_fixa*dum_`ano'
	}



 




local controlsa1 " "
local controlsa2 sexo_2003-sexo_2017
local controlsa3  sexo_2003-sexo_2017 idade_2003-idade_2017 idade2_2003-idade2_2017

  
forv model = 1/3{
preserve
    tempfile tf1
    set more off
	*parmby "xi: reg emprego treat_2003-treat_2008 treat_2010-treat_2017 i.id dum_2004-dum_2017, r  cluster(cpf2)", lab saving(`tf1',replace) idn(1) 
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 `controlsa`model'', r  cluster(cpf2)", lab saving(`tf1',replace) idn(1) 

	dsconcat `tf1' 
	
	keep if inrange(parmseq,1,14)
	keep parmseq idnum parm estimate min95 max95
	rename parmseq time 
	rename estimate beta
	rename parm beta_name 

	gr two (line max95 time, color(gs6) lwidth(medthin) lpattern(dash))   ///
		   (line min95 time, color(gs6) lwidth(medthin) lpattern(dash))   ///
		   (scatter beta  time, msymbol(O) mcolor(black) lcolor(gs3) connect(l) msize(medlarge) lpattern(solid) lwidth(medthick)), ///
	scheme(s1color) plotregion(lcolor(none) )   ///
	ytitle("Employment") ylabel(, grid gex)   ///
	ylabel(-0.5(0.1)0.5, grid gex) yscale(range(-0.5 0.5))  name(figure1a, replace) ///
	yline(0, lp(solid) lwidth(thick) lcolor(gs6)) ///
	xlabel(1 "2003" 2 "2004" 3 "2005" 4 "2006" 5 "2007" 6 "2008" 7 "2009" 8 "2010" 9 "2011" 10 "2012" 11 "2013" ///
	12 "2014" 13 "2015" 14 "2016" 15 "2017", labsize(vsmall)) ///
		title(" ", color(gs3)) xtitle(" ") legend(off)
	graph save controlsa`model', replace
	graph export "controlsa`model'.png", replace
	graph export "controlsa`model'.eps", replace
restore

}




*Gráficos juntos
 
preserve
    tempfile tf1 tf2
    set more off
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 if sexo_final==1, r  cluster(cpf2)", lab saving(`tf1',replace) idn(1) 
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 if sexo_final==0, r  cluster(cpf2)", lab saving(`tf2',replace) idn(2) 

	dsconcat `tf1' `tf2' 
	
	keep if inrange(parmseq,1,14)
	keep parmseq idnum parm estimate min95 max95
	rename parmseq time 
	rename estimate beta
	rename parm beta_name 
	gr two   (line max95 time if idnum==1, color(red) lwidth(medthin) lpattern(dash))   ///
		  (line min95 time if idnum==1, color(red) lwidth(medthin) lpattern(dash))   ///
		  (line max95 time if idnum==2, color(black) lwidth(medthin) lpattern(dash))   ///
		  (line min95 time if idnum==2, color(black) lwidth(medthin) lpattern(dash))   ///
		   (scatter beta  time if idnum==2, msymbol(O) mcolor(black) lcolor(black) connect(l) msize(medlarge) lpattern(solid) lwidth(medthick)) ///
		   (scatter beta  time if idnum==1, msymbol(O) mcolor(red) lcolor(red) connect(l) msize(medlarge) lpattern(solid) lwidth(medthick)), ///
	scheme(s1color) plotregion(lcolor(none) )   ///
	ytitle("Employment") ylabel(, grid gex)   ///
	ylabel(-0.5(0.1)0.5, grid gex) yscale(range(-0.5 0.5))  name(figure1a, replace) ///
	yline(0, lp(solid) lwidth(thick) lcolor(gs6)) ///
	xlabel(1 "2003" 2 "2004" 3 "2005" 4 "2006" 5 "2007" 6 "2008" 7 "2009" 8 "2010" 9 "2011" 10 "2012" 11 "2013" ///
	12 "2014" 13 "2015" 14 "2016" 15 "2017", labsize(vsmall)) ///
		title(" ", color(gs3)) xtitle(" ") legend(off)
	graph save sexo1a, replace
	graph export sexo1a.png, replace
	graph export sexo1a.eps, replace
restore





**********Outro tipo de gráfico com IC vertical*****************


 * Event Studies: 2003-2017   

local controlsa1 " "
local controlsa2 sexo_2003-sexo_2017
local controlsa3  sexo_2003-sexo_2017 idade_2003-idade_2017 idade2_2003-idade2_2017

forv model = 1/3{
preserve
    tempfile tf1
    set more off
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 `controlsa`model'', r  cluster(cpf2)", lab saving(`tf1',replace) idn(1) 

	dsconcat `tf1' 
	
	keep if inrange(parmseq,1,15)
	keep parmseq idnum parm estimate min95 max95
	rename parmseq time 
	rename estimate beta
	rename parm beta_name 

	gr two  (rcap max95 min95 time, lcolor(black)) ///
		(scatter beta  time, msymbol(O) mcolor(black) lcolor(gs3) connect(l) msize(medium) lpattern(solid) lwidth(medium)), ///
	scheme(s1color) plotregion(lcolor(none) )   ///
	ytitle("Employment") ylabel(, grid gex)   ///
	ylabel(-0.2(0.1)0.2, nogrid) yscale(range(-0.2 0.2))  name(figure1a, replace) ///
	yline(0, lp(solid) lwidth(medthick) lcolor(black)) ///
	xlabel(1 "2003" 2 "2004" 3 "2005" 4 "2006" 5 "2007" 6 "2008" 7 "2009" 8 "2010" 9 "2011" 10 "2012" 11 "2013" ///
	12 "2014" 13 "2015" 14 "2016" 15 "2017", labsize(vsmall)) ///
		title(" ", color(gs3)) xtitle("Years") legend(off)
	*graph save controlsIC`model', replace
	graph export "controlsICa`model'.png", replace
	*graph export "controlsIC`model'.eps", replace
restore
}


*GRÁFICO DE HOMENS E MULHERES 
 
preserve
    tempfile tf1 tf2
    set more off
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 if sexo_final==1, r  cluster(cpf2)", lab saving(`tf1',replace) idn(1) 
	parmby "xi: reg emprego treat_2003-treat_2008 omitted treat_2010-treat_2017 i.id dum_2004-dum_2017 if sexo_final==0, r  cluster(cpf2)", lab saving(`tf2',replace) idn(2) 

	dsconcat `tf1' `tf2' 
	
	keep if inrange(parmseq,1,15)
	keep parmseq idnum parm estimate min95 max95
	rename parmseq time 
	rename estimate beta
	rename parm beta_name 
	gr two   (rcap max95 min95 time if idnum==1, lcolor(red)) ///
		 (rcap max95 min95 time if idnum==2, lcolor(black)) ///
		 (scatter beta  time if idnum==2, msymbol(O) mcolor(black) lcolor(gs3) connect(l) msize(medium) lpattern(solid) lwidth(medium)) ///
		 (scatter beta  time if idnum==1, msymbol(O) mcolor(red) lcolor(red) connect(l) msize(medium) lpattern(solid) lwidth(medium)), ///
	scheme(s1color) plotregion(lcolor(none) )   ///
	ytitle("Employment") ylabel(, grid gex)   ///
	ylabel(-0.2(0.1)0.2, nogrid) yscale(range(-0.2 0.2))  name(figure1a, replace) ///
	yline(0, lp(solid) lwidth(medthick) lcolor(black)) ///
	xlabel(1 "2003" 2 "2004" 3 "2005" 4 "2006" 5 "2007" 6 "2008" 7 "2009" 8 "2010" 9 "2011" 10 "2012" 11 "2013" ///
	12 "2014" 13 "2015" 14 "2016" 15 "2017", labsize(vsmall)) ///
		title(" ", color(gs3)) xtitle("Years") legend(off)
	*graph save sexo1a, replace
	graph export sexoIC1a.png, replace
	*graph export sexoIC1a.eps, replace
restore
