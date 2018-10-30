*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

*
This file uses four merged data sets to address research questions regarding
graduation and dropout rates for students at schools in California during the
2014-2015 and 2015-2016 academic years.
;

*
[Dataset 1 Name] grad1415

[Dataset Description] Graduates by Ethnicity and School, 2014-15

[Experimental Unit Description] Data for graduates of high schools in California
in AY2014-2015 by ethnicity and school

[Number of Observations] 2490

[Number of Features] 15

[Data Source] http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2014-15&cCat=GradEth&cPage=filesgrad.asp,
downloaded and then converted to xls format

[Data Dictionary] https://www.cde.ca.gov/ds/sd/sd/fsgrad09.asp

[Unique ID Schema] Column "CDS_CODE" uniquely identifies each school in
California that produced graduates in 2015.

--

[Dataset 2 Name] grad1516

[Dataset Description] Graduates by Ethnicity and School, 2015-16

[Experimental Unit Description] Data for graduates of high schools in California
in AY2015-2016 by ethnicity and school

[Number of Observations] 2521

[Number of Features] 15

[Data Source] http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2015-16&cCat=GradEth&cPage=filesgrad.asp,
downloaded and then converted to xls format

[Data Dictionary] https://www.cde.ca.gov/ds/sd/sd/fsgrad09.asp

[Unique ID Schema] Column "CDS_CODE" uniquely identifies each school in
California that produced graduates in 2016.

--

[Dataset 3 Name] dropouts1415

[Dataset Description] Dropouts by Race & Gender, 2014-2015

[Experimental Unit Description] Data for dropouts from junior high and high
schools in California in AY2014-2015 by race, gender, and school

[Number of Observations] 58,875

[Number of Features] 20

[Data Source] http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2014-15&cCat=Dropouts&cPage=filesdropouts,
downloaded and then converted to xls format

[Data Dictionary] https://www.cde.ca.gov/ds/sd/sd/fsdropouts.asp

[Unique ID Schema] The CDS_CODE, ETHNIC, and GENDER columns comprise a composite
 key that uniquely identifies groups by school, ethnic background, and gender.

--

[Dataset 4 Name] dropouts1516

[Dataset Description] Dropouts by Race & Gender, 2015-2016

[Experimental Unit Description] Data for dropouts from junior high and high
schools in California in AY2015-2016 by race, gender, and school

[Number of Observations] 59,316

[Number of Features] 20

[Data Source] http://dq.cde.ca.gov/dataquest/dlfile/dlfile.aspx?cLevel=School&cYear=2015-16&cCat=Dropouts&cPage=filesdropouts,
downloaded and then converted to xls format

[Data Dictionary] https://www.cde.ca.gov/ds/sd/sd/fsdropouts.asp

[Unique ID Schema] The CDS_CODE, ETHNIC, and GENDER columns comprise a composite
key that uniquely identifies groups by school, ethnic background, and gender.
;

* environmental setup;

* create output formats;

* setup environmental parameters;

%let inputDataset1URL =
https://github.com/johnbville/ca_ach_gap_sas/blob/master/data/grad1415.xls?raw=true
;
%let inputDataset1Type = xls;
%let inputDataset1DSN = grad1415_raw;

%let inputDataset2URL =
https://github.com/johnbville/ca_ach_gap_sas/blob/master/data/grad1516.xls?raw=true
;
%let inputDataset2Type = xls;
%let inputDataset2DSN = grad1516_raw;

%let inputDataset3URL =
https://github.com/johnbville/ca_ach_gap_sas/blob/master/data/dropouts1415.xls?raw=true
;
%let inputDataset3Type = xls;
%let inputDataset3DSN = dropouts1415_raw;

%let inputDataset4URL =
https://github.com/johnbville/ca_ach_gap_sas/blob/master/data/dropouts1516.xls?raw=true
;
%let inputDataset4Type = xls;
%let inputDataset4DSN = dropouts1516_raw;


* load raw datasets over the wire, if they doesn't already exist;
%macro loadDataIfNotAlreadyAvailable(dsn,url,filetype);
    %put &=dsn;
    %put &=url;
    %put &=filetype;
    %if
        %sysfunc(exist(&dsn.)) = 0
    %then
        %do;
            %put Loading dataset &dsn. over the wire now...;
            filename tempfile "%sysfunc(getoption(work))/tempfile.xlsx";
            proc http
                method="get"
                url="&url."
                out=tempfile
                ;
            run;
            proc import
                file=tempfile
                out=&dsn.
                dbms=&filetype.;
            run;
            filename tempfile clear;
        %end;
    %else
        %do;
            %put Dataset &dsn. already exists. Please delete and try again.;
        %end;
