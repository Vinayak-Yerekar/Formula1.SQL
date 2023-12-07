
/*1.Country which has produced the most F1 drivers.*/


select * 
from(select COUNT(nationality) 'No_of_driver', nationality,
DENSE_RANK() over(order by COUNT(nationality) desc) rnk
from drivers
group by nationality) x
where x.rnk =1;


/*2. Country have the most no of F1 circuits*/

select *
from(select COUNT(country) 'No_of_circuits',country,
DENSE_RANK() over(order by COUNT(country) desc) rnk
from circuits
group by country) x
where x.rnk =1;

/*3.Top five countries have produced highest no. of constructors? */

select * 
from(select COUNT(nationality) 'No_of_constructors', nationality,
DENSE_RANK() over(order by COUNT(nationality) desc) rnk
from constructors
group by nationality) x
where x.rnk <= '5';

/*4. No of races that have taken place each year*/
select COUNT(raceId) "No of races",year  
from races
group by year
order by year desc;

/*5. Youngest and oldest F1 driver?*/
SELECT  
    max(CASE WHEN rn = 1 THEN CONCAT(forename, ' ', surname) END) AS oldest_driver,
    max(CASE WHEN rn = cnt THEN CONCAT(forename, ' ', surname) END) AS youngest_driver
FROM (
       SELECT *, 
        ROW_NUMBER() OVER (ORDER BY dob) AS rn, 
        COUNT(*) OVER () AS cnt
       FROM drivers
) x
WHERE rn = 1 OR rn = cnt
    

/*6. No of races that have taken place each year and the first and the last race of each season.*/
select distinct(year),
FIRST_VALUE(name) over(partition by year order by date) as First_race,
last_VALUE(name) over(partition by year order by date 
range between unbounded preceding and unbounded following) as Last_race,
COUNT(*) over(partition by year) No_of_races
from races
order by year desc


/*7. Circuit has hosted the most no of races. 
Display the circuit name, no of races,city and country.*/

select top 1 COUNT(r.raceId) as No_of_races, c.name,c.circuitId,c.country,c.location as city from circuits c
join races r on c.circuitId = r.circuitId
group by c.circuitId,c.name,c.country,c.location
order by COUNT(r.raceId) desc;

/* 8. Display the following for 2022 season:
year, race_no, circuit name, driver name, driver race position, driver race points, flag to indicate if winner,
constructor name, constructor position, constructor points, , flag to indicate if constructor is winner,
race status of each driver, flag to indicate fastest lap for which driver, total no of pit stops by each driver*/

select r.year,r.raceId,r.round as Race_no,c.name as circuit_name,
concat(d.forename,' ',d.surname) as driver_name,ds.position as driver_race_position,
ds.points as driver_race_points,case when ds.position = 1 then 'WINNER' end as Winner_flag,
con.name as constructor_name, cs.position as constructor_position, cs.points as constructor_points,
case when cs.position = 1 then 'WINNER' end as con_winner_flag, s.status as race_status,
fst.Fastest_lap_time,PT.pit_stop
from races r
join circuits c on c.circuitId = r.circuitId
join driver_standings ds on ds.raceId = r.raceId
join drivers d on d.driverId = ds.driverId
join constructor_standings cs on r.raceId = cs.raceid
join constructors con on con.constructorid = cs.constructorid 
join results rs on rs.driverId = d.driverId and rs.driverId = ds.driverId and r.raceId = rs.raceId
and rs.constructorId = con.constructorid and rs.driverId = d.driverId
join status s on s.statusId = rs.statusId
left join( select MIN(fastestLapTime) AS Fastest_lap_time,raceId 
			from results
			GROUP BY raceId) as fst on fst.raceId = r.raceId and fst.Fastest_lap_time = rs.fastestLapTime
left join (select count(stop) as pit_stop,driverid from pit_stops
group by driverid) as pt on pt.driverid = d.driverId
where r.year = 2022 
order by r.raceId


/*9.Names of all F1 champions and the no of times they have won it.*/
select y.driver_name,count(y.rn) as No_of_championship 
from
(select x.driver_name,x.rn from
(select rs.year,CONCAT(d.forename,' ',d.surname)as driver_name,sum(r.points) as total_point ,d.driverId,
DENSE_RANK() over( partition by rs.year order by sum(r.points) desc) as rn 
from races rs
join driver_standings ds on ds.raceId = rs.raceId
join drivers d on d.driverId = ds.driverId
join results r on r.driverId = d.driverId and r.raceId = rs.raceId
group by rs.year,CONCAT(d.forename,' ',d.surname),d.driverId) x
where x.rn = 1 ) y
group by y.driver_name
order by count(y.rn) desc

