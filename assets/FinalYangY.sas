/* Programmed by: North Yang
   Programmed on: 11/15/21
   Programmed to: Its for final project part A
   Course: ST445
   Session:001
   Final edit: 
*/

%let counties = L:\st555\Data\BookData\BeverageCompanyCaseStudy\;
*seting librefs and fileref using only relative path;
x "CD L:\st555\Data\BookData\BeverageCompanyCaseStudy";
Libname InputDS ".";
filename RawData ".";

x "CD L:\ST445\Data";
libname InputFmt ".";


x "CD S:\documents\";
LIBNAME final ".";
filename final ".";

*Set up output;
ods _all_ close;

ods NOPROCTITLE;
options fmtsearch = (work final InputFmt) nodate nobyline;
option nodate nobyline;
option label;

proc format library = final;
  value $Enames(fuzz=0) 1 = 'Zip-Orange'
                        2 = 'Zip-Berry'
                        3 = 'Zip-Grape  '
                        4 = 'Diet Zip-Orange'
                        5 = 'Diet Zip-Berry'
                        6 = 'Diet Zip-Grape'
                        7 = 'Big Zip-Berry' 
                        8 = 'Big Zip-Grape'
                        9 = 'Diet Big Zip-Berry '
                       10 = 'Diet Big Zip-Grape'
                       11 = 'Mega Zip-Orange'
                       12 = 'Mega Zip-Berry'
                       13 = 'Diet Mega Zip-Orange'
                       14 = 'Diet Mega Zip-Berry';
  value $Onames(fuzz=0) 1 = 'Non-Soda Ades-Lemonade'
                        2 = 'Non-Soda Ades-Diet Lemonade'
                        3 = 'Non-Soda Ades-Orangeade'
                        4 = 'Non-Soda Ades-Diet Orangeade'
                        5 = 'Nutritional Water-Orange'
                        6 = 'Nutritional Water-Grape'
                        7 = 'Diet Nutritional Water-Orange'
                        8 = 'Diet Nutritional Water-Grape'
                        ; 
  value $ID(fuzz=0)
                     '  I' = '1'
                     ' II' = '2'
                     'III' = '3'
                     ' IV' = '4'
                     ;
run;

proc import out       = final.Counties
            Datatable = "counties" 
            DBMS      = ACCESS REPLACE;
    DATABASE = "&counties.2016Data.accdb";
    USEDATE  = YES;
    SCANTIME = NO;
    DBSASLABEL=NONE;
RUN;
/*I search on SASHELP to see the example of how to import Access database table to a SAS dataset
URL: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/acpcref/p0psac3j16cioen1nq2hkwrnk55y.htm#p16yyba7ezskobn1517otrrvjipe*/

data final.NonColaSouth;
  infile RawData('Non-Cola--NC,SC,GA.dat') firstobs = 7 dlm = '09'x ;
  input StateFIPS 2. CountyFIPS 3. _productName $20. Size $10. UnitSize 36-38 Date mmddyy10.  UnitsSold 7.;
run;

/*formatted list input
data NonColaSouth;
  infile RawData('Non-Cola--NC,SC,GA.dat') firstobs = 7 dlm = ' ' dsd ;
  input StateFIPS 2. CountyFIPS 3. ProductN $20. SizeVolume_P & $10. Containers_U 36-38 Date $10.  UnitsSold 7.;
run;
*/

/*list input*/
data final.EnergySouth;
  infile RawData('Energy--NC,SC,GA.txt') firstobs = 2 dlm = '09'x dsd ;
  input StateFIPS CountyFIPS _productName : $19. Size : $10. UnitSize 1. Date date10. UnitsSold &;
run;

data final.OtherSouth;
  infile RawData('Other--NC,SC,GA.csv') firstobs = 2 dlm = '2C'x dsd ;
  input StateFIPS CountyFIPS _productName : $29. Size: $9. UnitSize Date date8. UnitsSold;
run;

/*error???*/
data final.NonColaNorth;
  infile RawData('Non-Cola--DC-MD-VA.dat') firstobs = 5 dlm = '09'x dsd ;
  input  @1  StateFIPS 2. 
             CountyFIPS 3.
             Code  $25. 
         @31 Date ANYDTDTE10.
             UnitsSold: 3. ;
