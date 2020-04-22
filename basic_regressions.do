*Author:  Bruna Mirelle 

*use "DATASET"
clear
cd "xxxxxxxxxxxxxxxxxxx"
import delimited "xxxxxxxxxxx.csv" 
set more off


********************************************************
*Dataset has 650 observations - Lottery dataset
*Years = 2003 to 2017 
********************************************************


***************Duplicates***********************************
duplicates report    

********Duplicado  
*Quantas duplciadas aparecem em 2010
duplicates report cpf curso if ano==2010

*Quantas pessoas aparecem mais de uma vez na RAIS
duplicates tag cpf curso2 if ano==2010, generate(dup_cpf_curso)
collapse (mean) dup_cpf_curso, by(cpf)
eststo clear
estpost tab dup_cpf_curso
eststo
esttab est1 using tab1.tex, cells("b(label(Freq)) pct(label(Perc.)) cumpct(label(Cum.))") label nodepvar replace

********Duplicado Geral
*Ano do sorteio = 2010
duplicates report cpf2 if ano==2010
*Quantas pessoas aparecem mais de uma vez 
duplicates tag cpf2 if ano==2010, generate(dup_cpf_geral)
collapse (mean) dup_cpf_geral, by(cpf)
eststo clear
estpost tab dup_cpf_geral
eststo
esttab est1 using tabg.tex, cells("b(label(Freq)) pct(label(Perc.)) cumpct(label(Cum.))") label nodepvar replace


*Duplicados curso 
gen dup_final = dup_cpf_geral - dup_cpf_curso

*Contando unicos
collapse (mean) dup_final, by(cpf)
tab dup_final
eststo clear
estpost tab dup_final
eststo
esttab est1 using tab.tex, cells("b pct cumpct") label nodepvar


duplicates tag cpf curso2, generate(dup_cpf_curso)
duplicates tag cpf2, generate(dup_cpf_geral)
gen dup_final = dup_cpf_geral - dup_cpf_curso

*Colapsando uma pessoa por ano  

collapse (mean) salario emprego sexo_final, by(ano nome cpf2 cpf curso curso2 status dup_final idade)
 

*Deixando as pessoas que aparecem em mais de um sorteio 
gen id = curso + "-" + cpf
encode id, gen(id2)
drop id
rename id2 id

*Painel
xtset id 


*
*****************Preenchendo idade
bysort cpf2: egen maxidade = max(idade)
gen index_maxidade = 0 
replace index_maxidade = 1 if maxidade == idade
gen anomax = ano*index_maxidade
bysort cpf2: egen anowheremax = max(anomax)
replace idade = maxidade + (ano-anowheremax) if missing(idade)

gen idade_fixa=idade - (ano-2010)
 
*******************Mostrar cpfs que aparecem pelo menos em algum momento da RAIS: 

*Apareceu pela primeira vez
by cpf2 (ano), sort: gen byte first = sum(emprego) == 1  & sum(emprego[_n - 1]) == 0 
*Número de ocorrências
by cpf2 (ano), sort: gen noccur = sum(emprego)
*Dummy de apareceu ou não 
by cpf2, sort: gen appear = sum(first)==1
by cpf2, sort: replace appear=1 if sum(appear[_N])==1
by cpf2, sort: replace appear=1 if sum(appear)==1

gen rais = (noccur>0)
estpost tab rais if ano==2010
estpost tab rais if ano==2017
estpost appear rais if ano==2017
esttab . using appear_ano.tex, cell(b pct) unstack noobs replace



*Variavel tratamento
replace status = "." if status=="NA"
replace status = "1" if status=="convocado"
replace status = "0" if status=="lista de espera"
destring status, replace


*Tabela descritiva painel
 estpost tabstat status salario emprego sexo_final idade_fixa if ano==2017, by(curso2) statistics(mean sd max min) columns(statistics) listwise
 esttab .  using cursos.tex, main(mean) aux(sd) cells("mean sd max min") replace 
 estpost tabulate curso2 status if ano==2017
 esttab . using status.tex, cell(b) unstack noobs replace
estpost tabulate curso2 rais if ano==2017
 esttab . using rais.tex, cell(b) unstack noobs replace

 estpost tabstat status salario emprego sexo_final, statistics(mean sd max min) columns(statistics) listwise
 esttab .  using cursos.tex, main(mean) aux(sd) cells("mean sd max min")  noobs
 estpost tab status
 esttab . using status.tex, cell(b) unstack noobs replace




*Balance 
tab curso2, gen(dumcurso)

