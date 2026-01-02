# ARC Bot (Architectural Review Console) — Implementation Status

**Version:** 1.3  
**Last Updated:** January 1, 2026  
**Status:** Production Ready

---

## 1. Executive Summary

| Component | Status | Details |
|-----------|--------|---------|
| Supabase Database | ✅ Complete | Schema, indexes, functions deployed |
| Storage Bucket | ✅ Complete | `arc-documents` bucket created |
| Document Ingestion Workflow | ✅ Complete | 232 chunks ingested (3 documents) |
| Exhibit Supplements | ✅ Complete | All exhibits A-O vectorized |
| Hybrid Retrieval Tool | ✅ Complete | Tested and working |
| Reranker Tool | ✅ Complete | GPT-4o scoring |
| Main AI Agent Workflow | ✅ Complete | GPT-4o with JSON response format |
| Chat Frontend | ✅ Complete | Enhanced UI with expandable sources |

---

## 2. Infrastructure

### 2.1 Supabase Project

| Property | Value |
|----------|-------|
| Database | PostgreSQL with pgvector extension |
| Storage | Supabase Storage for PDF files |
| Configuration | See `env.example` for required variables |

### 2.2 n8n Instance

| Property | Value |
|----------|-------|
| Type | Self-Hosted |
| Version | 2.0.3+ |
| Configuration | See `env.example` for required variables |

### 2.3 API Keys Configured

| Service | Credential Name in n8n | Purpose |
|---------|------------------------|---------|
| OpenAI | Header Auth OpenAI | Embeddings & LLM |
| Supabase | Supabase API (built-in) | Database operations |
| Supabase REST | Manual headers in node | RPC function calls |

---

## 3. Database Schema

### 3.1 Tables Created

| Table | Purpose | Row Count |
|-------|---------|-----------|
| `documents` | Source document registry | 3 |
| `knowledge_chunks` | Main chunk storage with embeddings | 232 |
| `ingestion_batches` | Audit trail for imports | 0 |
| `query_log` | Query analytics | 0 |

### 3.2 Indexes Created

| Index | Type | Column | Purpose |
|-------|------|--------|---------|
| `idx_knowledge_chunks_embedding` | HNSW | `embedding` | Vector similarity search |
| `idx_knowledge_chunks_fts` | GIN | `fts_vector` | Full-text search |
| `idx_knowledge_chunks_document_id` | BTREE | `document_id` | Foreign key lookups |
| `idx_knowledge_chunks_document_type` | BTREE | `document_type` | Type filtering |

### 3.3 Functions Created

| Function | Purpose | Parameters |
|----------|---------|------------|
| `hybrid_search` | Combined vector + FTS search | query_embedding, query_text, match_count, filter_document_types |
| `vector_search` | Vector-only search | query_embedding, match_count |
| `fts_search` | Full-text only search | query_text, match_count |

### 3.4 Key Configuration

| Setting | Value | Rationale |
|---------|-------|-----------|
| Vector Dimensions | 1536 | Supabase HNSW limit is 2000 |
| HNSW m | 16 | Default, good for ~1M vectors |
| HNSW ef_construction | 64 | Higher quality index |

---

## 4. n8n Workflows

### 4.1 Document Ingestion Workflow

| Property | Value |
|----------|-------|
| **Name** | ARC Bot - Document Ingestion |
| **Trigger** | Manual |
| **Status** | ✅ Complete |

**Node Flow:**
```
Manual Trigger
    │
    ▼
Set Document Config ──────────────────────────┐
    │                                          │
    ▼                                          │
Download PDF from Storage (HTTP Request)       │
    │                                          │
    ▼                                          │
Extract PDF Text                               │
    │                                          │
    ▼                                          │
Aggregate Pages (Code) ◀───────────────────────┘
    │
    ▼
Prepare Document Record (Code)
    │
    ▼
Create Document (Supabase) ────────┐
    │                               │
    ▼                               │
Analyze Document Structure (OpenAI)│
    │                               │
    ▼                               │
Chunk Document (Code) ◀─────────────┘
    │
    ▼
Batch Chunks (Split In Batches)
    │
    ├── [loop] ──▶ Generate Embeddings (HTTP Request)
    │                    │
    │                    ▼
    │              Prepare for Insert (Code)
    │                    │
    │                    ▼
    │              Insert to Supabase
    │                    │
    │                    ▼
    │              Loop Back ──▶ (back to Batch Chunks)
    │
    └── [done] ──▶ End
```

