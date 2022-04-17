%let name=GMC_Estimated_Growth_Mapping;
filename filegmc url "https://lipy.us/data/gm_counters_esti.csv";
filename odshtml "/home/html";

proc import out=gm0dgmc	datafile=filegmc dbms=csv replace; getname=yes; datarow=2; run;
data gm0dgmc; set gm0dgmc (where=(state not in ('AK' 'DC' 'HI' 'PR'))); run;
proc geocode out=gm0dgmc data=gm0dgmc lookup=sashelp.zipcode method=city; run;
data gm1dcity; set gm0dgmc (where=(_matched_^='None')); run;
proc geocode out=gm2dzip data=gm0dgmc (where=(_matched_='None')) lookup=sashelp.zipcode method=zip; run;
data gm0dgmc; set gm1dcity gm2dzip; run;
proc sort out=gm0dgmc data=gm0dgmc; by begdate; run;

data gm3adots (drop=state); set gm0dgmc; anno_flag=1; long=x; lat=y; statecode=state; year=year(begdate); run;
data gm4astates; set mapsgfk.uscenter (where=(statecode not in ('AK' 'DC' 'HI' 'PR'))); anno_flag=2; run;
data gm5ausa; set mapsgfk.us_states (where=(fipstate(state) not in ('AK' 'DC' 'HI' 'PR') and (density<3))); run;
data gm6acomb; set gm5ausa gm3adots gm4astates; run;

proc gproject data=gm6acomb out=gm6acomb latlong eastlong degrees dupok; id statecode; run;
data gm5ausa gm3adots gm4astates; set gm6acomb; if anno_flag=1 then output gm3adots; else if anno_flag=2 then output gm4astates; else output gm5ausa; run;

data gm3adots; set gm3adots; length function $8 color $20 text $20; xsys='2'; ysys='2'; hsys='3'; when='a'; function='pie'; rotate=360; size=0.7; style='psolid';
	color='Aff000077'; output; style='pempty'; color='gray66'; line=1; output; run;
data gm4astates; length function $8 color $20 style $20; xsys='2'; ysys='2'; hsys='3'; when='a'; retain flag 0; set gm4astates; function='label';
	style='albany amt/bold'; text=fipstate(state); size=2.25; color='gray66'; position='5';
	if ocean='Y' then do; position='6'; output; function='move'; flag=1; end; else if flag=1 then do; function='draw'; size=.25; flag=0; end; output; run;

goptions reset=all; goptions xpixels=1000 ypixels=650; goptions border;
options dev=sasprtc printerpath=gif animduration=.5 animloop=0 animoverlay=no animate=start;
ods _all_ close; ods listing close;
ods html path=odshtml (url=none) gpath=odshtml (url=none) body="&name..html" (title="GM Counters in USA - Estimated") style=htmlblue;

%macro do_year;
%do i = 1958 %to 2022;
    data gm7ydots; set gm3adots (where=(year<=&i)); run;
    proc sql noprint; select count(*) format=comma8.0 into :totalcnt separated by ' ' from gm7ydots where style='psolid'; quit; run;
    data gm8ydata; length text $100; xsys='3'; ysys='3'; hsys='3'; when='a'; function='label'; style='albany amt/bold'; color='gray44';
    	x=5; position='6'; text="Estimated: &totalcnt"; y=22; size=3; output; text="&i"; y=12; size=15; output;
    	x=75; position='5'; text="GM Counters"; y=95; size=6; output; run;
    data gm9yall; set gm4astates gm7ydots gm8ydata; run;
    goptions gunit=pct ftitle="albany amt/bold" ftext="albany amt" htitle=5 htext=3.0; pattern1 v=s c=cxf7e7bd;
    proc gmap map=gm5ausa data=gm5ausa all; id statecode; choro state / levels=1 nolegend coutline=gray66 anno=gm9yall des='' name="&name"; run;
%end;
%mend;

%do_year;

quit;
ods html close; ods listing;