foreach year of num 2003/2009 {
matrix mat_`year' = J(4,4,0)
matrix colnames mat_`year' = "ControlMean" "T-C" "SE" "Observations"
matrix rownames mat_`year' = "Wage" "Employment" "Gender" "Age"
local i = 1
	foreach var of varlist salario emprego sexo idade_fixa{
		reg `var' status dumcurso* if ano==`year', rob 
		//di mat_`year'[`i',1]
		matrix mat_`year'[`i',1] = _b["_cons"]
		matrix mat_`year'[`i',2] = _b["status"]
		matrix mat_`year'[`i',3] = _se["status"]
		matrix mat_`year'[`i',4] = e(N)
		local ++i
		di `i'
	}
	outtable using balance_`year',  mat(mat_`year') center caption(`year') nobox replace 
}




****************** Regressões

eststo clear

gen aux = emprego if ano==2009
bysort cpf2: egen y2009 = max(aux)
set more off
*Cross Section
foreach year of num 2010/2017 {
local i = 1
	foreach var of varlist emprego{
	 reg `var' status dumcurso* if ano==`year', rob 
	 eststo m1
	 reg `var' status sexo dumcurso* if ano==`year', rob 
	 eststo m2
	 reg `var' status sexo c.idade_fixa##c.idade_fixa dumcurso* if ano==`year', rob 
	 eststo m3
	 reg `var' status sexo c.idade_fixa##c.idade_fixa y2009 dumcurso* if ano==`year', rob 
	 eststo m4
	 reg `var' status dumcurso* if ano==`year' & sexo==1, rob 
	 eststo m5
	 reg `var' status dumcurso* if ano==`year' & sexo==0, rob 
	 eststo m6
	 esttab * using cross_`year'.tex, cells(b(star fmt(%9.3f)) se(par)) stats(r2_a N, fmt(%9.3f %9.0g) labels(R-squared)) legend collabels(none) varlabels(_cons Constant sexo_final gender idade_fixa age c.idade_fixa#c.idade_fixa  "age x age") mtitles("employment" "employment" "employment" "employment" "employment women" "employment men") title(`year') drop(dumcurso*) star(* 0.10 ** 0.05 *** 0.01) addnote("Note: Year and course fixed effects. Robust standard errors") replace
		local ++i
		di `i'
		eststo clear
	}
	
}



*Diff-in-Diff

gen time = (ano>=2010) & !missing(ano)
gen treated_post10 = time*status
set more off
	xtreg emprego treated_post10 i.ano , fe cluster(cpf2)  
	 eststo m1
	xtreg emprego treated_post10 i.ano#sexo i.ano , fe cluster(cpf2) 
	 eststo m2
	xtreg emprego treated_post10 i.ano#i.sexo i.ano  i.ano#c.idade_fixa##c.idade_fixa, fe cluster(cpf2) 
	 eststo m3
	xtreg emprego treated_post10 i.ano#i.sexo i.ano i.ano#c.idade_fixa##c.idade_fixa i.ano#y2009, fe cluster(cpf2) 
	eststo m4
	xtreg emprego treated_post10 i.ano if sexo==1 , fe cluster(cpf2)  
	eststo m5
	xtreg emprego treated_post10 i.ano if sexo==0 , fe cluster(cpf2)  
	eststo m6


	 esttab * using diff.tex, cells(b(star fmt(%9.3f)) se(par)) stats(r2_a N_clust N, fmt(%9.3f %9.0g  %9.0g) labels(R-squared "Number of cpfs" "Observations")) collabels(none) coeflabels(_cons Constant treated_post10 Status.Pos10) title("Diff-in-Diff") mtitles("employment" "employment" "employment" "employment" "employment women" "employment men") keep(_cons treated_post10) star(* 0.10 ** 0.05 *** 0.01) addnote("Note:cluster at the individual level. Individual and Year fixed effects.") replace
		
	eststo clear
	
 	
*POOLED OLS
reg emprego status  i.ano dumcurso*  if ano>=2012, cluster(cpf2)	
eststo m0
reg emprego status sexo_final i.ano dumcurso*  if ano>=2012, cluster(cpf2)	
eststo m1
reg emprego status sexo_final c.idade_fixa##c.idade_fixa  i.ano dumcurso*  if ano>=2012, cluster(cpf2)	
eststo m2
reg emprego status sexo_final c.idade_fixa##c.idade_fixa y2009  i.ano dumcurso*  if ano>=2012, cluster(cpf2)	
eststo m3
reg emprego status  i.ano dumcurso*  if ano>=2012 & sexo==1, cluster(cpf2)	
eststo m4
reg emprego status  i.ano dumcurso*  if ano>=2012 & sexo==0, cluster(cpf2)	
eststo m5	
esttab * using pooled.tex, cells(b(star fmt(%9.3f)) se(par)) stats(r2_a N_clust N, fmt(%9.3f %9.0g  %9.0g) labels(R-squared "Number of cpfs" "Observations")) collabels(none) coeflabels(_cons Constant Status) title("Diff-in-Diff") keep(_cons status) mtitles("employment" "employment" "employment" "employment women" "employment men") star(* 0.10 ** 0.05 *** 0.01) addnote("Note:cluster at the individual level. Year and course fixed effects") replace
	
eststo clear
	
	
	
	
*Event Studies 
	forv ano=2003/2017{
	gen dum_`ano' = (ano==`ano')
	gen treat_`ano' = dum_`ano'*status
	}
	order *, alphabetic
	xtreg emprego treat_2003-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017, fe  cluster(cpf2) 
	 eststo m1
	 coefplot m1, drop(_cons dum_2004 dum_2005 dum_2006 dum_2007 dum_2008 dum_2009 dum_2010 dum_2011 dum_2012 dum_2013 dum_2014 dum_2015 dum_2016 dum_2017) vertical yline(0)
	xtreg emprego treat_2003-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 i.ano#i.sexo, fe  cluster(cpf2) 
	 eststo m2
	 coefplot m2, drop(_cons dum_2004 dum_2005 dum_2006 dum_2007 dum_2008 dum_2009 dum_2010 dum_2011 dum_2012 dum_2013 dum_2014 dum_2015 dum_2016 dum_2017 ano*) vertical yline(0)
	xtreg emprego treat_2003-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 i.ano#i.sexo i.ano#c.idade_fixa##c.idade_fixa, fe  cluster(cpf2) 
	 eststo m3
	 coefplot m3, drop(_cons dum_2004 dum_2005 dum_2006 dum_2007 dum_2008 dum_2009 dum_2010 dum_2011 dum_2012 dum_2013 dum_2014 dum_2015 dum_2016 dum_2017 ano*) vertical yline(0)
	xtreg emprego treat_2003-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 if sexo==1, fe  cluster(cpf2) 
	 eststo m4
	 xtreg emprego treat_2003-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 if sexo==0, fe  cluster(cpf2) 
	 eststo m5


	esttab * using event.tex, cells(b(star fmt(%9.3f)) se(par)) stats(r2_a N_clust N, fmt(%9.3f %9.0g  %9.0g) labels(R-squared "Number of cpfs" "Observations")) collabels(none) coeflabels(_cons Constant) title("Event Studies") keep(treat*) mtitles("employment" "employment" "employment" "employment women" "employment men") star(* 0.10 ** 0.05 *** 0.01) addnote("Note:cluster at the individual level. Individual and year fixed effect") replace
	eststo clear
	
	xtreg emprego treat_2007-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 if ano>=2007, fe cluster(cpf2) 
	 eststo m3
 	xtreg emprego treat_2007-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017  i.ano#i.sexo_final if ano>=2007, fe cluster(cpf2) 
	 eststo m4
 	xtreg emprego treat_2007-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017  i.ano#i.sexo_final i.ano#c.idade_fixa##c.idade_fixa if ano>=2007, fe cluster(cpf2) 
	 eststo m5
	xtreg emprego treat_2007-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 if ano>=2007 & sexo_final==1, fe cluster(cpf2) 
	 eststo m6
	 xtreg emprego treat_2007-treat_2008 treat_2010-treat_2017  dum_2004-dum_2017 if ano>=2007 & sexo_final==0, fe cluster(cpf2) 
	 eststo m7
	esttab * using event2.tex, cells(b(star fmt(%9.3f)) se(par)) stats(r2_a N_clust N, fmt(%9.3f %9.0g  %9.0g) labels(R-squared "Number of cpfs" "Observations")) collabels(none) coeflabels(_cons Constant) title("Event Studies") keep(treat*) mtitles("employment" "employment" "employment" "employment women" "employment men") star(* 0.10 ** 0.05 *** 0.01) addnote("Note:cluster at the individual level. Individual and year fixed effect") replace


 ******** Tabelas automáticas Tab e Tabulate 
estpost tab cnpj
esttab . using cnpj.tex, cell(b pct) unstack noobs replace
 
estpost tabulate correto sexotrabalhador
esttab . using ocupacao.tex, cell(b(fmt(0))) unstack noobs replace
 
