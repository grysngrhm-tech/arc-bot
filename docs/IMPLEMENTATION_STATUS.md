# ARC Bot (Architectural Review Console) — Implementation Status

**Version:** 2.4  
**Last Updated:** January 6, 2026  
**Status:** Production Ready with Voice Mode & Mobile Fixes

---

## 1. Executive Summary

| Component | Status | Details |
|-----------|--------|---------|
| **Voice Mode** | ✅ Complete | Unified voice+text chat via OpenAI Realtime API |
| **PWA** | ✅ Complete | Installable app, offline support, mobile-optimized |
| **Error Handling** | ✅ Complete | AbortController, exponential backoff, cancel/retry UI |
| **Mobile Audio** | ✅ Complete | Tap-to-play fallback, playsinline, autoplay handling |
| **Response Formatting** | ✅ Complete | JSON parsing with proper escaping for TTS |
| Voice Session Workflow | ✅ Complete | Ephemeral token generation for WebRTC |
| Supabase Database | ✅ Complete | Schema, indexes, functions deployed |
| Storage Bucket | ✅ Complete | `arc-documents` bucket created |
| Document Ingestion Workflow | ✅ Complete | 244 chunks ingested (4 documents) |
| Exhibit Supplements | ✅ Complete | All exhibits A-O vectorized |
| Hybrid Retrieval Tool | ✅ Complete | Tested and working |
| Reranker Tool | ⏸️ Disabled | Disconnected for performance (adds ~60s latency) |
| Main AI Agent Workflow | ✅ Complete | GPT-4o with enforced JSON response format |
| Chat Frontend | ✅ Complete | Discovery West branded UI with voice input |
| Rotating Question Library | ✅ Complete | 26 nuanced questions across 4 document types |
| Authority Labels | ✅ Complete | Binding, ARC Guidance, DWOA Guidance badges |

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
| `documents` | Source document registry | 5 |
| `knowledge_chunks` | Main chunk storage with embeddings | 256 |
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
  "chunk_count": 15,
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
| City of Bend - Discovery West | city_code | N/A | 12 | ✅ Complete |
| **Total** | | **201+** | **256** | |

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

**City of Bend Development Code - Discovery West:**
- Source: https://bend.municipal.codes/BDC/2.7_ArtXIX
- Ingested: January 2, 2026
- Chunk Distribution: 12 chunks across 10 code sections
- Content: Article XIX Discovery West Master Planned Development (districts, permitted uses, setbacks, live/work townhomes, cluster housing, street standards)
- Sections: 2.7.3700-2.7.3790

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
| Embedding model mismatch | Manual upload script used `text-embedding-3-small`, n8n used `text-embedding-3-large` | Align all embedding generation to use `text-embedding-3-large` with `dimensions: 1536` |
| City code chunks not found | Vector similarity was 0 due to embedding mismatch | Re-uploaded chunks with correct embedding model |
| Slow response times (~70s) | Reranker calling GPT-4o to score 15 chunks | Disabled reranker; embedding fix made it less necessary |
| AI returns markdown instead of JSON | System prompt instructions not always followed | Enabled `responseFormat: json_object` in OpenAI Chat Model node |
| Voice state stuck on "listening" | Voice mode wouldn't exit after TTS completed | Removed `setVoiceInputState('listening')` from response handlers |
| Invalid property check (`audio.playing`) | JavaScript audio elements don't have `.playing` property | Changed to `audio.paused` for correct logic |
| VAD too sensitive (500ms) | User speech cut off prematurely | Increased `silence_duration_ms` to 1200ms |
| No manual VAD override | Users couldn't submit if VAD failed | Added "Done" button to manually commit audio buffer |
| Transcription timeout | App stuck if Realtime API failed to transcribe | 30-second timeout with error recovery |
| Mobile autoplay blocked | `audio.play()` rejected without user gesture | Tap-to-play indicator with `playsinline` attribute |
| TTS JSON escaping | Special characters broke OpenAI API | `JSON.stringify($json.body.text)` in n8n workflow |
| Main Agent malformed response | AI output both text and raw JSON | Updated Format Response node to parse JSON from output |

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
11. **Use consistent embedding models** - All scripts and workflows must use the same model (`text-embedding-3-large`, 1536 dims)
12. **Enable JSON response format** - Use OpenAI's native `responseFormat: json_object` option, not just prompt instructions
13. **Retrieve more chunks than needed** - 15 chunks ensures diverse document types aren't filtered; agent/frontend handles final selection

---

## 8. Next Steps

### 8.1 Completed (Phase 1-6)

