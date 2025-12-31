# ARC Bot — System Architecture

**Version:** 1.0  
**Last Updated:** December 31, 2025  
**Status:** Canonical Reference

---

## 1. System Purpose and Scope

### 1.1 Purpose

ARC Bot is a Retrieval-Augmented Generation (RAG) chatbot that assists the **Architectural Review Committee (ARC)** for the **Discovery West** community. It provides evidence-backed guidance on architectural standards, CC&Rs, and community guidelines.

### 1.2 Core Objectives

1. **Answer questions** from homeowners, builders, and committee members about:
   - Architectural Design Guidelines
   - CC&Rs (Covenants, Conditions & Restrictions)
   - Rules and Regulations
   - (Future) ARC submittals and review response letters

2. **Provide verifiable answers** grounded in source documents with explicit citations

3. **Maintain trust** by never inventing rules, interpretations, or approvals

### 1.3 What ARC Bot Does NOT Do

- Issue official decisions or approvals
- Provide legal advice
- Override or interpret ambiguous rules beyond source text
- Answer questions outside the scope of governing documents

### 1.4 Scope Boundaries

| In Scope | Out of Scope |
|----------|--------------|
| Design guidelines interpretation | Legal disputes |
| CC&R requirements lookup | Property valuations |
| Submittal process guidance | Contractor recommendations |
| Material/color requirements | HOA fee questions |
| Setback and height rules | Neighbor disputes |

---

## 2. Architecture Overview

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERFACE                                  │
│                     (GitHub Pages - Static HTML/JS)                          │
│                                                                              │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  Chat Input  │  Message History  │  Source Citations Panel          │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS POST
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         n8n ORCHESTRATION LAYER                              │
│                   (Self-hosted: n8n.srv1208741.hstgr.cloud)                  │
│                                                                              │
│   ┌───────────┐    ┌───────────────┐    ┌──────────────────────────────┐   │
│   │  Webhook  │───▶│   AI Agent    │───▶│  Answer Synthesis & Format   │   │
│   │  Trigger  │    │ (Tools Agent) │    │                              │   │
│   └───────────┘    └───────┬───────┘    └──────────────────────────────┘   │
│                            │                                                 │
│                    Tool Calls                                                │
│                            │                                                 │
│   ┌────────────────────────┼────────────────────────┐                       │
│   │                        │                        │                       │
│   ▼                        ▼                        ▼                       │
│ ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐             │
│ │   Hybrid     │   │   Reranker   │   │   Context Assembly   │             │
│ │  Retrieval   │   │    Tool      │   │       Tool           │             │
│ │    Tool      │   │              │   │                      │             │
│ └──────────────┘   └──────────────┘   └──────────────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
         │                                           │
         │ SQL Queries                               │ API Calls
         ▼                                           ▼
┌─────────────────────────────────┐    ┌─────────────────────────────────────┐
│         SUPABASE                 │    │           OPENAI API                 │
│    (New Dedicated Project)       │    │                                     │
│                                  │    │   ┌─────────────────────────────┐   │
│  ┌────────────────────────────┐ │    │   │  GPT-4o (Agent LLM)         │   │
│  │    knowledge_chunks        │ │    │   │  - Tool orchestration       │   │
│  │    ─────────────────────   │ │    │   │  - Answer synthesis         │   │
│  │    • id (uuid)             │ │    │   │  - Reranking decisions      │   │
│  │    • content (text)        │ │    │   └─────────────────────────────┘   │
│  │    • embedding (vector)    │ │    │                                     │
│  │    • metadata (jsonb)      │ │    │   ┌─────────────────────────────┐   │
│  │    • fts_vector (tsvector) │ │    │   │  text-embedding-3-large     │   │
│  └────────────────────────────┘ │    │   │  - Query embedding          │   │
│                                  │    │   │  - 1536 dimensions          │   │
│  ┌────────────────────────────┐ │    │   └─────────────────────────────┘   │
│  │    Indexes                 │ │    │                                     │
│  │    • HNSW (pgvector)       │ │    └─────────────────────────────────────┘
│  │    • GIN (full-text)       │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌────────────────────────────┐ │
│  │    Storage Bucket          │ │
│  │    • Original PDFs         │ │
│  │    • Source preservation   │ │
│  └────────────────────────────┘ │
└─────────────────────────────────┘
```

### 2.2 Request Flow Sequence

```
1. USER sends question via chat interface
          │
          ▼
2. WEBHOOK receives HTTP POST with question
          │
          ▼
3. AI AGENT (Tools Agent) analyzes question
          │
          ├──▶ Determines retrieval strategy
          │
          ▼
