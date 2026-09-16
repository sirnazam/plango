# PLANGO database

The live database is the restored `PLANGO` Supabase project. This web workspace extends the existing PLANGO backend rather than creating a second product.

Core product tables:

- `profiles`, `workspaces`, `workspace_members`, `workspace_invitations`
- `projects`, `tasks`, `approvals`, `activity_logs`
- `customers`, `email_connections`, `files`

The private `agent-stem-files` bucket accepts PDF, DOCX, XLSX, PPTX, PNG, and JPEG files up to 50 MB. Row-level security is enabled on every PLANGO table. Browser code must use only the publishable key; privileged keys must never be committed.

Before running locally, copy `.env.example` to `.env.local` and fill in your Supabase project URL and publishable key.
