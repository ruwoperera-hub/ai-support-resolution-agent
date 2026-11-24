# Workflow exports

Export these three workflows from n8n (open the workflow, then the "..." menu, then Download) and save them in this folder:

- `support-agent-main.json`     the Support Agent - Main workflow
- `error-handler.json`          the Support Agent - Error Handler workflow
- `kb-ingestion.json`           the KB Ingestion workflow

Before committing, open each file in a text editor and search for `AQ.` and `eyJ` to make sure no key was exported.
To use them elsewhere: Import from File in n8n, then re-create the credentials (Supabase API and Header Auth).