run;
/*find the way to transform two format date in to one type
URL: https://documentation.sas.com/doc/en/vdmmlcdc/8.1/leforinforref/n04jh1fkv5c8zan14fhqcby7jsu4.htm*/

data final.EnergyNorth(drop = Product Code_);
  infile RawData('Energy--DC-MD-VA.txt') firstobs = 2 dlm = '09'x DSD truncover;
  input StateFIPS CountyFIPS  Product $8. Code_ $ Date ANYDTDTE10. UnitsSold 4.;
  Code = input(cats(Product, Code_),$13.);
run;

/*I search on the internet to find how to combine two character columns
link: https://communities.sas.com/t5/General-SAS-Programming/concatenate-two-character-columns-into-one-column/td-p/168369
*/

data final.OtherNorth(drop = date1);
  infile RawData('Other--DC-MD-VA.csv') firstobs = 2 dlm = '2C'x DSD;
  input StateFIPS CountyFIPS Code: $13. Date1: $quote20. UnitsSold: ;
  Date = input(Date1,ANYDTDTE20.);
run;

data Sodas1(where = (length(_size) ne 1)
           drop = i);
  infile RawData('Sodas.csv') firstobs = 6 dlm = '2C'x DSD truncover;
  input  Number Flavor: $20. @;
  do i = 1 to 6;
    input _size: $quote23. @;
    output;
  end;
run;

data sodas2(drop = _size size1 size2);
  set sodas1;
  attrib Number label = "Product Number"
         Flavor label = "Flavor"
         size   label = "Product Size per container"
         unit   label = "product quantity"
         container label = "product container";
  size1     = scan(_size,1,' ');
  size2     = scan(_size,2,' ');
  container = scan(scan(_size,3,' '),1,'(');
  unit1     = compress(scan(_size,2,'('),')');
  size      = catx(" ",size1,size2);
  if find(_size,'(') = 0 then unit2 = '1';
  do i = 1 to 3;
      unit3 = compress(scan(unit1, i, ','));
      output;
  end;
run;

data sodas3(drop = unit1 unit2 unit3);
  set sodas2;
  unit = compress(catx(" ",unit2,unit3));
  if unit eq '' then delete;
run;

data final.sodas(drop = i);
  set sodas3 ;
  if (unit eq '1') and (i eq '1') then delete;
  if (unit eq '1') and (i eq '2') then delete;
run;