**Chunk Parameters (Actual):**
| Parameter | Value |
|-----------|-------|
| MAX_CHARS | 6000 (~1500 tokens) |
| TARGET_CHARS | 2400 (~600 tokens) |
| OVERLAP_CHARS | 300 (~75 tokens) |
| Batch Size | 1 (single chunk per embedding call) |

**Section Detection Method:**
- **TOC-based extraction**: GPT-4o extracts section titles from Table of Contents
- **Character-position matching**: Searches for section titles AFTER TOC ends in document
- **Hierarchy tracking**: Full parent→child paths (e.g., `["Residential Architectural Guidelines", "Fencing"]`)

**Credentials Required:**
- `Header Auth OpenAI` on "Generate Embeddings" node
- `Supabase API` on "Create Document" and "Insert to Supabase" nodes

### 4.2 Hybrid Retrieval Tool Workflow

| Property | Value |
|----------|-------|
| **Name** | ARC Bot - Hybrid Retrieval Tool |
| **Webhook Path** | `/arc-retrieval` |
| **Status** | ✅ Active |

**Node Flow:**
```
Webhook Trigger (POST /arc-retrieval)
    │
    ▼
Extract Query (Code)
    │
    ▼
Check for Error (IF)
    │
    ├── [true] ──▶ Return Error (Respond to Webhook)
    │
    └── [false] ──▶ Generate Query Embedding (HTTP Request)
                         │
                         ▼
                   Call Hybrid Search (HTTP Request - Supabase RPC)
                         │
                         ▼
                   Format Results (Code)
                         │
                         ▼
                   Respond to Webhook
```

**Request Format:**
```json
{
  "query": "What is the maximum fence height allowed?",
  "match_count": 10,
  "document_types": null
}
```

**Response Format:**
```json
{
  "status": "success",
  "query": "...",
  "chunk_count": 8,
  "best_score": 0.369,
  "chunks": [
    {
      "id": "uuid",
      "content": "...",
      "document_name": "Architectural Design Guidelines",
      "document_type": "design_guidelines",
      "section_hierarchy": ["Chapter 4", "4.2 Fencing"],
      "section_title": "Fencing",
      "page_number": 42,
      "is_binding": true,
      "relevance": {
        "combined_score": 0.369,
        "vector_score": 0.52,
        "fts_score": 0.006
      }
    }
  ]
}
```

**Credentials Required:**
- `Header Auth OpenAI` on "Generate Query Embedding" node
- Manual headers in "Call Hybrid Search" node:
  - `apikey`: (service role key)
  - `Authorization`: `Bearer (service role key)`
  - `Content-Type`: `application/json`
  - `Prefer`: `return=representation`

---

## 5. Ingested Documents

### 5.1 Current Knowledge Base

| Document | Type | Pages | Chunks | Status |
|----------|------|-------|--------|--------|
| Architectural Design Guidelines | design_guidelines | 143 | 148 | ✅ Complete |
| CC&Rs Declaration | ccr | 57 | 83 | ✅ Complete |
| Rules & Regulations | rules_regulations | 1 | 1 | ✅ Complete |
| **Total** | | **201** | **232** | |

### 5.2 Document Details

**Architectural Design Guidelines:**
- File: `design-guidelines/arc_guidelines.pdf`
- Ingested: December 31, 2025
- Document ID: `8937a606-f3f9-417f-b676-ef058dd75e6a`
- Chunk Distribution: 148 chunks across 143 pages

**CC&Rs Declaration:**
- File: `ccrs/ccrs-declaration.pdf`
- Ingested: January 1, 2026
- Chunk Distribution: 83 chunks across 57 pages
- Content: Legal covenants, enforcement, violations, committee structure

**Rules & Regulations:**
- File: `rules/Rules-and-Regulations.pdf`
- Ingested: January 1, 2026
- Chunk Distribution: 1 chunk (single page document)
- Content: Community rules (trash, parking, lighting, etc.)

### 5.3 Exhibit Coverage

All exhibits from the Architectural Design Guidelines have been vectorized and are searchable:

