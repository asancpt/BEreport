%MACRO BETEST(DSNAME, VARNAME);
/* PROC GLM use only complete subjects. */
PROC GLM DATA=&DSNAME OUTSTAT=STATRES; 
  CLASS SEQ PRD TRT SUBJ;
  MODEL &VARNAME = SEQ SUBJ(SEQ) PRD TRT;
  RANDOM SUBJ(SEQ)/TEST;
  LSMEANS TRT /PDIFF=CONTROL('R') CL ALPHA=0.1 COV OUT=LSOUT;

DATA STATRES;
  SET STATRES;
  IF _TYPE_='ERROR' THEN CALL SYMPUT('DF', DF);

DATA LSOUT;
  SET LSOUT;
  IF TRT='R' THEN CALL SYMPUT('GMR_R', LSMEAN);
  IF TRT='T' THEN CALL SYMPUT('GMR_T', LSMEAN);
  IF TRT='R' THEN CALL SYMPUT('V_R', COV1);
  IF TRT='T' THEN CALL SYMPUT('V_T', COV2);
  IF TRT='T' THEN CALL SYMPUT('COV', COV1);

DATA LSOUT2;
  LNPE = &GMR_T - &GMR_R;
  DF = &DF;
  SE = SQRT(&V_R + &V_T - 2*&COV);
  LNLM = TINV(0.95, DF)*SE;
  LNLL = LNPE - LNLM ;
  LNUL = LNPE + LNLM;
  PE = EXP(LNPE);
  LL = EXP(LNLL);
  UL = EXP(LNUL);
  WD = UL - LL;
PROC PRINT DATA=LSOUT2; RUN;

/* PROC MIXED  uses all data. */
PROC MIXED DATA=&DSNAME; 
  CLASS SEQ TRT SUBJ PRD;
  MODEL &VARNAME = SEQ PRD TRT;
  RANDOM SUBJ(SEQ);
  ESTIMATE 'T VS R' TRT -1 1 /CL ALPHA=0.1; 
  ODS OUTPUT ESTIMATES=ESTIM COVPARMS=COVPAR;

DATA COVPAR;
  SET COVPAR;
  IF CovParm = 'Residual' THEN CALL SYMPUT('MSE', Estimate);

DATA ESTIM;
  SET ESTIM;
  MSE = &MSE;
  LNLM = (Upper - Lower)/2;
  PE = EXP(Estimate);
  LL = EXP(Lower);
  UL = EXP(Upper);
  WD = UL - LL;
PROC PRINT Data=ESTIM; RUN;

%MEND BETEST;

DATA PKDATA; 
  INFILE 'c:\Users\mdlhs\asancpt\BE-validation\sas\NCAResult4BE.csv' FIRSTOBS=2 DLM=",";
  INPUT SUBJ $ SEQ $ PRD $ TRT $ AUClast Cmax Tmax;
  IF CMAX =< 0 THEN DELETE;
  LNAUCL = LOG(AUClast);
  LNCMAX = LOG(Cmax);

*BE Test ;

%BETEST(PKDATA, LNAUCL);
%BETEST(PKDATA, LNCMAX);