data AllDrinks(drop =  size1 container1 _ProductName ProductName1) ;
  attrib 
         StateFIPS          format = BEST12.  label = 'State FIPS'
         CountyFIPS         format = BEST12.  label = 'County FIPS'
         region             format = $8.      label = 'Region'
         productName        format = $50.     label = 'Beverage Name'
         type               format = $8.      label = 'Beverage Type'
         Flavor             format = $30.     label = 'Beverage Flavor'
         ProductCategory    format = $20.     label = 'Beverage Category'
         ProductSubCategory format = $30.     label = 'Beverage Sub-Category'
         size               format = $200.    label = "Container Size"
         UnitSize           format = Best12.  label = 'Beverage Quantity'
         container          length = $6.      label = 'Beverage Container'
         Date               format = Date9.   label = 'Sale Date'
         UnitsSold          format = Comma7.  label = ' Units Sold'
         _ProductName       format = $50.
         code               format = $200.
         ;        
  set final.Energynorth(in=inA)
      final.ENERGYSOUTH(in=inB)
      final.NonColaNorth(in=inC)
      final.NonColaSouth(in=inD)
      final.OtherNorth(in=inE)
      final.OtherSouth(in=inF)
      InputDS.ColaDCMDVA(in=inG)
      InputDS.ColaNCSCGA(in=inH)
      ;
  if inA = 1 then do;
    productName1 = compress(Substr(Code,3,2),'-');
    productName = put(productName1,$Enames.);
    region = 'North';
    ProductCategory = 'Energy';
    ProductSubcategory = tranwrd(propcase(scan(productName,1,'-')),'Diet ','');
    UnitSize = compress(substr(Code,length(code)-1),'-');
    if find(productName,'-') > 0 then Flavor = strip(substr(productName, index(productName, '-') + 1));
  /*trying to locate specific component of string
  url:https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lefunctionsref/p00ab6ey29t2i8n1ihel88tqtga9.htm*/
  end;

  if inB = 1 then do;
    productName = propcase(_productName);
    region = 'South';
    ProductCategory = 'Energy';
    ProductSubcategory = tranwrd(propcase(scan(productName,1,'-')),'Diet ','');
    if find(productName,'-') > 0 then Flavor = strip(substr(productName, index(productName, '-') + 1));
  end;

  if inC = 1 then do;
    productName1 = compress(Substr(Code,3,2),'-');
    productName = propcase(put(productName1,PRODNAMES.));
    region = 'North';
    ProductCategory = 'Soda: Non-Cola ';
    Flavor = strip(tranwrd(productName,'Diet ',''));
    UnitSize = compress(substr(Code,length(code)-1),'-');
  end;

  if inD = 1 then do;
    productName = propcase(_productName);
    region = 'South';
    ProductCategory = 'Soda: Non-Cola ';
    if find(productName,'Diet') > 0 then Flavor = strip(tranwrd(productName,'Diet ',''));
    else if find(productName,'Diet') = 0 then  Flavor = strip(productName);
  end;

  if inE = 1 then do;
    region = 'North';
    productName1 = compress(Substr(Code,3,2),'-');
    productName = put(productName1, Onames.);
    UnitSize = compress(substr(Code,length(code)-1),'-');
    if find(productName,'Non-Soda') > 0 then do;
      productCategory = substr(ProductName,1,13);
      Flavor = strip(tranwrd(substr(ProductName,15),'Diet ',''));
      end;
   else if find(productName,'Non-Soda') = 0 then do;
      productCategory = 'Nutritional Water';
      Flavor = strip(tranwrd(substr(ProductName,length(ProductName)-5),'-',''));
      end;
  end;

  if inF = 1 then do;
    productName = propcase(_productName);
    region = 'South';
    if find(productName,'Non-Soda') > 0 then do;
      productCategory = substr(ProductName,1,13);
      Flavor = strip(tranwrd(substr(ProductName,15),'Diet ',''));
      end;
   else if find(productName,'Non-Soda') = 0 then do;
      productCategory = 'Nutritional Water';
      Flavor = strip(tranwrd(substr(ProductName,length(ProductName)-5),'-',''));
      end;
  end;


  if inG = 1 then do;
    Region = 'North';
    productName1 = compress(Substr(Code,3,2),'-');
    productName = propcase(put(productName1,PRODNAMES.));
    Unitsize = compress(substr(Code,length(code)-1),'-');
  end;

  if (inG = 1) or (inH = 1) then do;
    if inH = 1 then Region = 'South';
    Flavor = strip(tranwrd(ProductName,'Diet ', ''));
    ProductCategory = 'Soda: Cola';
  end;

  /*extract year from data into column
  url: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lefunctionsref/p13eycdrmfb0l8n1492z3wocpt3s.htm*/
  /*North area*/

    *if (StateFIPS eq '11') and (CountyFIPS eq '1') then do;
  /*South Area*/
  temporary = cats(StateFIPS,CountyFIPS);
  if not missing(code) then do;
    size1 = compress(substr(Code,5,3),,'kd');
    container1 = substr(compress(Code,,'ak'),2);
    size = catx(" ",Size1,container1);
  end;

  size = lowcase(size);
  if find(size,'ounces') > 0 then size = tranwrd(size,'ounces','oz');
  if length(size) eq 3    then size = tranwrd(size,'l','litter');
  /*ProductName Settings*/

  if find(productName, 'Diet') > 0 then type = 'Diet';
     else type = 'Non-Diet';
  if (find(size,'oz') > 0) and (compress(size,,'kd')) < 20 then Container = 'Can';
    else Container = 'Bottle';
run;

data countynew(drop = region);
  set final.counties;
  temporary = cats(state,County);
run;