%mend;
%loadDataIfNotAlreadyAvailable(
    &inputDataset1DSN.,
    &inputDataset1URL.,
    &inputDataset1Type.
)
%loadDataIfNotAlreadyAvailable(
    &inputDataset2DSN.,
    &inputDataset2URL.,
    &inputDataset2Type.
)
%loadDataIfNotAlreadyAvailable(
    &inputDataset3DSN.,
    &inputDataset3URL.,
    &inputDataset3Type.
)
%loadDataIfNotAlreadyAvailable(
    &inputDataset4DSN.,
    &inputDataset4URL.,
    &inputDataset4Type.
)


* sort and check raw data sets for duplicates with respect to primary keys,
  data contains no blank rows so no steps to remove blanks is needed;
proc sort
        nodupkey
        data=grad1415_raw
        out=grad1415_raw_sorted(where=(not(missing(CDS_CODE))))
    ;
    by
        CDS_CODE
    ;
run;
proc sort
        nodupkey
        data=grad1516_raw
        out=grad1516_raw_sorted(where=(not(missing(CDS_CODE))))
    ;
    by
        CDS_CODE
    ;
run;
proc sort
        nodupkey
        data=dropouts1415_raw
        out=dropouts1415_raw_sorted(where=(not(missing(CDS_CODE))))
    ;
    by
        CDS_CODE
        ETHNIC
        descending GENDER
    ;
run;
proc sort
        nodupkey
        data=dropouts1516_raw
        out=dropouts1516_raw_sorted(where=(not(missing(CDS_CODE))))
    ;
    by
        CDS_CODE
        ETHNIC
        descending GENDER
    ;
run;

*
Use PROC MEANS to generate a data set containing the total number of graduates
from each county in AY2014-2015 (TOTAL_sum), as well as the total number of
schools in each county (_FREQ_)
;
proc means
        noprint
        sum
        data = grad1415_raw_sorted
        nonobs
    ;
    var TOTAL
    ;
    by COUNTY
    ;
    output
        out=grad1415_means
        sum(TOTAL) = TOTAL_sum
    ;
run;

* Sort the data set created in the previous step by county;
proc sort data=grad1415_means out=grad1415_means_sorted;
    by COUNTY;
run;

*
Merge the data set containing graduations by school and total graduations by
county in AY2014-2015 so that each row in the new data set contains graduation
statistics for an individual school as well as the total number of graduations
in the county in which that school is located
;
data grad1415_final;
    merge
        grad1415_raw_sorted
        grad1415_means_sorted
    ;
    by COUNTY;
run;

*
Use PROC MEANS to generate a data set containing the total number of graduates
from each county in AY2015-2016 (TOTAL_sum), as well as the total number of
schools in each county (_FREQ_)
;
proc means
        noprint
        sum
        data = grad1516_raw_sorted
        nonobs
    ;
    var TOTAL
    ;
    by COUNTY
    ;
    output
        out=grad1516_means
        sum(TOTAL) = TOTAL_sum
    ;
run;

* Sort the data set created in the previous step by county;
proc sort data=grad1516_means out=grad1516_means_sorted;
    by COUNTY;
run;

*
Merge the data set containing graduations by school and total graduations by
county in AY2015-2016 so that each row in the new data set contains graduation
statistics for an individual school as well as the total number of graduations
in the county in which that school is located
;
data grad1516_final;
    merge
        grad1516_raw_sorted
        grad1516_means_sorted
    ;
    by COUNTY;
run;

*
Vertically join the two final data sets containing graduation records for use
in analysis steps
;
data grad_all;
    set
        grad1415_final
        grad1516_final
    ;
run;

*
Combine data sets for dropout and graduation data for AY2014-2015 horizontally
;
data all1415;
    merge
        dropouts1415_raw_sorted
        grad1415_final;
    by CDS_CODE;
run;

*
Combine data sets for dropout and graduation data for AY2015-2016 horizontally
;
data all1516;
    merge
        dropouts1516_raw_sorted
        grad1516_final;
    by CDS_CODE;
run;

*
Finally, combine all merged data into a single data set containing dropout and
graduation data for both years
;
data grad_drop_merged;
    set all1415 all1516;
run;

*
Sort the resulting combined data set by year, CDS code, ethnic code, and gender,
excluding any records in which the CDS code is missing
;
proc sort
        nodupkey
        data=grad_drop_merged
        out=grad_drop_merged_sorted(where=(not(missing(CDS_CODE))))
    ;
    by
        YEAR
        CDS_CODE
        ETHNIC
        descending GENDER
    ;
run;


* Begin data steps for JB analysis file;

*
The first research question asks that we find the counties in California with
the greatest increase in dropout rate from one year to the next. The second and
third questions then explore additional details about the enrollment and dropout
statistics of the five counties with the greatest increase in dropout rate.

The final data set for the first research question (JB1_final) contains a record
for each county in California, as well as the total number of students enrolled
in each county in academic years 2014-2015 and 2015-2016, and the ratio of
dropouts to enrollments in each county in each year. The change in dropout ratio
is calculated for each county by subtracting the 2014-2015 dropout rate from the
2015-2016 dropout rate. The data set is sorted based upon the change in dropout
rate.
;

