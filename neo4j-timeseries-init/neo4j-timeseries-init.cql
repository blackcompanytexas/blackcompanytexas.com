//BASED ON          		https://www.graphgrid.com/modeling-time-series-data-with-neo4j/
//which was based on  	http://www.markhneedham.com/blog/2014/04/19/neo4j-cypher-creating-a-time-tree-down-to-the-day/
//QUERY 1-6
//Create Time Tree Indexes
CREATE INDEX ON :Year(value);
CREATE INDEX ON :Month(value);
CREATE INDEX ON :Day(value);
CREATE INDEX ON :Hour(value);
CREATE INDEX ON :Minute(value);
CREATE INDEX ON :Second(value);

//QUERY 7
//Create Time Tree with Day Depth
WITH range(1970, 2016) AS years, range(1,12) AS months
FOREACH(year IN years |
  CREATE (y:Year {value: year})
  FOREACH(month IN months |
    CREATE (m:Month {value: month})
    MERGE (y)-[:CONTAINS]->(m)
    FOREACH(day IN (CASE
                      WHEN month IN [1,3,5,7,8,10,12] THEN range(1,31)
                      WHEN month = 2 THEN
                        CASE
                          WHEN year % 4 <> 0 THEN range(1,28)
                          WHEN year % 100 = 0 AND year % 400 = 0 THEN range(1,29)
                          ELSE range(1,28)
                        END
                      ELSE range(1,30)
                    END) |
      CREATE (d:Day {value: day})
      MERGE (m)-[:CONTAINS]->(d))));

//QUERY 8
//Connect Years Sequentially
MATCH (year:Year)
WITH year
ORDER BY year.value
WITH collect(year) AS years
FOREACH(i in RANGE(0, length(years)-2) |
    FOREACH(year1 in [years[i]] |
        FOREACH(year2 in [years[i+1]] |
            CREATE UNIQUE (year1)-[:NEXT]->(year2))));

//QUERY 9
//Connect Months Sequentially
MATCH (year:Year)-[:CONTAINS]->(month)
WITH year, month
ORDER BY year.value, month.value
WITH collect(month) AS months
FOREACH(i in RANGE(0, length(months)-2) |
    FOREACH(month1 in [months[i]] |
        FOREACH(month2 in [months[i+1]] |
            CREATE UNIQUE (month1)-[:NEXT]->(month2))));

//QUERY 10
//Connect Days Sequentially
MATCH (year:Year)-[:CONTAINS]->(month)-[:CONTAINS]->(day)
WITH year, month, day
ORDER BY year.value, month.value, day.value
WITH collect(day) AS days
FOREACH(i in RANGE(0, length(days)-2) |
    FOREACH(day1 in [days[i]] |
        FOREACH(day2 in [days[i+1]] |
            CREATE UNIQUE (day1)-[:NEXT]->(day2))));