proc sort data = alldrinks out = alldrinkssort;
  by temporary;
run;
proc sort data = countynew out = countysort;
  by temporary;
run;

data finalmerge1;
  attrib StateName          format = $50.     label = 'State Name'
         StateFIPS          format = BEST12.  label = 'State FIPS'
         CountyName         format = $50.     label = 'County Name'
         CountyFIPS         format = BEST12.  label = 'County FIPS'
         region             format = $8.      label = 'Region'
         popestimate2016    format = Comma10. label = 'Estimated Population in 2016'
         popestimate2017    format = Comma10. label = 'Estimated Population in 2017'
         productName        length = $50.     label = 'Beverage Name'
         type               length = $8.      label = 'Beverage Type'
         Flavor             length = $30.     label = 'Beverage Flavor'
         ProductCategory    length = $20.     label = 'Beverage Category'
         ProductSubCategory length = $30.     label = 'Beverage Sub-Category'
         size               length = $200.    label = "Container Size"
         UnitSize           format = Best12.  label = 'Beverage Quantity'
         container          length = $6.      label = 'Beverage Container'
         Date               format = Date9.   label = 'Sale Date'
         UnitsSold          format = Comma7.  label = ' Units Sold'
         SalesPerThousand   format = 7.4      label = "Sales per 1,000"
         ; 
  merge alldrinkssort
        countysort;
  by  temporary;
  average          = mean(popestimate2016,popestimate2017);
  SalesPerThousand = UnitsSold / average * 1000;
run;
data finalmerge;
  set finalmerge1;
  drop county State temporary average code;
run;

ods pdf file = "YangFinalReport.pdf" style = sapphire dpi=300;
/*Output*/

/*Activity 2.1*/
title "Activity 2.1";
title2 "Summary of Units Sold";
title3 "12oz Size Diet Products";
footnote "Minimum and maximum Sales are within any county for any week";
proc means data = finalmerge
           nonobs sum min max;
  attrib StateFIPS     label = "StateFIPS"
         ProductName   label = "ProductName"
         size          label = "Container Size"
         UnitSize      label = "Container per Units"
         ;
  where (StateFIPS in (13,37,45)) and
        (ProductCategory eq "Soda: Cola") and
        (UnitSize eq 1);
  class StateFIPS ProductName size UnitSize;
  var UnitsSold;
  label UnitSize  = "Container per Units";
run;
title;
footnote;

/*Activity 2.3*/
proc sort data = finalmerge out = sort23;
  where (StateFIPS in (13,37,45)) and
        (ProductCategory eq "Soda: Cola") and
        (UnitSize eq 1);
  label StateFIPS = .;
  by productName;
run;

ods select table1of1.CrossTabFreqs table2of1.CrossTabFreqs ;
title "Activity 2.3";
title2 "Cross Tabulation of Single Unit Product Sales in Various States";
proc freq data = sort23 ;
  attrib size label = "Container Size";
  table productName*StateFIPS*size / format = comma13. ;
  weight UnitsSold;
run;
title;


/*Activity 3.1*/
ods exclude all;
ods output summary = final.summary31;
proc means data = finalmerge sum nonobs;
  where (stateName in ("Georgia", "North Carolina", "South Carolina")) and
        (UnitSIze eq 1) and
        (size eq '12 oz') and
        (ProductCategory eq "Soda: Non-Cola") and
        (type eq "Non-Diet") and
        (Flavor in ("Citrus Splash","Grape Fizzy","Lemon-Lime","Orange Fizzy","Professor Zesty"));
   class StateName Flavor;
   var UnitsSold;
run; 

ods exclude none;
title "Activity 3.1";
title2 "Single-Unit 12 oz Sales";
title3 "Regular, Non-Cola Soda";
proc sgplot data = final.summary31;
  hbar stateName / response = UnitsSold_Sum
                   group    = Flavor
                   groupdisplay = cluster;
  keylegend / location = inside 
              position = bottomright 
              across   = 2
              title    = ''
              opaque;
  xaxis label        = 'Total Sold'
        valuesformat = comma9.;
run;
title;

