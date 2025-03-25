/*Identifying trends and patterns*/

/* Table1 (Analysing Seasonal Trends in Demand)*/
proc means data=AMA.AMAQUB n mean stddev min max maxdec=2;
    class Season;
    var DemandForecast_DAM;
    title "Summary Statistics for Demand by Season";
run;

/*Figure 1 (Seasonal Demand Trends Over Time)*/
proc sgplot data=AMA.AMAQUB;
    series x=StartDateTime y=DemandForecast_DAM / group=Season;
    title "Seasonal Demand Trends Over Time";
run;

/*Figure 2(Av Demand by Weekday: Summer vs Winter)*/
/* Create a format to label the weekday numbers */
proc format;
    value weekdayfmt
        1 = "Sunday"
        2 = "Monday"
        3 = "Tuesday"
        4 = "Wednesday"
        5 = "Thursday"
        6 = "Friday"
        7 = "Saturday";
run;

/* Plot using numeric order */
data AMA.WeekdaySorted;
    set AMA.WeekdaySorted;
    if Season = "W" then SeasonGroup = 1;
    else if Season = "S" then SeasonGroup = 2;
run;
proc sort data=AMA.WeekdaySorted;
    by WeekdayOrder SeasonGroup;
run;
proc sgplot data=AMA.WeekdaySorted;
    styleattrs datacolors=(brown darkblue);  /* First group = Winter (W), second = Summer (S) */

    vbar WeekdayOrder / response=DemandForecast_DAM stat=mean 
        group=Season groupdisplay=cluster datalabel;

    format WeekdayOrder weekdayfmt.;
    yaxis label="Average Demand";
    title "Average Demand by Weekday: Winter vs Summer";
run;

/*Table 2(Electricity Demand by TimeBlock)*/
PROC MEANS DATA=AMA.AMAQUB N MEAN STDDEV MIN MAX maxdec=2;
    CLASS ISEMBlock;
    VAR DemandForecast_DAM;
    TITLE "Electricity Demand by Time Block";
RUN;


/*INITIAL REGRESSION ANALYSIS*/
proc reg data=AMA.AMAQUB; 
 model ISEM_DA_Price = StartHr WeekdayNum FuelGas FuelCarbon DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM  GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability;
run;
quit;

 
 /*DIAGNOSTICS*/

/*OUTLIERS*/

/*RSTUDENT*/
proc reg data=AMA.AMAQUB;
    model ISEM_DA_Price = StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability;
    
    output out=diagnostics student=rstudent_resid;
run;
quit;

proc print data=diagnostics;
    where abs(rstudent_resid) > 3;
run;

/*COOKSD*/
proc reg data=AMA.AMAQUB;
    model ISEM_DA_Price = StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability;
    
    output out=diagnostics cookd=cookd;
run;
quit;

/* Check high influence points */
proc print data=diagnostics;
    where cookd > 4 / 52580; /* Replace 52580 with actual dataset size */
run;


/*REMOVING THE OUTLIERS*/
data AMA.CleanedData;
    set diagnostics;
    /* Remove observations with high studentized residuals or cook's distance */
    if abs(rstudent_resid) <= 3 and cookd <= 4 / 52580 ; 
run;

/*RERUNNING THE REGRESSION TO SEE IF ANY IMPROVEMENTS*/
proc reg data=AMA.CleanedData;
    model ISEM_DA_Price = StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability;
run;
quit;

/*Selection methods on cleaned data*/
 proc reg data=AMA.cleaneddata;
 model ISEM_DA_Price = StartDateTime StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability/selection=forward
 slentry=0.15;
 run;


ods graphics on;
 proc reg data=AMA.CLEANEDDATA;
 model ISEM_DA_Price = StartDateTime StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability /selection=backward
 slstay=0.10;
 run;
 
ods graphics off;

 proc reg data=AMA.cleaneddata;
 model ISEM_DA_Price = StartDateTime StartHr WeekdayNum FuelGas FuelCarbon 
        DemandForecast_DAM WindForecast_DAM NetDemandForecast_DAM 
        GB_DA_N2EX_Price_FC GB_DAM_N2EX_Price DAM_Unavailability /selection=stepwise
 slentry =0.15 slstay=0.15;
 run;

