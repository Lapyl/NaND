%let name=CPM_Data_Analysis;
filename filecpm1 url "https://lipy.us/data/2022_2_GMC_31164B313435D3_Montclair_3407_w11772.txt";
filename filecpm2 url "https://lipy.us/data/2022_1_GMC_37074B313530AA_YorbaLinda_3389_w11780.txt";
filename filegif "/home/html/&name..gif";
filename odshtml "/home/html";

%if %sysfunc(exist(cpm0)) %then %do; proc delete data=cpm0; run; %end;
%if %sysfunc(exist(cpm1)) %then %do; proc delete data=cpm1; run; %end;
%if %sysfunc(exist(cpm2)) %then %do; proc delete data=cpm2; run; %end;
%if %sysfunc(exist(cpm3)) %then %do; proc delete data=cpm3; run; %end;
%if %sysfunc(exist(cpm4)) %then %do; proc delete data=cpm4; run; %end;
%if %sysfunc(exist(cpm5)) %then %do; proc delete data=cpm5; run; %end;

data cpm1; infile filecpm1 recfm=n dlm='{[",:';	input reco : $13. @@; run;
data cpm2; infile filecpm2 recfm=n dlm='{[",:';	input reco : $13. @@; run;

data cpm1; set cpm1; reco=strip(reco); where length(strip(reco))>12; run;
data cpm2; set cpm2; reco=strip(reco); where length(strip(reco))>12; run;

data cpm1; set cpm1; Cpm=input(substr(strip(reco),12,2), 2.);
	MDH=input(substr(strip(reco),1,6), 6.); N=input(substr(strip(reco),7,2), 2.); run;
data cpm2; set cpm2; Cpm=input(substr(strip(reco),12,2), 2.);
	MDH=input(substr(strip(reco),1,6), 6.); N=input(substr(strip(reco),7,2), 2.); run;

data cpm1; set cpm1; where Cpm>0; run;
data cpm2; set cpm2; where Cpm>0; run;

proc sql;
	create table cpm0 as (select MDH, N from ((select * from cpm1) union (select * from cpm2)) as A group by MDH, N);

	create table cpm3 as (select MDH, N, int(mean(Cpm)) as CpmM from cpm1 group by MDH, N);
	create table cpm4 as (select MDH, N, int(mean(Cpm)) as CpmY from cpm2 group by MDH, N);

	create table cpm5 as (
		select A.MDH, A.N, A.cpmM, B.cpmY from (
		(select cpm0.MDH, cpm0.N, cpm3.CpmM from cpm0 left join cpm3 on (cpm0.MDH=cpm3.MDH and cpm0.N=cpm3.N)) as A
		inner join
		(select cpm0.MDH, cpm0.N, cpm4.CpmY from cpm0 left join cpm4 on (cpm0.MDH=cpm4.MDH and cpm0.N=cpm4.N)) as B
		on (A.MDH=B.MDH and A.N=B.N)));
run;
proc sort data=cpm5 out=sort; by MDH N; run;

ods graphics / imagefmt=GIF width=6in height=4in;
options papersize=('6 in','4 in')	nodate nonumber
	animduration=0.5 animloop=yes noanimoverlay	printerpath=gif animation=start;
ods printer file=filegif;

title "CountsPerMinute by Minute in Montclair and YorbaLinda (Y)";
proc sgplot data=cpm5; by MDH;
	series x=N y=CpmM / legendlabel="Montclair";
	series x=N y=CpmY / legendlabel="YorbaLinda";
	xaxis lable="Minute"; yaxis label="CountsPerMinute";
	xaxis integer values=(1 to 60); yaxis min=0 max=30 grid;
run;
title;

options printerpath=gif animation=stop;
ods printer close;