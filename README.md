# ARC Bot

A Retrieval-Augmented Generation (RAG) chatbot for the Discovery West Architectural Review Committee.

## Status

| Component | Status |
|-----------|--------|
| Database Schema | ✅ Complete |
| Document Ingestion | ✅ Complete |
| Hybrid Retrieval | ✅ Complete |
| AI Agent | 🔲 In Progress |
| Chat Frontend | 🔲 Planned |

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

## Quick Links

| Resource | URL |
|----------|-----|
| n8n Dashboard | https://n8n.srv1208741.hstgr.cloud |
| Supabase Dashboard | https://supabase.com/dashboard/project/wdouifomlipmlsksczsv |
| Retrieval Webhook | https://n8n.srv1208741.hstgr.cloud/webhook/arc-retrieval |

## Documentation

| Document | Purpose |
|----------|---------|
| [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) | Current build status and next steps |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design and components |
| [DATA_MODEL.md](docs/DATA_MODEL.md) | Database schema |
| [RETRIEVAL_STRATEGY.md](docs/RETRIEVAL_STRATEGY.md) | Search and ranking logic |
| [CHUNKING_STRATEGY.md](docs/CHUNKING_STRATEGY.md) | Document processing |
| [AGENT_GUARDRAILS.md](docs/AGENT_GUARDRAILS.md) | AI behavior rules |
| [ANSWER_CONTRACT.md](docs/ANSWER_CONTRACT.md) | Response format |
| [RISKS_AND_MITIGATIONS.md](docs/RISKS_AND_MITIGATIONS.md) | Risk register |

## n8n Workflows

| Workflow | ID | Purpose |
|----------|-------|---------|
| Document Ingestion | `wonZrB2BxGufGsE9` | Process PDFs into knowledge base |
| Hybrid Retrieval Tool | `0MtB1JawL7bIXug9` | Search knowledge base (sub-workflow) |
| Main AI Agent | TBD | Answer user questions |

## Source Documents

Located in `Source Documents/`:

| Document | Status |
|----------|--------|
| Architectural Design Guidelines | ✅ Ingested (124 chunks, 172 sections) |
| CC&Rs Declaration | 🔲 Pending |
| Rules and Regulations | 🔲 Pending |
| ARC Application Form | 🔲 Pending |

### Chunk Metadata

Each chunk includes:
- **section_title**: Extracted from Table of Contents
- **section_hierarchy**: Full parent→child path (e.g., `["Residential Architectural Guidelines", "Fencing"]`)
- **char_start/char_end**: Character positions for precise citations

## Development

### Prerequisites

- Access to n8n instance (https://n8n.srv1208741.hstgr.cloud)
- Supabase project credentials
- OpenAI API key

### Testing Retrieval

```bash
curl -X POST https://n8n.srv1208741.hstgr.cloud/webhook/arc-retrieval \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the maximum fence height allowed?"}'
```

## License

Private - Discovery West HOA

---

Last Updated: December 31, 2025

