%let name=CPM_to_Storms_Estimated_Correlation;
filename filesto1 url "https://lipy.us/data/Storms_data_USA_2001p.csv";
filename filesto2 url "https://lipy.us/data/Abnormal_CPM.csv";
filename odshtml "/home/html";

proc import out=cs0dstorm datafile=filesto1 dbms=csv replace; getname=yes; datarow=2; run;
proc import out=cs0dcpm datafile=filesto2 dbms=csv replace; getname=yes; datarow=2; run;
data cs0dstorm; set cs0dstorm; Loc='Storm'; Col='red'; run; data cs0dcpm; set cs0dcpm; Loc='CPM'; Col='blue'; run; data cs1dcomb; set cs0dstorm cs0dcpm; run;
data cs1dcomb; set cs1dcomb; Year=year(datepart(ISO_TIME)); Mon=month(datepart(ISO_TIME));
	Lat=int(10*LAT)/10; Long=int(10*LON)/10; keep Year Mon Lat Long Loc Col; run;
proc sort data=cs1dcomb; by Year Lat Long Loc Col; run;
data cs2duse; set cs1dcomb; by Year Lat Long Loc Col;
	retain N; if first.Col then N=1; else N=N+1; if last.Col then output;
   	keep Year Lat Long Loc Col N; run;
data cs2duse; set cs2duse; N=0.0001; run;

goptions reset=all border hsize=5.5in vsize=4.2in;
ods html path=odshtml body="&name._.htm" style=htmlblue;
ods graphics / imagefmt=png imagename="&name._";
proc sgmap mapdata=mapsgfk.us plotdata=cs2duse; title1 &name.;
	openstreetmap; bubble x=long y=lat size=N / group=Loc; run;
quit; ods html close; ods listing;

data cs3adots; set cs2duse; anno_flag=1; statecode='US'; run;
data cs4astates; set mapsgfk.uscenter (where=(statecode not in ('AK' 'DC' 'HI' 'PR'))); anno_flag=2; run;
data cs5ausa; set mapsgfk.us_states (where=(fipstate(state) not in ('AK' 'DC' 'HI' 'PR') and (density<3))); run;
data cs6acomb; set cs5ausa cs3adots cs4astates; run;

proc gproject data=cs6acomb out=cs6acomb latlong eastlong degrees dupok; id statecode; run;
data cs5ausa cs3adots cs4astates; set cs6acomb; if anno_flag=1 then output cs3adots; else if anno_flag=2 then output cs4astates; else output cs5ausa; run;

data cs3adots; set cs3adots; length function $8 color $20 text $20; retain xsys ysys '1'; xsys='2'; ysys='2'; hsys='3'; when='a'; function='pie'; rotate=360; size=.5; style='psolid';
	color=Col; output; style='pempty'; color='gray66'; line=1; output; run;
data cs4astates; length function $8 color $20 style $20; retain xsys ysys '1'; xsys='2'; ysys='2'; hsys='3'; when='a'; retain flag 0; set cs4astates; function='label';
	style='albany amt/bold'; text=fipstate(state); size=2.25; color='gray66'; position='5';
	if ocean='Y' then do; position='6'; output; function='move'; flag=1; end; else if flag=1 then do; function='draw'; size=.25; flag=0; end; output; run;

goptions reset=all; goptions xpixels=1000 ypixels=650; goptions border;
options dev=sasprtc printerpath=gif animduration=.5 animloop=0 animoverlay=no animate=start;
ods _all_ close; ods listing close;
ods html path=odshtml (url=none) gpath=odshtml (url=none) body="&name..html" (title="GM Counters in USA - Estimated") style=htmlblue;

%macro do_year;
%do i = 2001 %to 2021;
    data cs7ydots; set cs3adots (where=(year<=&i)); run;
    data cs8ydata; length text $100; retain xsys ysys '1'; xsys='3'; ysys='3'; hsys='3'; when='a'; function='label'; style='albany amt/bold'; color='gray44';
    	x=5; position='6'; text="&i"; y=12; size=15; output; x=60; position='5'; text="CPM vs Storms"; y=95; size=3; output; run;
    data cs9yall; set cs4astates cs7ydots cs8ydata; run;
    goptions gunit=pct ftitle="albany amt/bold" ftext="albany amt" htitle=5 htext=3.0; pattern1 v=s c=cxf7e7bd;
    proc gmap map=cs5ausa data=cs5ausa all; id statecode; choro state / levels=1 nolegend coutline=gray66 anno=cs9yall des='' name="&name"; run;
%end;
%mend;

%do_year;

quit;
ods html close; ods listing;