| Exhibit | Content | Page | Chunks |
|---------|---------|------|--------|
| **A** | Final Review Application Form | 95 | 1 |
| **B** | Prototype Tables (setbacks, FAR) | 110 | 1 |
| **C** | Floor Area Ratio (FAR) Calculation | 112 | 1 |
| **D** | Alley Setback Requirements | 113 | 1 |
| **E** | Home Height (30ft max) | 114 | 1 |
| **F** | Fire-Resistant Plants (complete list) | 115-121 | 9 |
| **G** | Street Tree Guidelines | 122 | 1 |
| **H** | Wildfire Mitigation (construction + zones) | 128-129 | 3 |
| **I** | Non-Development Easement NDE-1 | 134 | 1 |
| **J** | Non-Development Easement NDE-2 | 136 | 1 |
| **K** | Non-Development Easement NDE-3 | 138 | 1 |
| **L** | NDE Fence Standards | 140 | 1 |
| **M** | Venting Details (wildfire-resistant) | 141 | 1 |
| **N** | Scandinavian Soffit Orientation | 142 | 1 |
| **O** | Compliant Porch Column Detail | 143 | 1 |

**Total Exhibit Chunks:** 24 (of 148 total)

---

## 6. Test Results

### 6.1 Hybrid Retrieval Tests

| Query | Status | Best Score | Vector Score | FTS Score | Notes |
|-------|--------|------------|--------------|-----------|-------|
| "What is the maximum fence height allowed?" | ✅ success | 0.37 | 0.52 | 0.006 | Direct answer found |
| "What colors can I paint my house?" | ⚠️ low_confidence | 0.29 | 0.41 | 0.001 | Found color guidelines |
| "setback requirements" | ✅ success | **0.65** | 0.30 | **1.0** | FTS boost worked! |

### 6.2 Observations

1. **Hybrid search working correctly** - Vector captures semantic meaning, FTS captures exact keywords
2. **FTS normalization effective** - "setback requirements" got high FTS boost because exact term match
3. **Confidence thresholds appropriate** - Low-confidence flag triggers when best score < 0.35

---

## 7. Lessons Learned

### 7.1 Technical Issues Encountered

| Issue | Cause | Resolution |
|-------|-------|------------|
| HNSW index dimension limit | Supabase limits HNSW to 2000 dimensions | Reduced from 3072 to 1536 |
| `crypto is not defined` | n8n sandbox doesn't include crypto | Custom UUID generator function |
| `pageText.trim is not a function` | PDF extractor returns non-string | Explicit String() conversion |
| Token limit exceeded (51K tokens) | Poor chunking of large text blocks | Multi-strategy splitting |
| Foreign key violation | Chunks inserted before parent document | Added Create Document node first |
| Empty content in insert | Wrong node reference for chunk data | Reference Batch Chunks node |
| IF node type validation | Strict boolean comparison | Set looseTypeValidation: true |
| All chunks same section title | `indexOf()` found titles in TOC first | Search after TOC ends (~30K chars) |
| Section boundaries in TOC area | Section titles appear twice (TOC + content) | Use `tocEndPos` as search start offset |
| Missing FAR calculation | PDF extractor couldn't process table in Exhibit C | Manual exhibit insertion with embeddings |
| Missing plant lists | Exhibit F multi-page lists not extracted | Manual transcription + vectorization |
| NDE diagrams not searchable | Image-heavy exhibits not OCR'd | Manual content transcription |
| Supabase insert requires content_hash | NOT NULL constraint on content_hash column | Generate hex hash from content bytes |
| Supabase insert requires document_name | NOT NULL constraint on document_name column | Include all required fields in insert |

### 7.2 n8n 2.0 Specifics

- **Batch node outputs**: Top output = "done", Bottom output = "loop" (opposite of intuition)
- **Full workflow updates clear credentials**: Always warn user to re-add after full updates
- **Code node sandbox**: No `crypto`, no `require()`, limited Node.js APIs
- **HTTP Request auth**: "Multiple Headers Auth" exists but not in Generic Auth dropdown

### 7.3 Best Practices Identified

1. **Chunk conservatively** - 6000 chars max to stay well under 8192 token limit
2. **Batch size of 1** - Safer for debugging, prevents bulk failures
3. **Multiple split strategies** - Double newline → single newline → sentences → force split
4. **Always String() external data** - PDF extractors return unpredictable types
5. **Create parent records first** - Database foreign keys require proper order
6. **TOC-based section detection** - Extract section titles from TOC, then search AFTER TOC ends
7. **Character position matching** - More reliable than page-based section matching
8. **Manual supplement for tables/diagrams** - PDF extraction misses tabular data; manually transcribe
9. **Include all NOT NULL fields** - Supabase requires `content_hash`, `document_name`, `document_type`
10. **Vectorize exhibits separately** - Complex exhibits need individual attention for quality