*
JB1_step1

To find the counties with the greatest increase in dropout rate, we first need
to find the total numbers of enrollments and dropouts for each county in each
year.

Using the combined data set, generate a new data set in with the number of
enrollments (ETOT) and dropouts (DTOT) for each ethnic group and gender at each
school is summed up into new variables for enrollments (ETOT_sum) and dropouts
(DTOT_sum) for each county, sorted by year and by county.
;
proc means
        noprint
        sum
        data=grad_drop_merged_sorted
        nonobs
    ;
    var
        ETOT
        DTOT
    ;
    class
        YEAR
        COUNTY
    ;
    output
        out=JB1_step1
        sum(ETOT DTOT) = ETOT_sum DTOT_sum
    ;
;
run;

*
JB1_step2

The next step is to start calculating the dropout ratios for each year. We do
not need all of the fields created in the previous step, so we need to create a
new data set that contains the fields that we want to keep, and also calculate
the dropout ratios for each year for eventual calculation of the change in
dropout ratio from year to year. This step is to complete this for AY2014-2015.

From the data set generated in the previous PROC MEANS step, generate a new
data set that includes only the year, county, enrollment total, dropout total,
and calculated dropout ratio (dropout_ratio_1415) for each county, excluding
any counties in which enrollment is very low (less than 50 students total), and
only choosing data for AY2014-2015.
;
data JB1_step2;
    retain
        YEAR
        COUNTY
        ETOT_sum_1415
        DTOT_sum_1415
        dropout_ratio_1415
    ;
    keep
        YEAR
        COUNTY
        ETOT_sum_1415
        DTOT_sum_1415
        dropout_ratio_1415
    ;
    set JB1_step1(rename=(ETOT_sum=ETOT_sum_1415 DTOT_sum=DTOT_sum_1415));
        dropout_ratio_1415 = DTOT_sum_1415/ETOT_sum_1415
    ;
    if
        _TYPE_ ne 3
    then
        delete
    ;
    if
        YEAR ne 1415
    then
        delete
    ;
    if
        ETOT_sum_1415 < 50
    then
        delete
    ;
run;

*
JB1_step3

As with the previous step, we need to calculate the dropout ratio, this time for
AY2015-2016. This happens in two separate steps so that we can easily merge the
two data sets horizontally when calculating the change in dropout ratio year
over year.

From the data set generated in the previous PROC MEANS step, generate a new
data set that includes only the year, county, enrollment total, dropout total,
and calculated dropout ratio (dropout_ratio_1516) for each county, excluding
any counties in which enrollment is very low (less than 50 students total), and
only choosing data for AY2015-2016.
;
data JB1_step3;
    retain
        YEAR
        COUNTY
        ETOT_sum_1516
        DTOT_sum_1516
        dropout_ratio_1516
    ;
    keep
        YEAR
        COUNTY
        ETOT_sum_1516
        DTOT_sum_1516
        dropout_ratio_1516
    ;
    set JB1_step1(rename=(ETOT_sum=ETOT_sum_1516 DTOT_sum=DTOT_sum_1516));
        dropout_ratio_1516 = DTOT_sum_1516/ETOT_sum_1516
    ;
    if
        _TYPE_ ne 3
    then
        delete
    ;
    if
        YEAR ne 1516
    then
        delete
    ;
    if
        ETOT_sum_1516 < 50
    then
        delete
    ;
run;

*
JB1_step4

With the dropout ratios for each year calculated, we can now calculate the
change in dropout ratio from AY2014-2015 to AY2015-2016 so that we can
eventually find the counties with the highest increase in dropout ratio.

Merge the data sets created in the previous two steps to create a new data set
that includes all the data from the previous steps as well as a new calculated
value, change_in_dropout_ratio, which is the dropout ratio from AY2015-2016
(dropout_ratio_1516) minus the dropout ratio from AY2014-2015
(dropout_ratio_1415).
;
data JB1_step4;
    retain
        COUNTY
        ETOT_sum_1415
        dropout_ratio_1415
        ETOT_sum_1516
        dropout_ratio_1516
        change_in_dropout_ratio
    ;
    keep
        COUNTY
        ETOT_sum_1415
        dropout_ratio_1415
        ETOT_sum_1516
        dropout_ratio_1516
        change_in_dropout_ratio
    ;
    merge
        JB1_step2
        JB1_step3
    ;
    by
        COUNTY
    ;
    change_in_dropout_ratio = dropout_ratio_1516 - dropout_ratio_1415
    ;
run;

*
JB1_final

To find the counties with the highest increase in dropout ratio, we need to sort
the data created in previous steps by the change in dropout ratio. Because we
want to get the counties with the highest increase, we need to sort the data in
descending order.

