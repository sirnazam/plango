# PLANGO

PLANGO is an AI-powered productivity workspace for individuals, teams, companies, schools, and institutions.

It brings everyday work into one controlled space: tasks, team delegation, approvals, shared inboxes, customer follow-ups, cloud files, and AI assistance. The product supports both a private **Personal** space and an **Organization Workspace** where owners can invite managers, virtual assistants, secretaries, members, and viewers with role-based access.

## Current product foundation

- Personal and Organization workspace modes
- Team roles and controlled access
- Task and project workboard
- Deliverable review and owner approvals
- Shared inbox and AI-assisted reply drafts
- Customer follow-up tracking
- PDF, document, spreadsheet, and presentation workspace foundation
- Private file storage and Supabase backend connectivity
- Responsive web interface

## Product direction

PLANGO is being built as a broader AI work platform where users can complete work without moving between many applications. Planned capabilities include full email integrations, collaborative PDF editing, documents, spreadsheets, presentations, meetings, calendar workflows, automations, and specialized AI agents.

## Technology

- React 19 and TypeScript
- Next.js-compatible Vinext runtime
- Tailwind CSS
- Supabase for data, authentication, realtime features, and protected storage
- Cloudflare-compatible deployment

## Local development

Requirements: Node.js 22.13 or later.

```bash
npm run install:ci
cp .env.example .env.local
npm run dev
```

Add the public Supabase URL and publishable key to `.env.local`. Never commit service-role or privileged keys.

## Verification

```bash
npm run build
npm run lint
```

## Ownership

Copyright © 2026 Joseph Chukwunazam Kelvin / Sirnazam Digital Solutions. All rights reserved.

This repository is the single source of truth for the PLANGO product.