/*Activity 3.3*/
ods exclude all;
ods output summary = final.summary33;
proc means data = finalmerge  mean nonobs;
  where (stateName eq "Georgia") and
        (size eq "8 oz") and
        (ProductCategory eq "Energy") and
        (type eq "Non-Diet");
  class UnitSize productName;
  var UnitsSold;
run;

ods exclude none;
title "Activity 3.3";
title2 "Average Weekly Sales, Non Diest Energy Drinks";
title3 "For 8 oz Cans in Georgia";
proc sgplot data = final.summary33;
  vbar productName/ response = UnitsSold_Mean
                group = UnitSize
                groupdisplay = cluster
                DATASKIN = SHEEN ;             
  keylegend / location   = outside 
              position   = bottom
              opaque;
  yaxis DISPLAY =(NOLABEL)
        label   = 'Weekly Average Sales';
run; 
title;

/*Activity 3.6*/
data weekly;
  set finalmerge;
  week  = week(date);
  month = month(date);
run;

ods exclude all;
ods output summary = final.summary36(rename = (UnitsSold_Mean   = Mean
                                               UnitsSold_Median = Median));
proc means data = weekly  mean median nonobs;
  where (stateName in ("Georgia", "North Carolina", "South Carolina"))and
        (UnitSize eq 1) and
        (ProductCategory eq "Nutritional Water");
  class ProductName;
  var UnitsSold;
run;

ods exclude none;
title "Activity 3.6";
title2 "Weekly Average Sales, Nutritional Water";
title3 "Single-Unit Packages";
option nolabel;
proc sgplot data = final.summary36;
  hbar ProductName / response = Mean
                     barwidth = 0.6
                     NOSTATLABEL;
  hbar ProductName / response = Median
                     transparency = 0.5
                     NOSTATLABEL;
  keylegend / location = inside 
              position = topright 
              across   = 1
              opaque
              noborder
              title    = 'Weekly Sales'
              ;
  yaxis DISPLAY =(NOLABEL);
  xaxis label   = 'Georgia, North Carolina, South Carolina'; 
run;
title;
/*remove border for legend
url: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/n1k17f2g67cluyn1qrdzpsa61003.htm*/

/*Activity 4.1*/
title "Activity 4.1";
title2 "Weekly Sales Summaries";
title3 "Cola Products, 20 oz Bottles. Individual Units";
footnote "All States";
proc means data   = finalmerge 
           mean median q1 q3 nonobs
           maxdec = 0;
  where (UnitSize eq 1) and
        (size eq "20 oz") and
        (Container eq "Bottle") and
        (ProductCategory eq "Soda: Cola");
  class Region type flavor;
  var UnitsSold;
run;
title;
footnote;

/*Activity 4.2*/
title    "Activity 4.2";
title2   "Weekly Sales Distributions";
title3   "Cola Products, 12 Packs of 20 oz Bottles";
footnote "All States";
proc sgpanel data = weekly ;
  where (Container eq "Bottle") and
        (UnitSize eq 12) and
        (size eq "20 oz")  and
        (ProductCategory eq "Soda: Cola");
   panelby Region Type / NOVARNAME ; 
   histogram UnitsSold / scale = proportion 
                         binwidth = 320
                         ;
   rowaxis DISPLAY=(NOLABEL)
           valuesformat = percent7.
           ;
   colaxis label = "Units Sold";
run;
title;
footnote;


/*Activity 4.4*/
ods exclude all;
ods output summary = final.summary44;
proc means data = finalmerge q1 q3;
   where (ProductCategory eq "Soda: Cola") and
         (size eq "20 oz") and
         (Container eq "Bottle") and 
         (UnitSize eq 1);
   class region type date productname;
   var UnitsSold;
run;

ods exclude none;
title "Activit 4.4";
title2 "Sales Inter-Quartile Ranges";
title3 "Cola: 20 oz Bottles, Individual Units";
footnote "All States";
proc sgpanel data = final.summary44 NOAUTOLEGEND;
  panelby Region Type / NOVARNAME;
  highlow x = date low = UnitsSold_Q1 high = UnitsSold_q3 ;
  colaxis interval     = month 
          label        = 'Date'
          valuesformat = monyy8.;
  rowaxis 
          label        = 'Q1-Q3'
          ;
