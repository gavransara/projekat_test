-- 1. AVG OVER – poređenje sa prosekom: Za svaku utakmicu u sezoni 2024/25 prikažite broj golova koje je postigao domaći klub i prosečan broj golova tog kluba na domaćim utakmicama u istoj sezoni. Kolika je najveća razlika između broja golova na utakmici i proseka kluba?
select match_id, home_team_id, home_goals, 
        round(avg(home_goals) over(partition by home_team_id, season),2) as prosek,
        round(home_goals - avg(home_goals) over(partition by home_team_id, season),2) as diff
from matches
where season = '2024/25'
order by diff desc

-- 2. DENSE_RANK – rangiranje strelaca: Rangirajte igrače prema broju postignutih golova u sezoni 2023/24 pomoću funkcije DENSE_RANK().
select player_id, count(me.event_id) as goals,
    dense_rank() over(order by count(me.event_id) desc) as rank_goals
from match_events me join matches m on m.match_id = me.match_id
where season = '2023/24' and event_type in ('goal', 'penalty_goal')
group by player_id

--3.ROW_NUMBER – prva pobeda: Za svaki klub pronađite prvu utakmicu koju je pobedio u sezoni 2024/25. Prikažite naziv kluba, datum utakmice, protivnika i rezultat.
select t1.team_name, t2.team_name, date(kickoff_ts) as first_win_date, goals_for, goals_against,
    row_number() over(partition by tm.team_id order by kickoff_ts) as rn
from team_matches tm join teams t1 on t1.team_id = tm.team_id join teams t2 on t2.team_id = tm.opponent_id
where result = 'W' and season = '2024/25'
qualify rn = 1

--4.LAG – promena broja golova: Za svaki klub izračunajte ukupan broj postignutih golova po mesecima u sezoni 2024/25. Pomoću funkcije LAG() prikažite razliku u broju golova u odnosu na prethodni mesec. Koji klub je imao najveći mesečni rast?
with monthly_goals as(
    select team_id, month(kickoff_ts) as mesec, year(kickoff_ts) as godina,
    sum(goals_for) as total_goals_scored
    from team_matches
    where season = '2024/25'
    group by team_id, godina, mesec
    order by team_id, godina, mesec
)
select team_name, 
    mesec,
    godina,
    total_goals_scored - lag(total_goals_scored) over(partition by mg.team_id order by godina, mesec) as monthly_diff
from monthly_goals mg join teams t on mg.team_id = t.team_id  
order by monthly_diff desc

--5.Tekući zbir – prag od 30 golova: Za svaki klub izračunajte tekući zbir postignutih golova u sezoni 2024/25. Pronađite datum prve utakmice na kojoj je klub dostigao ili premašio 30 golova.
with cte as(
    select team_id, match_id, kickoff_ts,
        sum(goals_for) over(partition by team_id order by kickoff_ts, match_id
        rows between unbounded preceding and current row) as tekuci_zbir
    from team_matches
    where season = '2024/25'
    qualify tekuci_zbir >= 30
)
select team_id, min(kickoff_ts)
from cte
group by team_id


--6. SUM OVER – kumulativni broj bodova: Za svaki klub prikažite broj bodova nakon svake utakmice u sezoni 2024/25, računajući i domaće i gostujuće utakmice. Prikažite datum, protivnika, rezultat i tekući zbir bodova.
select match_id, team_id, opponent_id, kickoff_ts, result, points,
    sum(points) over(partition by team_id order by kickoff_ts, match_id
    rows between unbounded preceding and current row) as cummulative_points
from team_matches 
where season = '2024/25'

--7. RANK – rangiranje klubova po broju pobeda: Rangirajte klubove prema broju pobeda u sezoni 2024/25 pomoću funkcije RANK(). Prikažite rang, naziv kluba i broj pobeda. Obratite pažnju na razliku između RANK() i DENSE_RANK() kada više klubova ima isti rezultat.
select 
    tm.team_id,
    team_name,
    count(match_id) as no_wins,
    rank() over(order by count(match_id) desc) as rn
from team_matches tm join teams t on t.team_id = tm.team_id
where season = '2024/25' and result = 'W'
group by tm.team_id, team_name
order by rn

-- 8. LEAD – naredna utakmica: Za svaku utakmicu kluba u sezoni 2024/25 prikažite datum te utakmice, broj postignutih golova i broj golova na narednoj utakmici tog kluba. Koji klub je imao najveći rast broja golova između dve uzastopne utakmice?
select match_id, team_id, kickoff_ts, goals_for,
    lead(goals_for) over(partition by team_id order by kickoff_ts) as next_game_goals,
   lead(goals_for) over(partition by team_id order by kickoff_ts) - goals_for as diff
from team_matches
where season = '2024/25'
order by diff desc

-- 9. Okvir od tri utakmice: Za svaku utakmicu u sezoni 2024/25 izračunajte prosečan broj golova koje je klub postigao u poslednje tri utakmice, uključujući tekuću utakmicu. Prikažite samo rezultate za koje prozor sadrži sve tri utakmice. Koji klub je imao najveći takav prosek?
select team_id, kickoff_ts, goals_for,
    round(avg(goals_for) over(partition by team_id order by kickoff_ts, match_id
    rows between 2 preceding and current row), 2) as avg_3,
    row_number() over(partition by team_id order by kickoff_ts, match_id) as rn
from team_matches
where season = '2024/25'
qualify rn >= 3
order by avg_3 desc

--10. PARTITION BY – poređenje sa prethodnom sezonom: Za svaki klub prikažite ukupan broj golova u sezonama 2023/24 i 2024/25, kao i razliku između broja golova u te dve sezone. Pomoću prozorske funkcije rangirajte klubove prema promeni broja golova.
with cte as(
    select season, team_id, sum(goals_for) as sezona_golovi
    from team_matches
    where season in ('2023/24', '2024/25')
    group by season, team_id
),
cte1 as(
    select season, team_id, sezona_golovi,
        lag(sezona_golovi) over(partition by team_id order by season) as prev_season,
        sezona_golovi - lag(sezona_golovi) over(partition by team_id order by season) as diff
    from cte
)
select team_id, prev_season as golovi_2023_24, sezona_golovi as golovi_2024_25, diff,
    dense_rank() over(order by diff desc) as rn
from cte1
where season = '2024/25' and prev_season is not null
order by rn