/*10.Who won the most constructor championships*/
select COUNT(y.rnk) as No_const_champ,y.name
from
(select *
from
(select sum(cr.points) total_point,c.constructorid, r.year,c.name,
DENSE_RANK() over(partition by r.year order by sum(cr.points) desc) rnk
from races r
join constructor_standings cs on r.raceId = cs.raceid
join constructors c on c.constructorid = cs.constructorid
join constructor_results cr on cr.constructorId = cs.constructorid and cr.raceId = r.raceId
group by r.year,c.constructorId,c.name) x
where x.rnk = 1) y
group by y.name
order by COUNT(rnk)


/*11.Races India hosted?*/
select count(r.raceId) no_of_races,c.name as Circuit_name,c.country from races r
join circuits c on r.circuitId= c.circuitId
where c.country = 'India'
group by c.country,c.name

/*12.Identify the driver who won the championship or was a runner-up and the team they belonged to. */ 

select y.driver_name,y.year,y.Team,
case 
when y.rn = 1 then 'champion' else 'runner-up' end as Final_result
from
(select x.driver_name,x.rn,x.Team,x.year from
(select rs.year,CONCAT(d.forename,' ',d.surname)as driver_name,c.name as Team,sum(r.points) as total_point,d.driverId,
DENSE_RANK() over( partition by rs.year order by sum(r.points) desc) as rn 
from races rs
join driver_standings ds on ds.raceId = rs.raceId
join drivers d on d.driverId = ds.driverId
join results r on r.driverId = d.driverId and r.raceId = rs.raceId
join constructors c on c.constructorid = r.constructorId
group by rs.year,CONCAT(d.forename,' ',d.surname),d.driverId,c.name) x
where x.rn in ('1','2') ) y
order by y.year,(case 
when y.rn = 1 then 'champion' else 'runner-up' end)

/*13.The top 10 drivers with most wins.*/


select driver_name, race_wins
	from (
		select ds.driverid, concat(d.forename,' ',d.surname) as driver_name
		, count(ds.driverid) as race_wins
		, rank() over(order by count(1) desc) as rnk
		from driver_standings ds
		join drivers d on ds.driverid=d.driverid
		where position=1
		group by ds.driverid, concat(d.forename,' ',d.surname)
		) x
	where rnk <= 10;

/*14.The top 3 constructors of all time.*/
select x.name,x.race_win from 
(select COUNT(C.constructorid) AS race_win,c.name,
dense_rank() over(order by COUNT(C.constructorid)desc) as rnk FROM constructors c
JOIN constructor_standings cs on c.constructorid = cs.constructorid
where cs.position =1
group by c.name)x
where x.rnk <= 3;


/*15.Identify the drivers who have won races with multiple teams.*/
SELECT driver_name, driverId, STRING_AGG( x.name, ', ') AS Teams
FROM (
    SELECT DISTINCT(r.driverid),CONCAT(d.forename, ' ', d.surname) AS driver_name, c.name
    FROM results r
    JOIN drivers d ON d.driverId = r.driverId
    JOIN constructors c ON r.constructorId = c.constructorid
    WHERE r.position = 1
) x
GROUP BY x.driver_name, x.driverId
HAVING COUNT(x.driverId) > 1
ORDER BY x.driverId, x.driver_name;

/*16.Drivers who have never won any race.*/
select driverId,CONCAT(forename, ' ',surname) AS driver_name,nationality from drivers
where driverId not in ( select driverId from driver_standings
where position = '1')
order by driver_name;


/*17.Are there any constructors who never scored a point? 
if so mention their name and how many races they participated in?*/

select c.name as Constructor_name , c.constructorid,
count(c.constructorid) No_of_races,
sum(cr.points) as Total_point
from constructor_results cr
join constructors c on cr.constructorId = c.constructorId
group by c.name,c.constructorid
having sum(cr.points) = 0
order by no_of_races desc, constructor_name ;


/*18.Mention the drivers who have won more than 50 races.*/

		select ds.driverid, concat(d.forename,' ',d.surname) as driver_name
		, count(ds.driverid) as race_wins
		from driver_standings ds
		join drivers d on ds.driverid=d.driverid
		where position=1
		group by ds.driverid, concat(d.forename,' ',d.surname)
		having count(ds.driverid) >50;


/*19.Identify the podium finishers of each race in 2022 season*/
select 
	ds.driverId,
	concat(d.forename,' ',d.surname) as driver_name,
	r.name as Race_name,
	ds.position,
	r.year
from driver_standings ds
join drivers d on ds.driverId = d.driverId
join races r on r.raceId = ds.raceId
where ds.position <=3 and r.year = 2022
order by r.raceid;