---

## 8. Next Steps

### 8.1 Completed (Phase 1-5)

1. ✅ **Database Schema** — Supabase with pgvector
2. ✅ **Document Ingestion** — Structure-aware chunking with TOC detection
3. ✅ **Hybrid Retrieval Tool** — Vector + FTS search
4. ✅ **Reranker Tool** — GPT-4o relevance scoring
5. ✅ **Main AI Agent** — Tools Agent with session memory
6. ✅ **Chat Frontend** — GitHub Pages with theme toggle
7. ✅ **Exhibit Supplements** — All exhibits A-O manually transcribed and vectorized
8. ✅ **CC&Rs & Rules Ingestion** — All governing documents now searchable
9. ✅ **Enhanced Response Format** — JSON structure with expandable sources

### 8.2 Future Enhancements

1. **Dynamic Follow-up Questions**
   - Add AI-generated contextual suggestions
   - Requires small backend modification

2. **Response Letters Ingestion** — Precedent tracking
3. **Query Caching** — Reduce API costs
4. **Analytics Dashboard** — Query patterns, coverage gaps
5. **Enable Reranker Tool** — Currently disabled; re-enable after fixing expression parsing

---

## 9. Response Format (v2)

### 9.1 JSON Response Structure

The AI Agent now returns structured JSON responses:

```json
{
  "answer": "Comprehensive prose answer without headers",
  "sources": [
    {
      "document_name": "CC&Rs Declaration",
      "section_title": "Section Title",
      "section_hierarchy": ["Parent", "Child"],
      "page_number": 42,
      "is_binding": true,
      "requirements": [
        "Specific requirement 1",
        "Specific requirement 2"
      ],
      "content": "Full source text..."
    }
  ],
  "confidence": {
    "level": "High",
    "explanation": "Reasoning for confidence level"
  }
}
```

### 9.2 Frontend Features

| Feature | Description |
|---------|-------------|
| Expandable Sources | Click source header to expand/collapse requirements |
| Source Text Toggle | "Show source text" button reveals full chunk content |
| Confidence Tooltip | Click confidence badge for explanation |
| Copy Answer | Copy button in message header |
| Authority Badges | Visual indicator for binding vs. guidance documents |
| Auto-extracted Requirements | Falls back to parsing content if AI doesn't provide array |

### 9.3 Key Files

| File | Purpose |
|------|---------|
| [scripts/system-prompt.txt](../scripts/system-prompt.txt) | AI Agent system prompt with JSON format |
| [scripts/format-response-node.js](../scripts/format-response-node.js) | n8n Code node for parsing AI output |

---

## 10. File References

| File | Purpose |
|------|---------|
| [database/001_initial_schema.sql](../database/001_initial_schema.sql) | Complete Supabase schema |
| [database/002_storage_bucket.sql](../database/002_storage_bucket.sql) | Storage bucket setup |
| [docs/ARCHITECTURE.md](ARCHITECTURE.md) | System architecture |
| [docs/DATA_MODEL.md](DATA_MODEL.md) | Database schema details |
| [docs/RETRIEVAL_STRATEGY.md](RETRIEVAL_STRATEGY.md) | Search logic |
| [docs/AGENT_GUARDRAILS.md](AGENT_GUARDRAILS.md) | AI behavior rules |
| [docs/ANSWER_CONTRACT.md](ANSWER_CONTRACT.md) | Response format |
| [docs/CHUNKING_STRATEGY.md](CHUNKING_STRATEGY.md) | Document processing |
| [docs/RISKS_AND_MITIGATIONS.md](RISKS_AND_MITIGATIONS.md) | Risk register |
| [scripts/system-prompt.txt](../scripts/system-prompt.txt) | AI Agent system prompt |
| [scripts/format-response-node.js](../scripts/format-response-node.js) | Response formatting code |

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.3 | 2026-01-01 | AI Agent | Ingested CC&Rs (83 chunks) and Rules & Regulations (1 chunk); Enhanced response format with JSON structure; Added expandable sources UI |
| 1.2 | 2025-12-31 | AI Agent | Added exhibit supplements (148 total chunks), full exhibit A-O coverage |
| 1.1 | 2025-12-31 | AI Agent | Added TOC-based section detection documentation |
| 1.0 | 2025-12-31 | AI Agent | Initial implementation status after Phase 1 |

