%let name=CPM_to_Noise_Classication;

proc freq data=CN1;
    table _Fraction_PartInd_ * I_Lab / out=CellCounts;
    run;
data CellCounts;
    set CellCounts;
    Match=0;
    if Crop=_INTO_ then Match=1;
    run;
proc means data=CellCounts mean;
    freq count;
    var Match;
    run;