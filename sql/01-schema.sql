create extension if not exists vector;

create table customers (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text,
  tier text default 'standard',          -- standard | vip
  created_at timestamptz default now()
);

create table orders (
  id text primary key,                    -- e.g. ORD-1001
  customer_id uuid references customers(id),
  status text,                            -- processing | shipped | delivered | refunded
  total numeric(10,2),
  tracking_number text,
  placed_at timestamptz default now(),
  delivered_at timestamptz
);

create table tickets (
  id uuid primary key default gen_random_uuid(),
  external_id text unique,                -- idempotency key from the sender
  customer_id uuid references customers(id),
  channel text default 'webhook',
  raw_message text not null,
  normalized_message text,
  language text,
  status text default 'received',         -- received | auto_resolved | pending_approval | escalated | clarification_needed
  created_at timestamptz default now()
);

create table classifications (
  ticket_id uuid primary key references tickets(id) on delete cascade,
  intent text,
  sentiment text,
  urgency int check (urgency between 1 and 5),
  frustration int check (frustration between 1 and 5),
  needs_order_data boolean,
  order_id text,
  model_version text,
  created_at timestamptz default now()
);

create table kb_chunks (
  id bigserial primary key,
  document text not null,
  content text not null,
  embedding vector(768),
  version int default 1
);
create index on kb_chunks using hnsw (embedding vector_cosine_ops);

create table ai_responses (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references tickets(id) on delete cascade,
  draft text,
  citations bigint[],
  groundedness numeric(3,2),
  policy_ok boolean,
  confidence numeric(3,2),
  judge_notes text,
  created_at timestamptz default now()
);

create table decisions (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references tickets(id) on delete cascade,
  action text,                            -- auto_resolve | draft_for_approval | escalate | clarify
  rule_triggered text,
  reasons text[],
  thresholds_snapshot jsonb,
  created_at timestamptz default now()
);

create table escalations (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references tickets(id) on delete cascade,
  priority text,                          -- normal | high | critical
  summary text,
  assigned_to text,
  sla_due timestamptz,
  resolved boolean default false
);

create table audit_log (
  id bigserial primary key,
  ticket_id uuid,
  step text,
  output jsonb,
  latency_ms int,
  tokens_in int,
  tokens_out int,
  created_at timestamptz default now()
);

create table config (
  key text primary key,
  value jsonb
);
insert into config values
 ('thresholds', '{"auto_resolve":0.85,"approval":0.60,"refund_limit":100,"repeat_contacts":3}'),
 ('critical_keywords', '["lawyer","sue","legal action","chargeback","fraud","police","scam"]');

-- Vector search used by n8n
create or replace function match_kb(query_embedding vector(768), match_count int default 5, min_sim float default 0.6)
returns table (id bigint, document text, content text, similarity float)
language sql stable as $$
  select id, document, content, 1 - (embedding <=> query_embedding) as similarity
  from kb_chunks
  where 1 - (embedding <=> query_embedding) >= min_sim
  order by embedding <=> query_embedding
  limit match_count;
$$;

-- Allow the n8n service role to work with all tables
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;
