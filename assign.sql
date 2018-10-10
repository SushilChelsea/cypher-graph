-- Author: Sushil Pun

-- Loading club.csv file
LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
create(n:Club {name:'row.club'};

--Loading result.csv file and making relationship between home and away club
LOAD CSV WITH HEADERS FROM ("file:///result.csv") AS row
match(a:Club{name:row.home}),(b:Club{name:row.away}) Merge (a)-[r:played_with]->(b);


--Loading attributes to relation
LOAD CSV WITH HEADERS FROM ("file:///result.csv") AS row
match(a:Club{name:row.home})-[r:played_with]-(b:Club{name:row.away}) 
set r+={status:row.status,home:row.home, away:row.away,score:[row.score__001, row.score__002], time:row.time, id:row.id, link:row.link };


-------------- Queires  -----------------------

-- Display total number of matches played. ----
match(a:Club)-[r:played_with{status:'played'}]->(b:Club) return count(r) AS Total_Match_Played;

-- Display details of all matches involved “Arsenal FC” ------
match(a:Club{name:'Arsenal FC'})-[r:played_with{status:'played'}]-(b:Club) return r AS Arsenal_FC_MATCHES;

-- Display the number of matches “Liverpool FC” has lost. ---
match(a:Club{name:'Liverpool FC'})-[r:played_with]->(b:Club)
WHERE r.score[0]<r.score[1] return r as result
UNION
match(a:Club)-[r:played_with]->(b:Club{name:'Liverpool FC'})
WHERE r.score[0]>r.score[1] return r as result

---- Club name with the Home score
match(a:Club)-[r:played_with]->(b:Club)
return a.name AS Club, sum(toInteger(head(r.score))) AS Home_Score

--- Club name with the Away score
match(a:Club)<-[r:played_with]-(b:Club)
return a.name AS Club, sum(toInteger(last(r.score))) AS Away_Score

---- Display top five teams that have best scoring power. --

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WITH a,sum(toInteger(head(r.score))) AS Home_score
OPTIONAL MATCH (a)<-[r:played_with]-(b:Club)
WITH a,Home_score, sum(toInteger(last(r.score))) AS Away_score
RETURN a.name, Home_score+Away_score AS Total_Score 
ORDER BY Total_Score DESC LIMIT 5


--- Display top five teams that have poorest defending.

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WITH a,sum(toInteger(last(r.score))) AS Home_concede
OPTIONAL MATCH (a)<-[r:played_with]-(b:Club)
WITH a,Home_concede, sum(toInteger(head(r.score))) AS Away_concede
RETURN a.name, Home_concede+Away_concede AS Total_concede
ORDER BY Total_concede DESC LIMIT 5


-- Display top five teams that have best winning records.

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WHERE r.score[0]>r.score[1] 
WITH a, count(r) as result1
match(a:Club)<-[r:played_with]-(b:Club)
WHERE r.score[0]<r.score[1] 
WITH a,result1, count(r) as result2
return a.name AS CLUB, result1+result2 AS WINNING_RECORDS
ORDER BY  WINNING_RECORDS DESC LIMIT 5;


-- Display top five teams with best home winning records.

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WHERE r.score[0]>r.score[1] 
RETURN a.name, count(r) AS HOME_WINNIG_RECORDS
ORDER BY  HOME_WINNIG_RECORDS DESC LIMIT 5;

-- Display top five teams with worst home losing recording.

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WHERE r.score[0]<r.score[1] 
RETURN a.name, count(r) AS WORST_HOME_RECORD
ORDER BY  WORST_HOME_RECORD DESC LIMIT 5;

-- Which teams had most “draw”?

LOAD CSV WITH HEADERS FROM ("file:///club.csv") AS row
match(a:Club{name:row.club})-[r:played_with]->(b:Club)
WHERE r.score[0]=r.score[1] 
return a.name AS CLUB, count(r) AS DRAWS
ORDER BY  DRAWS DESC ;

-- 10) display the team with most consecutive “wins”.
MATCH (a:Club {name:'Arsenal FC'})-[r:played_with]-(:Club)
WITH ((CASE a.name WHEN r.home THEN 1 ELSE -1 END) * (TOINT(r.score[0]) - TOINT(r.score[1]))) > 0 AS win, r
ORDER BY TOINT(r.time)
RETURN REDUCE(s = {max: 0, curr: 0}, w IN COLLECT(win) |
  CASE WHEN w
    THEN {
      max: CASE WHEN s.max < s.curr + 1 THEN s.curr + 1 ELSE s.max END,
      curr: s.curr + 1}
    ELSE {max: s.max, curr: 0}
  END
  ).max AS result;