/*20. For 2022 season, mention the points structure for each position. 
i.e. how many points are awarded to each race finished position. */

select res.position,res.points,r.year,r.raceId
from results res
join races r on res.raceId = r.raceId
where year = 2022 and points >0

/*21.How many drivers participated in 2022 season?*/
select count(distinct(d.driverId)) as No_of_driver,res.year 
from results r
right join drivers d on r.driverId = d.driverId
JOIN races res on res.raceId = r.raceId
where res.year = 2022
group by res.year


/*22.How many races has each of the top 5 constructors won in the last 10 years.*/

select x.constructorid,coalesce(y.race_win,0) as race_win,x.name as race_win from
(select x.name,x.race_win,x.constructorid from 
(select COUNT(C.constructorid) AS race_win,c.constructorid,c.name,
dense_rank() over(order by COUNT(C.constructorid)desc) as rnk FROM constructors c
JOIN constructor_standings cs on c.constructorid = cs.constructorid
where cs.position =1
group by c.name,c.constructorid)x
where x.rnk <= 5 ) x

left join( 
select count(cs.constructorid)as race_win,cs.constructorid from constructor_standings cs
join races r on cs.raceid = r.raceId
where r.year >= DATEPART(YEAR,GETDATE())-10 and cs.position = 1
group by cs.constructorid) y 
on x.constructorid = y.constructorid


/*23.Display the winners of every sprint so far in F1*/
select d.driverId,concat(d.forename,' ',d.surname) as driver_name,r.name,
sr.position,
r.circuitId,r.year
from sprint_results sr
join drivers d on d.driverId = sr.driverId
join races r on r.raceId= sr.raceId
where sr.position = 1

/*24.Find the driver who has the most no of Did Not Qualify during the race.*/
select * from 
		(
		select count(d.driverId) 'Not_Qualify',d.driverId,
		concat(d.forename,' ',d.surname) as Driver_name,r.statusId, 
		DENSE_RANK() over(order by count(d.driverId) desc) as Rnk
		from drivers d
		right join results r on d.driverId = r.driverId
		where r.statusId = (select statusId from status
							where status = 'Did Not Qualify'
							) 
		group by d.driverId,concat(d.forename,' ',d.surname),r.statusId
		) x
where X.Rnk = 1;


/*25) During the last race of 2022 season, 
identify the drivers who did not finish the race and the reason for it.*/

select r.driverId, s.statusId, s.status,
concat(d.forename,' ',d.surname) as Driver_name
from results r
join status s on s.statusId = r.statusId
join drivers d on d.driverId = r.driverId
where s.statusId <> 1 and r.raceId = (select max(raceId) from races
									  where year = 2022)



/* 26 Who won the drivers championship when India hosted F1 for the first time?*/

select d.driverId,
concat(d.forename,' ',d.surname) as Driver_name,
c.circuitId, c.name as Circuit_name,
min(r.year) as Year
from races r
join circuits c on r.circuitId = c.circuitId
join results res on res.raceId = r.raceId 
join drivers d on d.driverId = res.driverId
where c.country = 'India'
and res.position = 1
group by d.driverId,
concat(d.forename,' ',d.surname),
c.circuitId, c.name 


/*27.Driver has done the most lap time in F1 history?*/

select * 
from
(
select sum(lt.milliseconds) total_time,d.driverId,
concat(d.forename,' ',d.surname) as Driver_name,
DENSE_RANK() over(order by sum(lt.milliseconds) desc) rnk
from lap_times lt
join drivers d on d.driverId = lt.driverId
group by d.driverId,concat(d.forename,' ',d.surname)
) x
where x.rnk = 1


/*28.Top 3 drivers who have got the most podium finishes in F1 */

select * 
from
(
select count(ds.driverId) as No_podium_finishes,
concat(d.forename,' ',d.surname) as Driver_name,
DENSE_RANK() over(order by count(ds.driverId) desc) rnk
from driver_standings ds
join drivers d on ds.driverId = d.driverId
where ds.position <= 3
group by concat(d.forename,' ',d.surname)
) x
where x.rnk <=3


/*29 Which driver has the most pole position (no 1 in qualifying)*/

select * 
from
(		select q.driverId,count(q.position) as Most_qualify,
		concat(d.forename,' ',d.surname) as Driver_name,
		DENSE_RANK() over (order by count(q.position) desc) rnk
		from qualifying q
		join drivers d on q.driverId = d.driverId
		where q.position = 1
		group by q.driverId,concat(d.forename,' ',d.surname)
           ) x
Where x.rnk = 1 