1. ✅ **Database Schema** — Supabase with pgvector
2. ✅ **Document Ingestion** — Structure-aware chunking with TOC detection
3. ✅ **Hybrid Retrieval Tool** — Vector + FTS search
4. ✅ **Reranker Tool** — GPT-4o relevance scoring
5. ✅ **Main AI Agent** — Tools Agent with session memory
6. ✅ **Chat Frontend** — GitHub Pages with theme toggle
7. ✅ **Exhibit Supplements** — All exhibits A-O manually transcribed and vectorized
8. ✅ **CC&Rs & Rules Ingestion** — All governing documents now searchable
9. ✅ **Enhanced Response Format** — JSON structure with expandable sources
10. ✅ **City Code Ingestion** — Discovery West Overlay Zone (BDC Article XIX)
11. ✅ **UI Branding Refresh** — Discovery West branded design with official logos, enhanced welcome panel, direct PDF links
12. ✅ **Rotating Question Library** — 26 nuanced questions across 4 document types with random selection
13. ✅ **Authority Labels** — Binding, ARC Guidance, and DWOA Guidance badges with consistent display

### 8.2 Future Enhancements

1. **Dynamic Follow-up Questions**
   - Add AI-generated contextual suggestions
   - Requires small backend modification

2. **Response Letters Ingestion** — Precedent tracking
3. **Query Caching** — Reduce API costs
4. **Analytics Dashboard** — Query patterns, coverage gaps
5. **Optimized Reranker** — Currently disabled for performance; consider GPT-4o-mini or fewer chunks if re-enabled

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
| Discovery West Branding | Official pinecone logo, charcoal/burnt orange color scheme |
| Enhanced Welcome Panel | Expanded description explaining what ARC Bot is and how it works |
| Direct Document Links | Links to actual PDF source documents (Guidelines, CC&Rs, Rules, City Code) |
| Rotating Question Library | 26 nuanced questions (5-10 per document type) with random rotation on each visit |
| Authority Labels | Aligned labels: Binding (CC&Rs, City Code), ARC Guidance (Design Guidelines), DWOA Guidance (Rules) |
| Montserrat Typography | Professional typography matching Discovery West aesthetic |
| Staggered Animations | Smooth fade-in animations for welcome panel elements |

### 9.3 Key Files

| File | Purpose |
|------|---------|
| [scripts/system-prompt.txt](../scripts/system-prompt.txt) | AI Agent system prompt with JSON format |
| [scripts/format-response-node.js](../scripts/format-response-node.js) | n8n Code node for parsing AI output |

---

## 10. Voice Mode (v2.0)

### 10.1 Overview

Voice mode allows users to speak questions and hear answers read aloud. Voice and text share the same conversation, with identical formatting and source citations.

### 10.2 Architecture

```
User speaks → WebRTC → OpenAI Realtime API → get_arc_answer() → Main Agent → Response
                                                                      ↓
                                            Chat renders formatted message + Audio plays
```

**Key Design Decision:** Voice mode is a "voice interface" to the Main Agent, not a separate AI:
- Realtime API configured with meta-prompt that delegates all questions
- `get_arc_answer()` function routes questions to the same Main Agent workflow
- Identical answers between voice and text modes
- Voice responses include natural source citations

### 10.3 n8n Workflow: Voice Session

| Property | Value |
|----------|-------|
| **Name** | ARC Bot - Voice Session |
| **ID** | `eNkvTZbFPjbkQIz2` |
| **Webhook Path** | `/arc-voice-session` |
| **Purpose** | Generate ephemeral tokens for Realtime API |

**Flow:**
```
Webhook (POST) → HTTP Request (OpenAI Realtime Sessions) → Return client_secret
```

### 10.4 Frontend Voice Functions

| Function | Purpose |
|----------|---------|
| `toggleVoiceMode()` | Start/stop voice mode, transform input area |
| `setVoiceInputState(state)` | Update UI for listening/processing/speaking |
| `handleGetAnswer(callId, args)` | Handle function call, route to Main Agent, render response |
| `formatAnswerForVoice(data)` | Add natural citations for speech output |

### 10.5 Voice Meta-Prompt

The Realtime API is configured with a meta-prompt that forces delegation:

```
You are a voice interface for ARC Bot...

CRITICAL RULE: You do NOT have architectural knowledge. For ANY question about:
- Architectural guidelines, requirements, or standards
- CC&Rs, covenants, conditions, or restrictions
- Community rules and regulations
...

You MUST call the get_arc_answer function and then read the response naturally.
```

---

## 11. PWA Features (v1.7+)

### 11.1 Overview

ARC Bot is a Progressive Web App that can be installed on iOS and Android devices, works offline, and provides a native-like experience.

### 11.2 Components

| File | Purpose |
|------|---------|
| `manifest.json` | PWA metadata, icons, theme colors |
| `sw.js` | Service worker for caching |
| `assets/icons/` | Various icon sizes for platforms |

### 11.3 Service Worker Strategy

- **Cache-first** for static assets (HTML, CSS, JS, images)
- **Network-first** for API calls
- **Precaching** of app shell on install
- **Cache versioning** (`arc-bot-v2.0`) for updates

