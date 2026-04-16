-- V7: Financial Reporting Views
-- This provides the "Human Readable" layer of the ledger.

CREATE OR REPLACE VIEW vw_trial_balance AS
WITH account_sums AS (
    -- Aggregate all entries per account
    -- Using the 'entries' table as the Ground Truth
    SELECT 
        account_id,
        SUM(CASE WHEN direction = 'DEBIT' THEN amount ELSE 0 END) as total_debit,
        SUM(CASE WHEN direction = 'CREDIT' THEN amount ELSE 0 END) as total_credit
    FROM entries
    GROUP BY account_id
)
SELECT 
    a.code AS account_code,
    a.name AS account_name,
    a.category,
    s.total_debit,
    s.total_credit,
    -- Calculate net balance based on account category rules
    CASE 
        WHEN a.category IN ('ASSET', 'EXPENSE') THEN s.total_debit - s.total_credit
        ELSE s.total_credit - s.total_debit 
    END AS net_balance
FROM accounts a
JOIN account_sums s ON a.id = s.account_id
ORDER BY a.code;

-- A Quick View to verify the Entire Ledger is in balance
CREATE OR REPLACE VIEW vw_ledger_health AS
SELECT 
    SUM(total_debit) as global_debits,
    SUM(total_credit) as global_credits,
    (SUM(total_debit) - SUM(total_credit)) as discrepancy
FROM vw_trial_balance;
