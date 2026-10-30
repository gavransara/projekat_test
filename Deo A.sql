--1. Koliko je utakmica odigrano u oktobru 2024. godine?
select count(distinct match_id)
from matches
where month(kickoff_ts) = 10 and year(kickoff_ts) = 2024
--30

--2.Prikažite pet utakmica sa najvećim ukupnim brojem golova. Prikažite datum, nazive domaćeg i gostujućeg kluba i konačan rezultat.
select match_id, date(kickoff_ts) as date, t1.team_name as home_name, t2.team_name as away_name, home_goals, away_goals, home_goals + away_goals as total_goals
from matches m join teams t1 on t1.team_id = m.home_team_id join teams t2 on t2.team_id = m.away_team_id
order by total_goals desc, date asc
limit 6 -- jer imamo 5 utakmica sa istim brojem golova, sve su na drugom mestu

--3.Koliko različitih stadiona je korišćeno za odigravanje utakmica u sezoni 2024/25?
select count(distinct stadium_id) as num_stadium
from matches 
where season = '2024/25' and status = 'played'
--21

--4.Koliko utakmica sezone 2024/25 je odigrano po kiši ili snegu?
select count(distinct match_id) as num_games
from matches 
where season = '2024/25' and weather in ('snow', 'rain') and status = 'played'
--97

--5.Koliko odigranih utakmica ima prijavljenu posetu manju od 1.000 gledalaca? Ne računajte utakmice za koje poseta nije prijavljena.
select count(distinct match_id) as num_games
from matches
where attendance < 1000 and attendance is not null 
--1

--6.Koliki je prosečan broj postignutih golova po utakmici u svakoj sezoni? Prikažite i sezonu i prosek, zaokružen na dve decimale.
select season, round(avg(home_goals + away_goals), 2) as prosek
from matches
where status = 'played'
group by season

select season, round(sum(home_goals + away_goals) / count(match_id), 2) as prosek
from matches
where status = 'played'
group by season

--7.Koliko igrača je postiglo bar jedan gol iz penala (penalty_goal) tokom svih sezona?
select count(distinct player_id) as num_players
from match_events
where event_type = 'penalty_goal'
--140

--8.Koji klub je u sezoni 2024/25 postigao najviše golova na domaćem terenu? Prikažite naziv kluba i ukupan broj golova.
select team_name, sum(home_goals) as total_home_goals
from matches m join teams t on t.team_id = m.home_team_id
where season = '2024/25'
group by team_name
order by total_home_goals desc
limit 1

--Kingsbridge City, 52

--9.Koliko odigranih utakmica u sezoni 2024/25 ima više kartona od prosečnog broja kartona po utakmici u toj sezoni? Utakmice bez kartona računajte sa 0.
with cards_per_game as(
        select m.match_id, count(me.event_id) as no_cards
        from matches m left join match_events me on m.match_id = me.match_id and event_type in ('yellow_card','second_yellow','red_card')
        where season = '2024/25' and status = 'played'
        group by m.match_id
)
select count(*) as num_games
from cards_per_game
where no_cards > (select avg(no_cards) from cards_per_game)
--182

--10. Koji klub je osvojio najviše bodova u sezoni 2024/25? Pobeda donosi 3 boda, nerešen rezultat 1 bod, a poraz 0 bodova. Računajte i domaće i gostujuće utakmice.
with points_matches as(
        select home_team_id as team_id, 
                case when home_goals > away_goals then 3
                    when home_goals = away_goals then 1
                    else 0 end as points
        from matches
        where season = '2024/25'
        union all
        select away_team_id as team_id, 
                case when home_goals < away_goals then 3
                    when home_goals = away_goals then 1
                    else 0 end as points
        from matches
        where season = '2024/25'
)
select team_name, sum(points) as total_points
from points_matches pm join teams t on pm.team_id = t.team_id
group by team_name
order by total_points desc
limit 1

--11.Za svaku sezonu prikažite broj odigranih utakmica i ukupan broj postignutih golova.
select season, count(match_id) as num_played, sum(home_goals + away_goals) as total_goals
from matches
where status = 'played'
group by season

--12.Prikažite klubove koji su u sezoni 2024/25 odigrali više od 10 utakmica kao domaćini.
select home_team_id, team_name, count(match_id) as home_games
from matches m join teams t on t.team_id = m.home_team_id
where season = '2024/25' and status = 'played'
group by home_team_id, team_name
having home_games > 10

--13.Koliko je utakmica završeno bez golova (0:0) u svakoj sezoni?
select season, count(match_id) as draw_matches
from matches
where away_goals = 0 and home_goals = 0
group by season

--14.Koji sudija je sudio najveći broj utakmica u sezoni 2024/25? Prikažite ime i prezime sudije i broj utakmica.
select r.referee_id, referee_name, count(match_id) as total_matches
from matches m join referees r on r.referee_id = m.referee_id
where season = '2024/25'
group by r.referee_id, referee_name
order by total_matches desc
limit 1

--15.Prikažite klubove koji su u sezoni 2024/25 postigli više golova na gostovanjima nego na domaćem terenu.
with home_stats as(
        select home_team_id, sum(home_goals) total_home_goals
        from matches
        where season = '2024/25'
        group by home_team_id
),
away_stats as(
        select away_team_id, sum(away_goals) total_away_goals
        from matches
        where season = '2024/25'
        group by away_team_id
)
select home_team_id, team_name
from home_stats hs join away_stats aws on hs.home_team_id = aws.away_team_id join teams t on hs.home_team_id = t.team_id
where total_away_goals > total_home_goals