Sort the data set generated in the previous step by descending change in dropout
ratio (change_in_dropout_ratio).
;
proc sort
        data=JB1_step4
        out=JB1_final
    ;
    by
        descending change_in_dropout_ratio
    ;
run;


*
The second research question seeks to compare the ratios of ethnic groups of
students who graduated and who dropped out in AY2015-2016 in the five counties
identified in the previous research question. The reasoning is, if there is no
achievement gap between various ethnic groups within a county, we would expect
the proportions of ethnic groups among students who graduated to roughly match
the proportions among students who dropped out. If the proportions for a given
ethnic group are much greater for students who dropped out compared to students
who graduated, then we may be seeing evidence of the achievement gap for
students within that ethnic group.

To view the data about proportions of ethnic groups among graduations and
dropouts, we need to create a data set that contains a unique record for each
county and each ethnic group within that county, as well as variables that
indicate within each county, what percentage of the graduate population belongs
to each ethnic group, and what percentage of the students who dropped out
belongs to each ethnic group.
;

*
JB2_step01

We need to calculate what percentage each ethnic group represents among the
graduating classes in each county for AY2015-2016. To start this process, we
need to isolate the records for the year and counties that interest us.

Use PROC SQL to generate a new data set containing only the graduation data for
AY2015-2016 for schools in counties with the highest change in dropout ratio.
;
proc sql;
    create table JB2_step01 as
    select *
    from grad_all
    where COUNTY
    in ('Inyo', 'Stanislaus', 'San Francisco', 'Lassen' ,'Tehama')
    and
    year=1516
    ;
quit;

*
JB2_step02

The records from the previous step include a separate line for each school.
Because we are interested in the data from each county, we need to calculate
the sums of graduates from each ethnic group for all schools within each county.
We will eventually compare this data to similar data from the data sets
pertaining to the number of dropouts, which is encoded differently from this
data set. Because of this, the output data set creates new variables marked as
"Code#" that corresponds to the ethnic codes in the data dictionary as they are
used in the dropout data sets.

Use PROC MEANS with the data set generated in the previous step to sum up the
graduation numbers at each school by ethnicity and overall for each county,
generating new columns named "Code#" corresponding to the ethnicity code as
denoted in the data dictionary, and also as included in the data sets that
pertain to student dropout rates.
;
proc means
        noprint
        sum
        data=JB2_step01
        nonobs
    ;
    var
        NOT_REPORTED    /* Code 0 */
        AM_IND          /* Code 1 */
        ASIAN           /* Code 2 */
        PAC_ISLD        /* Code 3 */
        FILIPINO        /* Code 4 */
        HISPANIC        /* Code 5 */
        AFRICAN_AM      /* Code 6 */
        WHITE           /* Code 7 */
        TWO_MORE_RACES  /* Code 9 */
        TOTAL
    ;
    class
        COUNTY
    ;
    output
        out=JB2_step02
        sum(
            NOT_REPORTED    /* Code 0 */
            AM_IND          /* Code 1 */
            ASIAN           /* Code 2 */
            PAC_ISLD        /* Code 3 */
            FILIPINO        /* Code 4 */
            HISPANIC        /* Code 5 */
            AFRICAN_AM      /* Code 6 */
            WHITE           /* Code 7 */
            TWO_MORE_RACES  /* Code 9 */
            TOTAL
        ) = Code0 Code1 Code2 Code3 Code4 Code5 Code6 Code7 Code9 TOT_sum
    ;
run;

*
JB2_step03

The previous PROC MEANS step created an aggregate record that includes the sum
of variables for all counties. We only need the sums from each county
individually, so we use PROC SQL to create a new data set that excludes the
records that are not needed.

Use PROC SQL and the _TYPE_=1 condition to extract the lines from the previously
created data set that include data specific to each county.
;
proc sql;
    create table JB2_step03 as
    select * from JB2_step02
    where _TYPE_=1
    ;
quit;

*
JB2_step04

Once again we need to prepare the graduation data to eventually merge with the
dropout data, so we transpose the previous data set so that each record contains
the county, ethnic group code, and number of graduates who belong to that group
within that county.

The resulting data set contains graduation data with columns for county and
ethnic code, along with the count of graduations for each of those combinations
stored in "COL1".
;
proc transpose data=JB2_step03 out=JB2_step04;
    by County;
run;

*
JB2_step05

Having transposed the graduation data in the previous step, we now need to
remove additional variables that are unnecessary.

Use PROC SQL to generate a new data set from the previous data set that excludes
rows that do not include an ethnic code.
;
proc sql;
    create table JB2_step05 as
    select * from JB2_step04
    where _NAME_ not in ('YEAR', '_TYPE_', '_FREQ_', 'TOT_sum')
    ;
quit;

*
JB2_step06

The final data set that we are trying to create contains a variable that
indicates what percentage of the graduating class of AY2015-2016 is comprised of
each ethnic group, so that we can compare that percentage to the percentage of
students who dropped out who belong to each ethnic group.