run;
title;
footnote;
/*learn how to use series & highlow
url: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/n1jkqnmk6y6ms9n1b2vvubyzqd4a.htm
*/

/*Activity #28*/
data data28;
  set finalmerge;
  keep productName type ProductCategory ProductSubcategory Flavor size Container;
run;

proc sort data = data28 out = sort28 nodup;
  by ProductCategory ProductSubcategory productName type container Flavor size ;
run;

title "Optional Activity";
title2 "Product Information and Categorization";
proc print data = sort28 noobs;
  var productName type ProductCategory ProductSubcategory Flavor size Container;
run;
title;

/*Activity 5.5*/
ods exclude all;
ods output summary = summary55; 
proc means data = finalmerge sum ;

   where (Flavor eq "Cola") and
         (size eq "12 oz") and
         (month(date) eq 8) and 
         (UnitSize eq 1) and
         (StateName in ("North Carolina", "South Carolina"));
    class type date statename;
    var unitsSold;
run;

proc sort data = summary55 out = sort55;
  by date type statename;
run;

proc transpose data = sort55 
               out = final.activity55
               ;
  id StateName;
  by date type statename;
  var UnitsSold_sum;
run;

ods exclude none;
option label;
title "Activity 5.5";
title2 "North and South Carolina Sales in August";
title3 "12 oz, Single-Unit, Cola Flavor";
proc sgpanel data = final.activity55;
  attrib Type label = "";
  panelby type / ROWS      = 2 NOVARNAME;
  hbar date    / response  = North_Carolina
                 barwidth  = 0.6
                 NOSTATLABEL;
  hbar date / response     = South_Carolina
              TRANSPARENCY = 0.5  
              NOSTATLABEL;
  rowaxis type         = linear
          valuesformat = mmddyy10.
          values       = ('05AUG2016'd to '26AUG2016'd by 7)
          display      = (nolabel)
          ;
  colaxis label        = "Sales"
          type         = linear
          valuesformat = comma8.;
  label North_Carolina = 'North Carolina'
        South_Carolina = 'South Carolina';

run;
title;
/*novarname
url: https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/n0wqazuv6959fnn1fask7mi68lla.htm
*/

/*Acitivity 6.2*/
data final.activity62;
  set finalmerge;
  where (size eq "12 oz") and
        (UnitSize eq 1) and
        (StateName eq "Maryland");
  Quarter = put(date,qtrr.);
run;

title "Activity 6.2";
title2 "Quarterly Sales Summaries for 12 oz Single-Unit Products";
title3 "Maryland Only";
proc report data = final.activity62;
  column Type ProductName Quarter UnitsSold,(median sum min max);
  define Type / group;
  define ProductName / group;
  define quarter    /group order = data;
  define UnitsSold / analysis '';
  define median / 'Median weekly sales';
  define sum   / 'Total Sales';
  define min  /  'Lowest Weekly Sales' ;
  define max / 'Highest Weekly Sales';
  break after productName / summarize ;
  compute quarter;
    if quarter eq '' then ProductName = '';
    if quarter eq '' then Type = '';
  endcomp;
run;
title;

/*Activity 7.1*/
data final.activity71;
  attrib number        label = "Product Number"
         Flavor        label = "Product Name"
         size          label = "Individual Container Size"
         Unit          label = "Retail Unit Size"
         Code          label = "Product Code";
  set final.sodas;
  code = catx('-','S',number,size,unit);
run;

title "Product Code Mapping for Sodas";
proc print data = final.activity71;
  var number Flavor size Unit Code;
run;
title;


