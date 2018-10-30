*******************************************************************************;
**************** 80-character banner for column width reference ***************;
* (set window width to banner width to calibrate line length to 80 characters *;
*******************************************************************************;

*
This file uses four merged data sets to address research questions regarding
graduation and dropout rates for students at schools in California during the
2014-2015 and 2015-2016 academic years.

Data set name: grad_drop_merged_sorted created in external file
STAT6250-01_w18-team-5_project2_data_preparation.sas, which is assumed to be
in the same directory as this file.

See the file referenced above for data set properties.
;

* environmental setup;

* set relative file import path to current directory;
X "cd ""%substr(%sysget(SAS_EXECFILEPATH),1,%eval(%length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILENAME))))""";


* load external file that generates analytic data set grad_drop_merged_sorted;
%include '.\STAT6250-01_w18-team-5_project2_data_preparation.sas';


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