### 11.4 Mobile Optimizations

| Feature | Implementation |
|---------|----------------|
| Touch targets | Minimum 48px for interactive elements |
| Safe areas | CSS `env(safe-area-inset-*)` for notched devices |
| Input handling | `inputmode`, `enterkeyhint` for mobile keyboards |
| Viewport | `viewport-fit=cover`, `overscroll-behavior: none` |
| Install prompts | Custom UI for iOS and Android |

---

## 12. Error Handling (v1.5+)

### 12.1 Features

| Feature | Implementation |
|---------|----------------|
| Request timeout | 45-second AbortController timeout |
| Retry logic | Exponential backoff (1s, 2s, 4s) up to 3 retries |
| Cancel button | Stop pending request, show retry option |
| Error classification | Network, timeout, server, rate limit categories |
| Graceful degradation | User-friendly error messages with retry |

### 12.2 Error Types

```javascript
const ErrorTypes = {
  NETWORK_ERROR: 'network',
  TIMEOUT_ERROR: 'timeout',
  SERVER_ERROR: 'server',
  RATE_LIMIT: 'rate_limit',
  UNKNOWN: 'unknown'
};
```

---

## 13. File References

| File | Purpose |
|------|---------|
| `index.html` | Main PWA frontend with voice mode |
| `manifest.json` | PWA manifest |
| `sw.js` | Service worker |
| [database/001_initial_schema.sql](../database/001_initial_schema.sql) | Complete Supabase schema |
| [database/002_storage_bucket.sql](../database/002_storage_bucket.sql) | Storage bucket setup |
| [database/004_dw_overlay_zone.sql](../database/004_dw_overlay_zone.sql) | Discovery West code chunks |
| [docs/ARCHITECTURE.md](ARCHITECTURE.md) | System architecture |
| [docs/DATA_MODEL.md](DATA_MODEL.md) | Database schema details |
| [docs/RETRIEVAL_STRATEGY.md](RETRIEVAL_STRATEGY.md) | Search logic |
| [docs/AGENT_GUARDRAILS.md](AGENT_GUARDRAILS.md) | AI behavior rules |
| [docs/ANSWER_CONTRACT.md](ANSWER_CONTRACT.md) | Response format |
| [docs/CHUNKING_STRATEGY.md](CHUNKING_STRATEGY.md) | Document processing |
| [docs/VOICE_MODE_SETUP.md](VOICE_MODE_SETUP.md) | Voice mode setup guide |
| [docs/RISKS_AND_MITIGATIONS.md](RISKS_AND_MITIGATIONS.md) | Risk register |
| [scripts/system-prompt.txt](../scripts/system-prompt.txt) | AI Agent system prompt |
| [scripts/format-response-node.js](../scripts/format-response-node.js) | Response formatting code |

---

## 14. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.4 | 2026-01-06 | AI Agent | **Bug Fixes:** Mobile audio tap-to-play fallback; TTS JSON escaping fix (`JSON.stringify`); Main Agent Format Response JSON parsing; Skip MediaSource streaming on mobile |
| 2.3 | 2026-01-06 | AI Agent | Voice UX: VAD increased to 1200ms; Manual "Done" button; 30-second transcription timeout; Fixed `audio.paused` check |
| 2.2 | 2026-01-06 | AI Agent | Streaming TTS via MediaSource API; Voice state management fixes; Loading animations |
| 2.1 | 2026-01-05 | AI Agent | Unified TTS architecture: Single TTS path via n8n webhook; Removed WebRTC audio output |
| 2.0 | 2026-01-05 | AI Agent | **Major Release:** Unified voice+text chat via OpenAI Realtime API; Voice as interface to Main Agent; PWA optimization complete; Mobile touch targets and safe areas |
| 1.8 | 2026-01-05 | AI Agent | Voice mode with full-screen overlay; OpenAI Realtime API integration; WebRTC audio |
| 1.7 | 2026-01-05 | AI Agent | PWA features: Service worker, manifest, install prompts; Mobile optimizations |
| 1.6 | 2026-01-04 | AI Agent | Error handling: AbortController, exponential backoff, cancel/retry UI |
| 1.5 | 2026-01-02 | AI Agent | Internal launch ready: Rotating question library, Authority labels |
| 1.4 | 2026-01-02 | AI Agent | UI branding refresh: Discovery West logos, charcoal/orange color scheme |
| 1.3 | 2026-01-02 | AI Agent | Fixed embedding model mismatch; Enabled JSON response format |
| 1.2 | 2026-01-02 | AI Agent | Added City of Bend Development Code (12 chunks) |
| 1.1 | 2026-01-01 | AI Agent | Ingested CC&Rs (83 chunks) and Rules & Regulations (1 chunk) |
| 1.0 | 2025-12-31 | AI Agent | Initial implementation with Design Guidelines (148 chunks) |