/*Activirt 7.4*/
title "Activity 7.4";
title2 "Quarterly Sales Summaries for 12 oz Single-Unit Products";
title3 "Maryland Only";
proc report data = final.activity62
  style(header)= [backgroundcolor = grey
                  color           = blue];
  column Type ProductName Quarter UnitsSold,(median sum min max);
  define Type        / 'Product Type' group;
  define ProductName / group;
  define quarter     / 'Quarter' group order = data;
  define UnitsSold   / analysis '';
  define median      / 'Median weekly sales';
  define sum         / 'Total Sales';
  define min         /  'Lowest Weekly Sales' ;
  define max         / 'Highest Weekly Sales';
  break after productName / summarize;
  compute quarter;
    if quarter eq ''          then ProductName = '';
    if quarter eq ''          then Type = '';
    if put(Quarter,ID.) eq 2  then
                    call define(_row_, 'style','style = [backgroundcolor = #dce0e4]');
    if put(Quarter,ID.) eq 3  then
                    call define(_row_, 'style','style = [backgroundcolor = #c5ccd2]');
    if put(Quarter,ID.) eq 4  then
                    call define (_row_, 'style','style = [backgroundcolor = #a5afb9]');
    if quarter          eq '' then
                    call define(_row_, 'style','style = [backgroundcolor = black
                                                         color           = white]');
  endcomp;
run;
title;

/*Activirt 7.5*/
ods exclude all;
data activity75;
  set finalmerge;
  where (size eq "12 oz") and
        (UnitSize eq 1) and
        (StateName eq "Maryland") and
        (Flavor eq 'Lemonade');
  Quarter = put(date,qtrr.);
  County = substr(CountyName,1,length(CountyName) -7);
  format popestimate2016 comma8.;
run;
proc sort data = activity75 out = sort75;
  by type;
run;

proc report data = sort75 out = activity751
  style(header)= [backgroundcolor = grey
                  color           = blue];
  column County Type Quarter UnitsSold,(sum) popestimate2016,(mean) Sales;
  define County / 'County' group;
  define Type / 'Product Type' group order=internal;
        compute type;
          if type ne ' ' then hold=type;
          if type eq ' ' then type=hold;
        endcomp;
  define quarter / 'Quarter' group order = data;
  define UnitsSold / '';
  define sum /'Total Sales';
  define popestimate2016 / '' analysis noprint;
  define mean/ 'mean';
  define Sales / computed;
  compute Sales;
    Sales = round(_c4_ / popestimate2016.mean * 1000,.10);
  endcomp;
  break after County / summarize;

run;

data Mactivity75;
  set activity751;
  retain counter;
  if type eq 'Diet' then counter = type;
  else counter = '';
run;


ods exclude none;
title "Activity 7.5";
title2 "Quarterly Per-Capita Sales Summaries";
title3 "for 12 oz Single-Unit Lemonade";
title4 "Maryland Only";
footnote "Flagged Rows: Sales Less Than 7.5 per 1000 for Diet; Less Than 30 per 1000 for Non-Diet";
ods html;
proc report data = Mactivity75 out = final.activity75
     style(header)= [backgroundcolor = grey
                    color           = blue];
  column County Type Quarter UnitsSold popestimate2016,(mean) counter Sales;
  define County          / 'County' order;
  define Type            / 'Product Type' order order=internal;
  define quarter         / 'Quarter' order order = data;
  define counter         / noprint;
  define popestimate2016 / '' analysis noprint;
  define mean            / 'mean';
  define Sales           / 'Sale per thousand'  computed;
  compute Sales;
    Sales = round(_c4_ / popestimate2016.mean * 1000,.10);
    if (Sales lt 7.5) and (counter eq  'Diet') then do;
                            call define(_row_, 'style','style = [backgroundcolor = #dce0e4]');
                            call define (_col_, 'style', 'style = [color = red]');
    end;
    if (Sales lt 30) and (counter ne 'Diet') then do;
                            call define(_row_, 'style','style = [backgroundcolor = #a5afb9]');
                            call define (_col_, 'style', 'style = [color = red]');
    end;
  endcomp;
  break after county   / summarize;
  compute after County / style = [backgroundcolor = black
                                      color           = white
                                      just            = right];
    line '2016 population: ' popestimate2016.mean comma8.;
  endcomp;

  compute quarter;
    if quarter eq '' then do;    
       call define(_row_, 'style','style = [backgroundcolor = black
                                            color           = white]');
       County = '';   
    end; 
  endcomp;

run;
title;
footnote;





ods pdf close;
ods listing;

quit;
