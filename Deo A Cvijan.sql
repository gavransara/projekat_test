--Ovde su zadaci iz grupe A koji se razlikuju u odnosu na ono sto je Natalija poslala
--3. Колико различитих судија је судило утакмице лиге?
select count(distinct referee_id) as no_referees
from matches
where status = 'played'
--19

--5. Колико утакмица нема пријављену посету, а колико их је одиграно без публике?
select 
    sum(case when attendance is null then 1 else 0 end) as neprijavljena_poseta,
    sum(case when attendance = 0 then 1 else 0 end) as odigrano_bez_publike
from matches
where status = 'played'

--6. Колики је просечан број картона (жути, други жути и црвени) по утакмици у свакој сезони? Пазите на утакмице без иједног картона.
with cards as(
    select m.match_id, season, count(me.event_id) as cards_per_match
    from matches m left join match_events me on m.match_id = me.match_id and event_type in ('yellow_card','second_yellow','red_card')
    group by m.match_id, season
)
select season, round(avg(cards_per_match), 2) as avg_cards
from cards
group by season
--7. Колико играча је бар једном искључено (red_card или second_yellow)?
select count(distinct player_id) as no_excluded
from match_events 
where event_type in ('second_yellow','red_card')
--81

--8. Који клуб је у сезони 2024/25 добио највише жутих картона (рачунајте и други жути)?
select me.team_id, team_name, count(me.event_type) as yellow_cards
from matches m join match_events me on me.match_id = m.match_id join teams t on t.team_id = me.team_id
where season = '2024/25' and event_type in ('yellow_card','second_yellow')
group by me.team_id, team_name
order by yellow_cards desc
limit 1