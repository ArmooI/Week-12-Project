-- 1. How many agent_transactions did we have in the months of 2022 (broken down by month)? 
SELECT 
    DATE_FORMAT(agent_transactions.when_created, '%m') AS months,
    COUNT(*) AS number_of_agent_transactions
FROM
    wave.agent_transactions
GROUP BY months
ORDER BY months ASC;

-- 2. Over the course of the first half of 2022, how many Wave agents were “net depositors” vs. “net withdrawers”?  
with final_status as (
select agent_id, sum(amount),
case
	when sum(amount) > 0 then 'net depositer'
    when sum(amount) = 0 then 'Neutral'
    else 'net withdrawer'
    end as status_description
from wave.agent_transactions at
where when_created < '2022-07-01'
group by agent_id)

select status_description, count(status_description) as number_of_agents
from final_status
group by status_description;



-- 3. Build an “atx volume city summary” table: find the volume of agent transactions created in the first half of 2022, grouped by city. You can determine the city where the agent transaction took place from the agent’s city field. 
SELECT 
    a.city, SUM(at.amount) AS volume
FROM
    wave.agents a
        JOIN
    wave.agent_transactions at ON a.agent_id = at.agent_id
WHERE
    at.when_created < '2022-07-01'
GROUP BY city
ORDER BY city ASC;

-- 4. Now separate the atx volume by country as well (so your columns should be country, city, volume). 
SELECT 
    a.country, a.city, SUM(at.amount) AS volume
FROM
    wave.agents a
        JOIN
    wave.agent_transactions at ON a.agent_id = at.agent_id
WHERE
    at.when_created < '2022-07-01'
GROUP BY country , city
ORDER BY country ASC;

-- 5. Build a “send volume by country and kind” table: find the total volume of transfers (by send_amount_scalar) sent in the first half of 2022, grouped by country and transfer kind.
SELECT 
    w.ledger_location AS country,
    t.kind,
    SUM(send_amount_scalar) AS send_volume
FROM
    wave.wallets w
        JOIN
    wave.transfers t ON w.wallet_id = t.source_wallet_id
WHERE
    t.when_created < '2022-07-01'
GROUP BY country , kind
ORDER BY country; 

-- 6. Then add columns for transaction count and number of unique senders (still broken down by country and transfer kind). 
SELECT 
    w.ledger_location AS country,
    t.kind,
    SUM(send_amount_scalar) AS send_volume,
    u.name AS unique_sender,
    COUNT(*) AS transaction_count
FROM
    wave.wallets w
        JOIN
    wave.transfers t ON w.wallet_id = t.source_wallet_id
        JOIN
    wave.users u ON t.u_id = u.u_id
WHERE
    t.when_created < '2022-07-01'
GROUP BY country , kind , name
ORDER BY country;

-- 7. Finally, which wallets sent more than 1,000,000 CFA in transfers in the first quarter (as identified by the source_wallet_id column on the transfers table), and how much did they send? 
SELECT 
    u.name,
    w.wallet_id,
    t.send_amount_currency AS currency,
    t.send_amount_scalar
FROM
    wave.users u
        JOIN
    wave.wallets w ON u.wallet_id = w.wallet_id
        JOIN
    wave.transfers t ON u.u_id = t.u_id
WHERE
    t.send_amount_currency = 'CFA'
        AND t.send_amount_scalar > 1000000
        AND t.when_created <= '2022-03-31';