4. HYBRID RETRIEVAL TOOL executes
          │
          ├──▶ Embeds query via OpenAI
          ├──▶ Vector similarity search (pgvector)
          ├──▶ Keyword search (Postgres FTS)
          ├──▶ Combines and deduplicates results
          │
          ▼
5. RERANKER TOOL scores candidates
          │
          ├──▶ LLM-based relevance scoring
          ├──▶ Returns top 5-8 chunks with scores
          │
          ▼
6. AI AGENT synthesizes answer
          │
          ├──▶ Extracts relevant information
          ├──▶ Formats per answer contract
          ├──▶ Adds citations
          ├──▶ Assigns confidence level
          │
          ▼
7. RESPONSE returned to user interface
```

---

## 3. Component Responsibilities

### 3.1 Frontend (GitHub Pages)

**Technology:** Static HTML, CSS, JavaScript  
**Hosting:** GitHub Pages (grysngrhm-tech)

**Responsibilities:**
- Render chat interface
- Send user messages to n8n webhook
- Display formatted responses with citations
- Maintain conversation history (client-side)
- Link to source documents when available

**Does NOT:**
- Process or transform data
- Store conversation history server-side
- Make decisions about answer quality

### 3.2 n8n Orchestration Layer

**Technology:** n8n (self-hosted on Hostinger VPS)  
**URL:** https://n8n.srv1208741.hstgr.cloud

#### 3.2.1 Main Agent Workflow

**Purpose:** Orchestrate the RAG pipeline from question to answer

**Components:**
| Node | Type | Purpose |
|------|------|---------|
| Webhook Trigger | Trigger | Receive HTTP POST from frontend |
| AI Agent | Tools Agent | Orchestrate tools, synthesize answers |
| OpenAI Chat Model | LLM | GPT-4o for reasoning |
| Response Formatter | Code | Structure output per contract |

#### 3.2.2 Hybrid Retrieval Tool (Sub-Workflow)

**Purpose:** Execute hybrid search and return candidate chunks

**Steps:**
1. Receive query from agent
2. Generate query embedding via OpenAI
3. Execute vector similarity search
4. Execute full-text search
5. Combine results with weighted scoring
6. Return top-K candidates with metadata

#### 3.2.3 Reranker Tool (Sub-Workflow)

**Purpose:** Score and filter retrieved candidates by relevance

**Steps:**
1. Receive candidates and original query
2. Score each candidate using LLM
3. Sort by relevance score
4. Return top 5-8 chunks with scores

### 3.3 Supabase (Knowledge Store)

**Technology:** Supabase (PostgreSQL + pgvector + Storage)  
**Project:** New dedicated project for ARC Bot

**Responsibilities:**
- Store document chunks with embeddings
- Execute vector similarity search
- Execute full-text search
- Store original PDF files
- Provide audit trail via metadata

**Database Objects:**
- `knowledge_chunks` table (primary data store)
- `idx_chunks_embedding` (HNSW vector index)
- `idx_chunks_fts` (GIN full-text index)
- `arc_documents` storage bucket

### 3.4 OpenAI API

**Models Used:**

| Model | Purpose | Configuration |
|-------|---------|---------------|
| GPT-4o | Agent reasoning, answer synthesis | Temperature: 0.1 |
| GPT-4o | Reranking decisions | Temperature: 0 |
| text-embedding-3-large | Query and document embedding | 1536 dimensions |

---

## 4. Technology Stack Decisions

### 4.1 Decision Matrix

| Component | Choice | Alternatives Considered | Rationale |
|-----------|--------|------------------------|-----------|
| **Orchestration** | n8n | LangChain, custom Python | Visual workflow, existing infrastructure, tool agent support |
| **LLM** | OpenAI GPT-4o | Claude, Gemini | Strong tool use, instruction following, proven reliability |
| **Embeddings** | text-embedding-3-large | text-embedding-3-small, Cohere | Higher quality critical for governance accuracy |
| **Vector Store** | Supabase pgvector | Pinecone, Weaviate | Native PostgreSQL, existing ecosystem, cost-effective |
| **Keyword Search** | Postgres FTS | Elasticsearch | Integrated with pgvector, simpler architecture |
| **Reranking** | LLM-based (GPT-4o) | Cohere Rerank, cross-encoder | Flexibility, no additional API dependency |
| **Frontend** | GitHub Pages | Vercel, Netlify | Free, simple, existing GitHub presence |
| **PDF Storage** | Supabase Storage | S3, local | Integrated with database, simple access control |

### 4.2 Non-Negotiable Constraints

1. **n8n is the orchestration engine** — All workflow logic lives in n8n
2. **Supabase is the knowledge store** — No alternative vector databases
3. **Hybrid retrieval is required** — Vector-only search is insufficient
4. **Reranking is required** — Raw retrieval scores are not trusted
5. **Citations are required** — Every claim must reference a source

---

## 5. Security Considerations

### 5.1 Data Flow Security

| Path | Security Measure |
|------|------------------|
| Frontend → n8n | HTTPS only |
| n8n → Supabase | Service role key (server-side only) |
| n8n → OpenAI | API key (server-side only) |
| User → Frontend | No authentication (public read) |

### 5.2 Sensitive Data Handling

- **No PII storage** in chat logs
- **Source documents** are community governance documents (not confidential)
- **API keys** stored in n8n credentials, never exposed to frontend

### 5.3 Access Control

| Resource | Access Level |
|----------|--------------|
| Chat interface | Public (read-only interaction) |
| n8n workflows | Admin only |
| Supabase database | Service role only |
| PDF storage | Public read via signed URLs |

---

## 6. Scalability Considerations

### 6.1 Current Scale

- **Document corpus:** ~4 documents, ~300 pages
- **Expected queries:** <100/day initially
- **Chunk count:** ~500-1000 chunks

### 6.2 Future Scale Provisions

| Growth Vector | Accommodation |
|---------------|---------------|
| More documents | Metadata-based filtering, document_type field |
| ARC submittals | New document_type, address/lot metadata |
| Response letters | precedent flag, binding status field |
| Higher query volume | n8n queue mode, Supabase connection pooling |

### 6.3 Performance Targets

| Metric | Target |
|--------|--------|
| Query to first token | <3 seconds |
| Full response | <10 seconds |
| Retrieval latency | <500ms |
| Vector search | <100ms (HNSW) |

---

## 7. Monitoring and Observability

### 7.1 Key Metrics to Track

| Metric | Source | Purpose |
|--------|--------|---------|
| Query latency | n8n execution time | Performance |
| Retrieval hit rate | Custom logging | Quality |
| "I don't know" rate | Response parsing | Coverage |
| Error rate | n8n error workflow | Reliability |

### 7.2 Logging Strategy

- **n8n execution logs:** All workflow runs
- **Supabase query logs:** Slow query identification
- **Custom audit table:** Query, response, sources, confidence

---

## 8. Disaster Recovery

### 8.1 Backup Strategy

| Component | Backup Method | Frequency |
|-----------|---------------|-----------|
| Supabase database | Built-in PITR | Continuous |
| n8n workflows | Export to GitHub | On change |
| Source PDFs | Supabase Storage | At upload |

### 8.2 Recovery Procedures

1. **Database corruption:** Restore from Supabase PITR
2. **n8n failure:** Re-import workflows from GitHub backup
3. **Embedding model change:** Re-embed all chunks (document this process)

---

## 9. Document References

| Document | Purpose |
|----------|---------|
| [DATA_MODEL.md](DATA_MODEL.md) | Database schema specification |
| [RETRIEVAL_STRATEGY.md](RETRIEVAL_STRATEGY.md) | Search and ranking logic |
| [AGENT_GUARDRAILS.md](AGENT_GUARDRAILS.md) | AI behavior rules |
| [ANSWER_CONTRACT.md](ANSWER_CONTRACT.md) | Response format specification |
| [CHUNKING_STRATEGY.md](CHUNKING_STRATEGY.md) | Document processing rules |
| [RISKS_AND_MITIGATIONS.md](RISKS_AND_MITIGATIONS.md) | Known risks and responses |

---

## 10. Implementation Reference

### 10.1 Deployed Workflows

| Workflow | ID | Status | URL |
|----------|----|----|-----|
| Document Ingestion | `wonZrB2BxGufGsE9` | Active | Manual trigger |
| Hybrid Retrieval Tool | `0MtB1JawL7bIXug9` | Active | `/webhook/arc-retrieval` |
| Main AI Agent | TBD | Not Started | TBD |

### 10.2 Supabase Configuration

| Setting | Value |
|---------|-------|
| Project ID | `wdouifomlipmlsksczsv` |
| Vector Dimensions | 1536 (reduced from 3072 due to HNSW limit) |
| Storage Bucket | `arc-documents` |

For full implementation details, see [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1 | 2025-12-31 | AI Agent | Added implementation reference section |
| 1.0 | 2025-12-31 | AI Agent | Initial canonical architecture |

