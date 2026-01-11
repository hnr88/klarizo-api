# /start - Backend Session Startup

Initialize a new development session for klarizo-api (Strapi backend).

## Instructions

When starting a new session:

1. **Read and acknowledge CLAUDE.md**
   - Review critical rules (DO EXACTLY WHAT IS ASKED, THINK 3X DO 1X, etc.)
   - Understand tech stack (Strapi v5, PostgreSQL, pnpm)
   - Note command restrictions

2. **Load specialized agents**
   - Check `.claude/agents/` for available agents
   - Understand each agent's purpose and triggers

3. **Review project documentation**
   - Check root `agents/` folder for shared docs
   - Check `agents.md` for quick agent reference

4. **Understand current state**
   - Review recent changes (git log)
   - Check for uncommitted work (git status)
   - Note any pending tasks

## Confirmation

After reading all documentation, confirm:

```
Backend session initialized. Ready to assist with klarizo-api development.

Loaded:
- CLAUDE.md critical rules
- Strapi v5 patterns (Document Service API)
- Project documentation

Available agents:
- Schema Architect (content-type schemas)
- API Route Engineer (custom endpoints)
- Lifecycle Guardian (hooks & policies)
- Document Service Expert (CRUD operations)
- Plugin Specialist (custom plugins)
- Migration Master (database migrations)
- Strapi Entity Manager (API entity management)
- Strapi Doctor (troubleshooting)

How can I help?
```

## Critical Reminders

- Execute ONLY what is requested
- NO hallucinations, NO unsolicited improvements
- Use Document Service API (not Entity Service)
- Use pnpm (never npm or yarn)
- Do not run dev/build/start commands
