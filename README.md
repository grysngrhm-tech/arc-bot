# ARC Bot — Architectural Review Console

> **A smart reference assistant that helps you find answers in Discovery West's architectural standards — with citations you can trust.**

---

## Table of Contents

- [What Is ARC Bot?](#what-is-arc-bot)
- [Why We Built This](#why-we-built-this)
- [Key Features](#key-features)
- [Try It Now](#try-it-now)
- [How It Works](#how-it-works)
- [Example Questions](#example-questions)
- [System Architecture](#system-architecture)
- [Technology Stack](#technology-stack)
- [Project Status](#project-status)
- [Documentation](#documentation)
- [Setup & Deployment](#setup--deployment)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## What Is ARC Bot?

**ARC Bot** is an evidence-based reference system designed for Discovery West's Architectural Review Committee (ARC), board members, and homeowners. It answers questions about architectural standards by searching official governing documents and providing answers **with exact citations**.

### Who Should Use This?

| Audience | How ARC Bot Helps |
|----------|-------------------|
| **ARC Committee Members** | Quickly verify requirements during reviews without flipping through 140+ pages |
| **Board Members** | Get consistent answers to policy questions with traceable sources |
| **Homeowners** | Understand what's allowed before submitting applications |
| **Developers/Maintainers** | Extend the system with new documents or features |

### What Questions Can It Answer?

- *"What is the minimum conifer tree spacing required for wildfire mitigation?"*
- *"How far must garage windows be from grade to require obscured glazing?"*
- *"What fence height is allowed within 8 feet of an alley?"*
- *"What are the quiet hours in Discovery West?"*
- *"What is the maximum building height for cottages in cluster housing?"*

Every answer includes the **document name**, **section**, and **page number** so you can verify it yourself.

---

## Why We Built This

### The Problem

Discovery West's architectural standards span multiple documents totaling hundreds of pages:

- **Architectural Design Guidelines** (143 pages, 15 exhibits)
- **CC&Rs Declaration** (57 pages of complex legal language)
- **Rules and Regulations** (community operational policies)
- **City of Bend Development Code** (Article XIX Discovery West Overlay Zone)

Finding the right answer means:
- ❌ Searching through lengthy PDFs
- ❌ Cross-referencing between documents
- ❌ Hoping you found the most current version
- ❌ Interpreting where rules apply

This takes time and introduces uncertainty — especially during live ARC meetings.

### The Solution

ARC Bot puts all governing documents at your fingertips:

- ✅ **Ask in plain English** — no need to know which document or section
- ✅ **Get cited answers** — see exactly where the rule comes from
- ✅ **Confidence indicators** — know when information is strong vs. uncertain
- ✅ **Follow-up naturally** — the system remembers your conversation context

**Result:** Faster, more consistent decisions backed by verifiable sources.

---

## Key Features

### 📚 Evidence-Based Answers
Every response cites specific sections from official documents. No guessing, no "I think it says..."

### 🔍 Smart Search
Combines **semantic understanding** (what you mean) with **keyword matching** (exact terms) to find the most relevant content — even if you don't use the exact wording from the documents.

### 📊 Confidence Indicators
Each answer shows a confidence level:
- **High** — Strong matches from authoritative sources
- **Medium** — Good relevance but may need verification
- **Low** — Limited information found; consult documents directly

### 📄 Source Transparency
Expand any citation to see the **exact text** from the source document — without opening the PDF. Each source is clearly labeled with its authority type:
- **Binding** — CC&Rs and City of Bend Code (legally enforceable)
- **ARC Guidance** — Design Guidelines (enforced by ARC)
- **DWOA Guidance** — Rules & Regulations (community policies)

### 💬 Conversation Memory
Ask follow-up questions naturally. The system remembers what you discussed within a session.

### 🌗 Light & Dark Themes
Comfortable viewing in any environment.

### 🎯 Rotating Sample Questions
Each visit presents new sample questions showcasing nuanced, specific topics across all four document types — helping users discover the depth of information available.

### 🎨 Discovery West Branding
Professional design featuring official Discovery West logos, charcoal and burnt orange color scheme, and direct links to source documents.

---

## Try It Now

### 🔗 Live Demo

**[https://grysngrhm-tech.github.io/arc-bot/](https://grysngrhm-tech.github.io/arc-bot/)**

No login required. Just type your question and press Enter.

### Screenshot

```
┌─────────────────────────────────────────────────────────────┐
│  🌲 Architectural Review Console                      [🌙]  │
│     Discovery West                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                  🌲 Welcome to ARC Bot                      │
│                                                             │
│     What is the Architectural Review Console?               │
│     ARC Bot is your intelligent assistant for               │
│     navigating Discovery West's architectural               │
│     standards and guidelines...                             │
│                                                             │
│     📄 Source Documents                                     │
│     ┌────────────────┐ ┌────────────────┐                  │
│     │ Guidelines     │ │ CC&Rs          │                  │
│     ├────────────────┤ ├────────────────┤                  │
│     │ Rules          │ │ City Code      │                  │
│     └────────────────┘ └────────────────┘                  │
│                                                             │
│     Try asking:                                             │
│     ┌────────────────┐ ┌────────────────┐                  │
│     │ Paint colors?  │ │ Max fence ht?  │                  │
│     └────────────────┘ └────────────────┘                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Ask about architectural standards...           [➤]  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## How It Works

ARC Bot follows a simple process to answer your questions:

```
   YOUR QUESTION
        │
        ▼
┌───────────────────┐
│  1. UNDERSTAND    │  Convert your question into a searchable format
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  2. SEARCH        │  Find relevant sections using AI + keyword matching
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  3. RANK          │  Score results by relevance to your specific question
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│  4. ANSWER        │  Generate a clear response with citations
└─────────┬─────────┘
          │
          ▼
   CITED RESPONSE
```

### Step-by-Step

1. **You ask a question** in plain English
2. **The system searches** all ingested documents using both meaning and keywords
3. **Results are ranked** by how well they answer your specific question
4. **An AI assistant** synthesizes the findings into a clear answer
5. **Citations are attached** so you can verify the source

**Important:** The AI only uses information it finds in the documents. It cannot make up rules or give opinions.

---

## Example Questions

Here are real questions ARC Bot can answer, organized by source document:

**Design Guidelines (ARC Guidance):**
| Question | What You'll Learn |
|----------|-------------------|
| *"What is the minimum conifer tree spacing for wildfire mitigation?"* | Specific spacing requirements for fire safety |
| *"What fence height is allowed within 8 feet of an alley?"* | Location-specific fence requirements |
| *"What roofing materials are prohibited in Discovery West?"* | Material restrictions and alternatives |

**CC&Rs (Binding):**
| Question | What You'll Learn |
|----------|-------------------|
| *"What is the minimum rental period allowed in Discovery West?"* | Rental restrictions and enforcement |
| *"When does an assessment become delinquent?"* | Payment timelines and consequences |

**Rules & Regulations (DWOA Guidance):**
| Question | What You'll Learn |
|----------|-------------------|
| *"What are the quiet hours in Discovery West?"* | Noise restrictions and timeframes |
| *"Where can visitors park overnight?"* | Parking rules and designated areas |

**City of Bend Code (Binding):**
| Question | What You'll Learn |
|----------|-------------------|
| *"What is the maximum building height for cottages in cluster housing?"* | Zoning-specific height limits |
| *"What are the setback requirements for R-1 small lots?"* | Municipal setback standards |

### Tips for Best Results

- **Be specific** — "fence height along an alley" works better than "fences"
- **Ask one thing at a time** — complex questions can be split into follow-ups
- **Use follow-ups** — "What about for corner lots?" continues the conversation

---

## System Architecture

ARC Bot connects several services to deliver accurate, cited answers:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           ARC BOT SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────┐                                                   │
│   │   YOU (User)    │                                                   │
│   │   Browser/Phone │                                                   │
│   └────────┬────────┘                                                   │
│            │ Ask question                                               │
│            ▼                                                            │
│   ┌─────────────────┐                                                   │
│   │  CHAT FRONTEND  │  Static website hosted on GitHub Pages            │
│   │  (index.html)   │  • Shows chat interface                           │
│   └────────┬────────┘  • Displays answers with citations                │
│            │                                                            │
│            ▼                                                            │
│   ┌─────────────────┐                                                   │
│   │  n8n WORKFLOWS  │  Orchestration engine (self-hosted)               │
│   │  (AI Agent)     │  • Routes questions to the right tools            │
│   └────────┬────────┘  • Manages conversation flow                      │
│            │                                                            │
│       ┌────┴────┐                                                       │
│       ▼         ▼                                                       │
│  ┌─────────┐  ┌─────────┐                                               │
│  │RETRIEVAL│  │ OpenAI  │  External AI Service                          │
│  │  TOOL   │  │   API   │  • Generates embeddings for search            │
│  └────┬────┘  └────┬────┘  • Powers the AI assistant (GPT-4o)           │
│       │            │                                                    │
│       ▼            │                                                    │
│  ┌─────────────────┴───┐                                                │
│  │      SUPABASE       │  Cloud database                                │
│  │  ┌───────────────┐  │  • Stores document chunks                      │
│  │  │   pgvector    │  │  • Vector similarity search                    │
│  │  │   database    │  │  • Full-text keyword search                    │
│  │  └───────────────┘  │                                                │
│  │  ┌───────────────┐  │                                                │
│  │  │  PDF Storage  │  │  • Original source documents                   │
│  │  └───────────────┘  │                                                │
│  └─────────────────────┘                                                │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Component Roles

| Component | What It Does | Why It Matters |
|-----------|--------------|----------------|
| **Chat Frontend** | The webpage you interact with | Simple, works on any device |
| **n8n Workflows** | Coordinates the AI agent and tools | Flexible, visual automation |
| **Supabase** | Stores documents and enables search | Fast vector + text search |
| **OpenAI API** | Provides AI understanding | High-quality embeddings and responses |

---

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | HTML, CSS, JavaScript | Static site, no server needed |
| **Hosting** | GitHub Pages | Free, reliable hosting |
| **Orchestration** | n8n (self-hosted) | AI agent workflow management |
| **Database** | Supabase (PostgreSQL + pgvector) | Document storage and vector search |
| **LLM** | OpenAI GPT-4o | Question answering and reasoning |
| **Embeddings** | text-embedding-3-large (1536 dims) | Semantic search capability |
| **Total Chunks** | 244 | Complete knowledge base |

### Why These Choices?

- **Static frontend** — No server to maintain, loads fast, works offline
- **n8n** — Visual workflow builder, easy to modify without coding
- **Supabase** — Managed PostgreSQL with vector search built-in
- **GPT-4o** — Best-in-class reasoning with tool/function support
- **1536 dimensions** — Optimal quality within Supabase index limits

---

## Project Status

### ✅ Production Ready

| Component | Details |
|-----------|---------|
| Database Schema | PostgreSQL with pgvector, hybrid search functions |
| Document Ingestion | Structure-aware chunking with section detection |
| Hybrid Retrieval | Vector similarity + full-text search |
| AI Agent | GPT-4o with tool calling, JSON response format, session memory |
| Chat Frontend | Discovery West branded UI with official logos, enhanced welcome panel |
| Rotating Question Library | 26 nuanced questions across 4 document types |
| Authority Labels | Binding, ARC Guidance, and DWOA Guidance badges |
| **Architectural Design Guidelines** | **148 chunks**, all 15 exhibits (A-O) |
| **CC&Rs Declaration** | **83 chunks** with legal covenants and enforcement |
| **Rules & Regulations** | **1 chunk** with community rules |
| **City of Bend Code** | **12 chunks** with Discovery West Overlay Zone |
| **Total Knowledge Base** | **244 chunks** across **4 governing documents** |

### 🔲 Planned

| Feature | Priority | Notes |
|---------|----------|-------|
| Dynamic Follow-up Suggestions | Medium | AI-generated contextual questions |
| Response Letter Archive | Low | Precedent search from past decisions |
| Query Analytics | Low | Track common questions and gaps |

---

## Documentation

Detailed technical documentation is available in the `docs/` folder:

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, data flow, and component overview |
| [DATA_MODEL.md](docs/DATA_MODEL.md) | Database schema, indexes, and search functions |
| [RETRIEVAL_STRATEGY.md](docs/RETRIEVAL_STRATEGY.md) | How search and ranking work |
| [CHUNKING_STRATEGY.md](docs/CHUNKING_STRATEGY.md) | Document processing and section detection |
| [AGENT_GUARDRAILS.md](docs/AGENT_GUARDRAILS.md) | AI behavior rules and system prompts |
| [ANSWER_CONTRACT.md](docs/ANSWER_CONTRACT.md) | Response format and citation requirements |
| [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md) | Build status, test results, lessons learned |
| [RISKS_AND_MITIGATIONS.md](docs/RISKS_AND_MITIGATIONS.md) | Known risks and how they're addressed |

---

## Setup & Deployment

### For Developers

#### Prerequisites

- n8n instance (self-hosted or cloud)
- Supabase project with pgvector enabled
- OpenAI API key

#### Environment Variables

Copy `env.example` to `.env` and configure:

```bash
N8N_WEBHOOK_URL=https://your-n8n-instance.com/webhook/arc-chat
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
OPENAI_API_KEY=your_openai_api_key
```

#### Database Setup

Run the SQL scripts in order:

```bash
# 1. Create tables, indexes, and functions
psql -f database/001_initial_schema.sql

# 2. Create storage bucket for PDFs
psql -f database/002_storage_bucket.sql
```

#### Deploy Frontend

The frontend is a single `index.html` file. Deploy to GitHub Pages:

```bash
git add index.html
git commit -m "Deploy frontend"
git push origin main
```

Enable GitHub Pages in repository settings (Settings → Pages → Source: main branch).

#### n8n Workflows

Import the following workflows into your n8n instance:

1. **ARC Bot - Document Ingestion** — Process and chunk PDFs
2. **ARC Bot - Hybrid Retrieval Tool** — Search the knowledge base
3. **ARC Bot - Main Agent** — Handle user conversations

Configure credentials for OpenAI and Supabase in each workflow.

---

## Contributing

We welcome contributions from the Discovery West community!

### Ways to Help

- **Report issues** — Found a wrong answer? [Open an issue](https://github.com/grysngrhm-tech/arc-bot/issues)
- **Suggest improvements** — Ideas for new features or better UX
- **Add documents** — Help ingest CC&Rs or other governing documents
- **Fix bugs** — Pull requests welcome

### Contact

For questions or support, contact the repository maintainer or open a GitHub issue.

---

## Disclaimer

> **⚠️ ARC Bot is an informational reference tool only.**

ARC Bot:
- ✅ **DOES** provide information from official Discovery West documents
- ✅ **DOES** cite sources so you can verify answers
- ✅ **DOES** help you find relevant policies faster

ARC Bot:
- ❌ **DOES NOT** issue approvals or denials
- ❌ **DOES NOT** replace official ARC review
- ❌ **DOES NOT** provide legal advice
- ❌ **DOES NOT** guarantee accuracy or completeness

**For official decisions, always contact the Discovery West Architectural Review Committee directly.**

---

## License

**Private — Discovery West HOA**

This project is developed for the Discovery West community. Source code and documentation are not licensed for external use without permission.

---

<p align="center">
  <strong>ARC Bot — Architectural Review Console</strong><br>
  <em>Evidence-based answers. Verifiable sources. Better decisions.</em><br><br>
  <a href="https://grysngrhm-tech.github.io/arc-bot/">Try the Live Demo →</a>
</p>

---

*Last Updated: January 2, 2026 — Internal Launch Ready*
