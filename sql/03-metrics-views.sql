create or replace view metrics_overview as
select
  count(*) as total_tickets,
  count(*) filter (where status = 'auto_resolved') as auto_resolved,
  count(*) filter (where status = 'escalated') as escalated,
  count(*) filter (where status = 'pending_approval') as pending_approval,
  count(*) filter (where status = 'clarification_needed') as clarification_needed,
  round(100.0 * count(*) filter (where status = 'auto_resolved') / nullif(count(*), 0), 1) as auto_resolve_pct,
  round(100.0 * count(*) filter (where status = 'escalated') / nullif(count(*), 0), 1) as escalation_pct
from tickets;

create or replace view metrics_by_intent as
select
  c.intent,
  count(*) as tickets,
  round(avg(c.urgency), 1) as avg_urgency,
  round(avg(c.frustration), 1) as avg_frustration,
  count(*) filter (where t.status = 'auto_resolved') as auto_resolved,
  count(*) filter (where t.status = 'escalated') as escalated
from classifications c
join tickets t on t.id = c.ticket_id
group by c.intent;

create or replace view metrics_decisions as
select action, rule_triggered, count(*) as total
from decisions
group by action, rule_triggered;

create or replace view metrics_confidence as
select
  d.action,
  count(*) as tickets,
  round(avg(r.confidence), 2) as avg_confidence,
  round(avg(r.groundedness), 2) as avg_groundedness
from decisions d
left join ai_responses r on r.ticket_id = d.ticket_id
group by d.action;

create or replace view metrics_tokens as
select
  step,
  count(*) as calls,
  sum(tokens_in) as tokens_in,
  sum(tokens_out) as tokens_out
from audit_log
where coalesce(tokens_in, 0) > 0 or coalesce(tokens_out, 0) > 0
group by step;