Use PROC FREQ to generate a new data set from the previous data set that adds
a column (PERCENT). For each county, the total number of graduations in
AY2015-2016 is calculated, and then the number of graduates of each ethnicity
within that county is divided by the total graduations in the county to generate
a percentage. The result in PERCENT is 100 times the number of graduates in a
county of a specific ethnicity (Code# in column _NAME_) divided by the total
number of graduates in that county. For example, in row 6 of the resulting data
set, COUNTY is "Inyo", _NAME_ is "Code5", and PERCENT is approximately 72.98.
According to the data dictionary, ethnic code 5 corresponds to Hispanic. This
means that in Inyo County, 72.98% of the graduates in 2016 were Hispanic.
;
proc freq data=JB2_step05 noprint;
    tables _NAME_ / out=JB2_step06;
    weight COL1;
    by COUNTY ;
run;

*
JB2_step07

Once again, we need to remove any variables that will not be used in the final
data set. Also, because we plan to merge the graduation data with the dropout
data, we need to create a new column that includes the single digit code for
each ethnic group.

Create a final data set for graduation data that drops the _NAME_ and COUNT
columns, while creating a new column for a numerical representation of ethnic
code (ETHNIC) that is created by using the substr() function to extract the
number from each "Code#" entry in the _NAME_ field. This step also renames
PERCENT to Grad_percent to be more descriptive for when we later merge it with
the data set that refers to the percentages of students who drop out.
;
data JB2_step07(drop=_NAME_ COUNT);
    set JB2_step06(rename=(Percent=Grad_percent));
    length ETHNIC 8;
    ETHNIC = substr(_NAME_,5,1);
run;

*
JB2_step08

The graduation data has been prepared, so the next step is to perform many of
the same steps on the dropout data for the counties in question.

Use PROC SQL to start to prepare a data set containing data about the number
of students who dropped out in AY2015-2016 in the counties in question.
;
proc sql;
    create table JB2_step08 as
    select
        CDS_CODE,
        ETHNIC,
        GENDER,
        DTOT,
        YEAR,
        COUNTY
    from grad_drop_merged_sorted
    where COUNTY
    in ('Inyo', 'Stanislaus', 'San Francisco', 'Lassen' ,'Tehama')
    and YEAR = 1516
    ;
quit;

*
JB2_step09

In order to work with the data set created in the previous step, it must first
be sorted.

Sort the data set generated in the previous step by county and ethnic code,
similar to the structure of the final graduation data set.
;
proc sort
        data=JB2_step08
        out=JB2_step09
    ;
    by
        COUNTY
        ETHNIC
    ;
run;

*
JB2_step10

As with the graduation data, we need to calculate the total number of dropouts
for each county and ethnic group within that county so that we can eventually
determine the percentage of the population of dropouts represented by each
ethnic group.

Use PROC MEANS to calculate the total number of dropouts per county in
AY2015-2016 (DTOT_by_county).
;
proc means
        noprint
        sum
        data=JB2_step09
        nonobs
    ;
    var
        DTOT
    ;
    class
        COUNTY
        ETHNIC
    ;
    output
        out=JB2_step10
        sum(DTOT) = DTOT_by_county
    ;
;
run;

*
JB2_step11

The previous PROC MEANS step created more combinations of sums than we need, so
we need to exclude any records that do not include sums by county by ethnic
group. We do not need every variable generated in the previous step either, so
we can choose only the variables that are needed.

Use PROC SQL to generate a new data set from the previous data set that includes
only the county, ethnic code, and total number of dropouts per county.
;
proc sql;
    create table JB2_step11 as
    select County, Ethnic, DTOT_by_county
    from JB2_step10
    where _TYPE_ = 3
    ;
quit;

*
JB2_step12

As with the graduation data set, we need to calculate what percentage of the
population of students who dropped out within each county is associated with
each ethnic group within that county.

Use PROC FREQ to generate a new data set that includes a column PERCENT that
represents the percentage of the total number of students who drop out in each
county who belong to the ethnic group represented by the associated ethnic code.
For example, in row 6 of the resulting data set, COUNTY is "Inyo", ETHNIC is 5,
and PERCENT is approximately 72.98. According to the data dictionary, ethnic
code 5 corresponds to Hispanic. This means that in Inyo County, 72.98% of the
students who dropped out in AY2015-2016 were Hispanic.
;
proc freq data=JB2_step11 noprint;
   tables ETHNIC / out=JB2_step12;
   weight DTOT_by_county;
   by COUNTY ;
run;

*
JB2_step13

We need to remove any extraneous variables and rename other variables so that
they are unique when we merge this data set with the graduation data.

Create a new data set from the previous data set that eliminates the COUNT
column and renames PERCENT to Drop_percent to be more descriptive.
;
data JB2_step13(drop=COUNT);
    set JB2_step12(rename=(Percent=Drop_percent));
run;

*
JB2_step14

Now that the graduation data and dropout data are in the same format, they can
be merged together for use in the final graph.

Create a data set that includes the proportions of graduates of each ethnicity
in the graduating class in each county, as well as the proportions of
ethnicities of students who drop out in each county.
;
data JB2_step14;
    merge JB2_step07 JB2_step13;
    by COUNTY ETHNIC;
run;

*
JB2_map

The plot created in the analysis file for this question needs to be labeled for
clarity, so we need to specify the attributes used in the final plot, including
the color to be used with each variable and the full name of each ethnicity as
indicated in the data dictionary.

Create an attribute map for use in generating a bar plot that displays a
different color for each ethnicity.
;
data JB2_map;
    retain linecolor "black";
    length id $3. value $18. fillcolor $8.;
    input id $ value $ fillcolor $;
    infile datalines delimiter='|';
    datalines;
        eth|Not Reported|cxf3ffff
        eth|Native American|cxd4e8e9
        eth|Asian|cxb6d1d5
        eth|Pacific Islander|cx98bac2
        eth|Filipino|cx7ca3b0
        eth|Hispanic|cx608d9e
        eth|African American|cx45778d
        eth|White|cx29617d
        eth|Two or More Races|cx004c6d
;
run;

*
JB2_step15

We want to add a variable containing the full name of each ethnicity for use in
the final plot and map it to the ethnic codes found in the data set created in
previous steps. This will cause the final plot to be easier to read.

Create a new data set containing the single digit ethnic code (ETHNIC) and the
text of the ethnicity it represents (Ethnic_group) for use in the bar plot to
be generated.
;
data JB2_step15;
    informat Ethnic_group $20.;
    input ETHNIC Ethnic_group $;
    infile datalines delimiter='|';
    datalines;
        0|Not Reported
        1|Native American
        2|Asian
        3|Pacific Islander
        4|Filipino
        5|Hispanic
        6|African American
        7|White
        9|Two or More Races
    ;
run;

*
JB2_final

We need to merge the previously created data set containing graduation and
dropout data with the one created in the previous step so that the new data set
contains the full title of each ethnic group so make the final plot easier to
read.

Use PROC SQL to generate the final data set to be used to generate a bar plot.
;
proc sql;
    create table JB2_final as
    select
        County,
        Ethnic_Group,
        Grad_percent,
        Drop_percent
    from JB2_step14 left join JB2_step15
    on JB2_step14.ETHNIC = JB2_step15.ETHNIC
    ;
quit;


*
The third and final research question seeks to identify at which grade level
we see the greatest number of dropouts in the counties identified in the
previous questions. The final data set contains the total number of dropouts
from each grade level in each county. To create the data set, we need to
separate the records from the counties of interest from the complete data set
created in the earlier data preparation steps, and then sum up the number of
dropouts by county and grade level.
;

*
JB3_step1

The complete data set contains variables for the number of dropouts at each
grade level (D#) and for unidentifed grade levels (DUS). We only need these
variables and the County variable for each record.

Generate a new data set using the final data set created in the data prep file
that contains only the county and number of dropouts for each grade level for
every school in AY2015-2016, keeping only the records from the counties we found
at the end of the first research question.
;
proc sql;
    create table JB3_step1 as
    select County, D7, D8, D9, D10, D11, D12, DUS
    from grad_drop_merged_sorted
    where County
    in ('Inyo', 'Stanislaus', 'San Francisco', 'Lassen' ,'Tehama')
    and year = 1516
    ;
quit;

*
JB3_step2

Again we are trying to calculate the total number of dropouts per grade level
for each county, so we need to add up the counts and group by County.

Use PROC MEANS to find the total number of students who dropped out in each
grade level by county in AY2015-2016, saving the results in new columns D#_sum
in which # represents the grade level.
;
proc means
        noprint
        sum
        data=JB3_step1
        nonobs
    ;
    var
        D7
        D8
        D9
        D10
        D11
        D12
        DUS
    ;
    class
        COUNTY
    ;
    output
        out=JB3_step2
        sum(D7 D8 D9 D10 D11 D12 DUS) =
            D7_sum
            D8_sum
            D9_sum
            D10_sum
            D11_sum
            D12_sum
            DUS_sum
    ;
;
run;

*
JB3_step3

The previous PROC MEANS step creates more records than we need, including the
sum of graduations for each level for all counties combined. We need to keep
only the records with the County names and the total of dropouts for each grade.

Use PROC SQL to extract only the county and totals of students who dropped out
from each grade level (note that DUS_sum, which contained the total number of
students from a grade other than 7-12 who dropped out, is dropped at this point
because the count for this variable for each county in question is 0)
;
proc sql;
    create table JB3_step3 as
    select County, D7_sum, D8_sum, D9_sum, D10_sum, D11_sum, D12_sum
    from JB3_step2
    where _TYPE_=1
    ;
quit;

*
JB3_final

The only values needed for the final plot refer to the County name, the grade
level, and the number of dropouts for each grade level in each county.

Create a final data set that includes the name of the each county, the grade
level, and the number of students who dropped out from that grade level in that
county (Count), for use in the final bar chart.
;
data JB3_final;
    set JB3_step3;
    keep
        County
        Grade
        Count
    ;
    retain
        County
        Grade
        Count
    ;
    Grade=7; Count=D7_sum; output;
    Grade=8; Count=D8_sum; output;
    Grade=9; Count=D9_sum; output;
    Grade=10; Count=D10_sum; output;
    Grade=11; Count=D11_sum; output;
    Grade=12; Count=D12_sum; output;
run;

* End data steps for JB analysis file;



*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;

title1
'Research Question: What are the top five counties that experienced the greatest increase in ratio of dropouts to enrollments from 2015 to 2016?'
;

title2
'Rationale: We can identify areas where dropouts have increased year over year and examine what can be done to retain students in these areas.'
;

footnote1
'Here we see the five counties with the highest increase in dropout rate from the academic years ending in 2015 to 2016.'
;

footnote2
'The dropout rate for either year is calculated by dividing the total number of students who dropped out in a county by the total enrollment for that county.'
;

footnote3
'The change in dropout rate for each county is the dropout rate for 2015-2016 minus the dropout rate for 2014-2015.'
;

*
The first research question asks that we find the counties in California with
the greatest increase in dropout rate from one year to the next. The second and
third questions then explore the

The final data set for the first research question (JB1_final) contains a record
for each county in California, as well as the total number of students enrolled
in each county in academic years 2014-2015 and 2015-2016, and the ratio of
dropouts to enrollments in each county in each year. The change in dropout ratio
is calculated for each county by subtracting the 2014-2015 dropout rate from the
2015-2016 dropout rate. The data set is sorted based upon the change in dropout
rate.

The research question asks that we find the counties in California with the
greatest increase in dropout rate from one year to the next.
;

*
Note: This compares the columns dropout_ratio_1516 and dropout_ratio_1415,
storing the difference between the two in the column change_in_dropout_ratio,
sorts by that column in descending order, and displays the top five records.

Methodology: Using the merged data set, we extract the sum of enrollments and
dropouts for each county using PROC MEANS. From there, we separate the output
into two separate data sets, one for each year, and we calculate the dropout
rate for each year, excluding any counties where total enrollment is less than
50 to remove outliers. We then merge the data sets for each year by county, and
calculate the change in dropout rate from year to year in each county. Finally,
we sort by the descending change in the dropout rate, and print the descriptive
data for the five counties with the greatest increase in dropout rate.

Limitations: In the original data sets, we merged records about graduation and
dropout rate based on CDS code. As a result, there is missing data in some
records in which a CDS code from the dropout records does not appear in the
graduation records or vice versa.

Possible Follow-up Steps: Move the data steps into the data prep file, and do
additional research to see if county names can be located for unmatched CDS
codes.
;

*
Print the descriptive data for the counties with the highest increase in dropout
ratio from AY2014-2015 to AY2015-2016
;
proc print
        noobs
        label
            data = JB1_final(obs=5)
    ;
    var
        COUNTY
        ETOT_sum_1415
        dropout_ratio_1415
        ETOT_sum_1516
        dropout_ratio_1516
        change_in_dropout_ratio
    ;
    label
        COUNTY = 'County'
        ETOT_Sum_1415='2014-2015 Enrollments'
        dropout_ratio_1415='2014-2015 Dropouts per Enrollments'
        ETOT_Sum_1516='2015-2016 Enrollments'
        dropout_ratio_1516='2015-2016 Dropouts per Enrollments'
        change_in_dropout_ratio='Change in Dropouts per Enrollments'
    ;
    format
        ETOT_sum_1415 comma9.
        dropout_ratio_1415 percent9.2
        ETOT_sum_1516 comma9.
        dropout_ratio_1516 percent9.2
        change_in_dropout_ratio percent9.2
    ;
run;

title;
footnote;


*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;

title1
'Research Question: Within the counties with a high increase in the ratio of dropouts to enrollments year over year, what are the proportions of the ethnic backgrounds of students who graduated compared to students who dropped out in the 2015-2016 academic year?'
;

title2
'Rationale: We may be able to identify evidence of the achievement gap by determining if the ratio of ethnic backgrounds of students who dropped out is significantly different from that of those who graduated.'
;

footnote1
'For each county, the top bar shows the ratio of the graduation rate for each ethnic group. The bottom bar shows the dropout rate of each ethnic group in that county.'
;

footnote2
'If the segment for a given ethnic group is much larger in the lower bar than in the upper bar, it indicates that within that county, members of that ethnic group drop out in greater proportion than they graduate, which could indicate an achievement gap between members of that group and the rest of the population in that county.'
;

footnote3
'We can see that in several of these counties, there appears to be a large discrepancy between these ratios, showing evidence of an achievement gap.'
;

footnote4
'For example, in San Francisco County, the proportions of Hispanic and African American students who drop out is significantly higher than the proportions of those who graduate.'
;

footnote5
'We can also observe a disparity in Tehama county, where the proportion of Hispanic students who drop out is much higher than the proportion of Hispanic students who graduate.'
;

*
Note: This compares the columns Grad_Percent, representing the percentages of
the graduation population in each county that belongs to each ethnic group,
and Drop_Percent, representing the same for the population of students who
dropped out.

Methodology: Create a new data set from the graduation data set which only
includes the counties from the previous step and the 2015-2016 academic year.
Then calculate the total graduation and dropout rates for each ethnicity in
these counties, and present the data in a reasonable format. In this case, the
graduation data contains a breakdown of each school's graduates by ethnicity,
with each ethnicity represented by a separate column. Because of this, when
extracting the data, we need to transpose the graduation data so that it is
listed vertically. Then, we need to merge it with data about drops by county
and create graphs that show the proportions of the graduation rate and dropout
rate for each ethnicity.

Limitations: There is some ambiguity with the differences between the count of
total graduates in each county, and the number of enrolled 12th grade students
in each county minus the number of students who dropped out. It is possible that
this is due to students who should have graduated were unable to do so, in which
case it would appear that they had enrolled, but not graduated, and not dropped
out. More investigation on this may be appropriate.

Possible Follow-up Steps: Figure out how to label the bars in the bar graph to
say "Grad" and "Drop" for each bar.
;

*
Use ODS GRAPHICS to fix the height of the display area, and then use PROC SGPLOT
to create two grouped bar charts for each county, in which the top bar shows
the proportions of ethnicities in the graduating class of 2016 in that county,
while the bottom bar shows the proportions of ethnicities of the total
population of students who have dropped out in AY2015-2016 in each county
;
ods graphics on / height=8in;
proc sgplot data=JB2_final dattrmap=JB2_map;
    hbarparm category=County response=Grad_Percent /
        group=Ethnic_group grouporder=data groupdisplay=stack
        discreteoffset=-0.17 barwidth=.3 attrid=eth;
        /* order by counts of 1st bar */
    hbarparm category=County response=Drop_Percent /
        group=Ethnic_group grouporder=data groupdisplay=stack
        discreteoffset=0.17 barwidth=.3 attrid=eth;
        /* order by counts of 2nd bar */
    yaxis discreteorder=data label="County";
    xaxis grid values=(0 to 100 by 10) label="Percentage of Total with Group";
run;

title;
footnote;


*******************************************************************************;
* Research Question Analysis Starting Point;
*******************************************************************************;

title1
'Research Question: Within counties with a high increase in the ratio of dropouts, at which grade levels do we see the greatest number of dropouts in 2015-2016?'
;

title2
'Rationale: If we can identify the point at which most students drop out, we may be able to put additional resources into student retention shortly before that point.'
;

footnote1
'Here we see that in Inyo, Stanislaus, Tehama, and Lassen Counties, most of their students who drop out will do so while they are in 12th grade.'
;

footnote2
'Additionally, we can see that Inyo and Stanislaus Counties have a much larger number of students who drop out overall than the rest of the counties shown here.'
;

footnote3
'However, in San Francisco County, it appears that a majority of drop outs occur while students are in 11th grade; additional research may be required to determine the cause of this anomaly.'
;

*
Note: This compares the sums of columns D7, D8, D9, D10, D11, and D12 from
dropouts1516 for the counties with the greatest increase in dropout rate as
determined in the first research question.

Methodology: Using the original merged data set, create a subset and sum up
the dropouts by grade level for each county, and display the total number of
dropouts per grade level in a horizontal bar chart.

Limitations: It might make more sense to display this as a ratio rather than as
a raw number, and crosstab information using the ethnicity data from the
previous step may help illuminate trends that are present. Also, the absence of
total enrollment numbers in each county deprives the chart of some context.

Possible Follow-up Steps: Determine the most effective way to communicate the
results to a non-statistician audience, and add the data and sorting steps to
the data prep file. Also look into adding total enrollment to the chart for
additional context.
;


*
Use PROC SGPLOT to create a bar chart using the previous data set in which we
see the total number of students who dropped out in AY2015-2016 for each county
and for each grade level
;
proc sgplot data=JB3_final;
    hbarparm category=County response=Count /
        group=Grade groupdisplay=cluster;
    xaxis grid offsetmin=0.1 label='2015-2016 Dropouts by County by Grade';
    x2axis offsetmax=0.95 display=(nolabel) valueattrs=(size=6);
    yaxis label='County';
run;

title;
footnote;
