# ARC Bot (Architectural Review Console)

An evidence-based reference system that helps users understand and navigate Discovery West's architectural standards by surfacing relevant governing documents with citations.

**ARC Bot does NOT make decisions or approvals** — it only provides information from official documents with verifiable sources.

## Live Demo

**Chat Interface:** [https://grysngrhm-tech.github.io/arc-bot/](https://grysngrhm-tech.github.io/arc-bot/)

## Features

- **Evidence-Based Answers** — Every response cites specific sections from governing documents
- **Hybrid Search** — Combines semantic understanding with keyword matching
- **Confidence Indicators** — Shows how well sources support each answer
- **Source Transparency** — View the exact document text behind citations
- **Session Memory** — Maintains conversation context for follow-up questions

## Project Status

| Component | Status |
|-----------|--------|
| Database Schema | ✅ Complete |
| Document Ingestion | ✅ Complete |
| Hybrid Retrieval | ✅ Complete |
| AI Agent | ✅ Complete |
| Chat Frontend | ✅ Complete |

## Architecture

```
┌──────────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│  Chat Frontend   │────▶│  n8n Orchestration   │────▶│    Supabase     │
│  (GitHub Pages)  │     │  (AI Agent + Tools)  │     │  (pgvector DB)  │
└──────────────────┘     └──────────────────────┘     └─────────────────┘
                                   │
                                   ▼
                         ┌──────────────────┐
                         │   OpenAI API     │
                         │  (GPT-4o, Embed) │
                         └──────────────────┘
```

## Documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and components |
| [DATA_MODEL.md](docs/DATA_MODEL.md) | Database schema |
| [RETRIEVAL_STRATEGY.md](docs/RETRIEVAL_STRATEGY.md) | Search and ranking logic |
| [CHUNKING_STRATEGY.md](docs/CHUNKING_STRATEGY.md) | Document processing |
| [AGENT_GUARDRAILS.md](docs/AGENT_GUARDRAILS.md) | AI behavior rules |
| [ANSWER_CONTRACT.md](docs/ANSWER_CONTRACT.md) | Response format |
| [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) | Build status and details |

## Knowledge Base

ARC Bot currently has access to:

| Document | Status |
|----------|--------|
| Architectural Design Guidelines | ✅ Ingested (124 chunks) |
| CC&Rs Declaration | 🔲 Pending |
| Rules and Regulations | 🔲 Pending |

## Technology Stack

- **Frontend:** Static HTML/CSS/JS (GitHub Pages)
- **Orchestration:** n8n (self-hosted)
- **Database:** Supabase (PostgreSQL + pgvector)
- **LLM:** OpenAI GPT-4o
- **Embeddings:** text-embedding-3-large (1536 dimensions)

## Setup

See [env.example](env.example) for required environment variables.

### Prerequisites

- n8n instance (self-hosted or cloud)
- Supabase project with pgvector enabled
- OpenAI API key

### Database Setup

Run the SQL scripts in `database/` in order:
1. `001_initial_schema.sql` — Tables, indexes, and functions
2. `002_storage_bucket.sql` — Storage bucket for PDFs

## Disclaimer

ARC Bot is an informational tool only. It does not:
- Issue approvals or denials
- Provide legal advice
- Replace official ARC review

For official decisions, contact the Discovery West Architectural Review Committee directly.

## License

Private — Discovery West HOA

---

*Last Updated: December 31, 2025*
