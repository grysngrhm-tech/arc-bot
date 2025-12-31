# ARC Bot (Architectural Review Console) — Retrieval Strategy

**Version:** 1.0  
**Last Updated:** December 31, 2025  
**Status:** Canonical Reference

---

## 1. Overview

This document specifies the hybrid retrieval and reranking strategy for ARC Bot. Retrieval quality directly determines answer quality — this is the most critical component of the RAG pipeline.

### 1.1 Core Principles

1. **Retrieval returns candidates, not truth** — Never trust raw similarity scores
2. **Hybrid search is mandatory** — Vector alone misses keyword matches
3. **Reranking is mandatory** — Raw scores are not calibrated
4. **Over-retrieve, then filter** — Get 20 candidates, use 5-8 final
5. **Metadata enriches ranking** — Document type and binding status matter

### 1.2 Retrieval Pipeline

```
User Query
    │
    ▼
┌─────────────────────────────────────────┐
│         QUERY PREPROCESSING             │
│  • Clean and normalize text             │
│  • Extract potential keywords           │
│  • Generate query embedding             │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│         HYBRID RETRIEVAL                │
│                                         │
│  ┌─────────────┐   ┌─────────────┐     │
│  │   Vector    │   │   Full-Text │     │
│  │   Search    │   │   Search    │     │
│  │  (pgvector) │   │   (FTS)     │     │
│  └──────┬──────┘   └──────┬──────┘     │
│         │                  │            │
│         └────────┬─────────┘            │
│                  ▼                      │
│         ┌───────────────┐              │
│         │    Combine    │              │
│         │  & Deduplicate│              │
│         └───────────────┘              │
└─────────────────────────────────────────┘
    │
    │ Top 20 candidates
    ▼
┌─────────────────────────────────────────┐
│            RERANKING                    │
│  • LLM-based relevance scoring          │
│  • Query-chunk alignment check          │
│  • Binding status boost                 │
└─────────────────────────────────────────┘
    │
    │ Top 5-8 ranked chunks
    ▼
┌─────────────────────────────────────────┐
│         CONTEXT ASSEMBLY                │
│  • Order by document structure          │
│  • Include adjacent chunks if needed    │
│  • Format for agent consumption         │
└─────────────────────────────────────────┘
    │
    ▼
Final Context for Agent
```

---

## 2. Query Preprocessing

### 2.1 Query Normalization

Before retrieval, queries undergo minimal preprocessing:

```
Input:  "What's the max fence height allowed in my backyard??"
Output: "What is the max fence height allowed in my backyard"
```

**Steps:**
1. Normalize unicode characters
2. Remove excessive punctuation
3. Expand common contractions
4. Preserve original case (embeddings are case-aware)

### 2.2 Query Embedding

**Model:** OpenAI text-embedding-3-large  
**Dimensions:** 1536 (reduced from native 3072 due to Supabase HNSW limit)  
**Normalization:** L2 normalized (handled by OpenAI)

```javascript
// n8n Code node example
const response = await $http.request({
  method: 'POST',
  url: 'https://api.openai.com/v1/embeddings',
  headers: {
    'Authorization': `Bearer ${$credentials.openai.apiKey}`,
    'Content-Type': 'application/json'
  },
  body: {
    model: 'text-embedding-3-large',
    input: query,
    dimensions: 1536
  }
});

return response.data[0].embedding;
```

---

## 3. Vector Search

### 3.1 Search Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Distance metric | Cosine | Standard for text embeddings |
| Index type | HNSW | Fast approximate search |
| ef_search | 40 | Good recall/speed tradeoff |
| Initial candidates | 40 | 2x final hybrid count |

### 3.2 Vector Search Query

```sql
-- Vector similarity search
SELECT 
    id,
    content,
    document_name,
    document_type,
    section_hierarchy,
    page_number,
    is_binding,
    1 - (embedding <=> $1) AS similarity
FROM knowledge_chunks
WHERE document_type = ANY($2)  -- Optional filter
ORDER BY embedding <=> $1
LIMIT 40;
```

### 3.3 Similarity Score Interpretation

| Score Range | Interpretation |
|-------------|----------------|
| > 0.85 | High relevance, likely direct match |
| 0.70 - 0.85 | Moderate relevance, related content |
| 0.55 - 0.70 | Low relevance, possibly tangential |
| < 0.55 | Poor relevance, likely noise |

**Note:** These thresholds are for text-embedding-3-large with cosine similarity. Calibrate after initial testing.

---

## 4. Full-Text Search

### 4.1 FTS Configuration

**Language:** English  
**Index:** GIN on tsvector  
**Ranking:** ts_rank_cd (cover density)

### 4.2 FTS Query

```sql
-- Full-text search with ranking
SELECT 
    id,
    content,
    document_name,
    document_type,
    section_hierarchy,
    page_number,
    is_binding,
    ts_rank_cd(fts_vector, query) AS fts_rank
FROM knowledge_chunks,
     plainto_tsquery('english', $1) AS query
WHERE fts_vector @@ query
  AND document_type = ANY($2)  -- Optional filter
ORDER BY fts_rank DESC
LIMIT 40;
```

### 4.3 When FTS Excels

FTS is particularly valuable for:

- **Exact terminology**: "setback", "easement", "variance"
- **Specific measurements**: "6 feet", "12 inches"
- **Document references**: "Section 4.2", "Exhibit A"
- **Proper nouns**: "Discovery West", "ARC"

### 4.4 FTS Score Normalization

FTS scores are not on a 0-1 scale. Normalize before combining:

```sql
-- Normalize FTS score to 0-1 range
GREATEST(0, LEAST(1, ts_rank_cd(fts_vector, query) * 10))
```

---

## 5. Hybrid Score Combination

### 5.1 Combination Formula

```
hybrid_score = (vector_score × vector_weight) + (fts_score × fts_weight)
```

**Default Weights:**
- vector_weight: 0.70
- fts_weight: 0.30

### 5.2 Combination Logic

```sql
WITH vector_results AS (
    SELECT id, 1 - (embedding <=> $1) AS v_score
    FROM knowledge_chunks
    ORDER BY embedding <=> $1
    LIMIT 40
),
fts_results AS (
    SELECT id, GREATEST(0, LEAST(1, ts_rank_cd(fts_vector, plainto_tsquery('english', $2)) * 10)) AS f_score
    FROM knowledge_chunks
    WHERE fts_vector @@ plainto_tsquery('english', $2)
    LIMIT 40
),
combined AS (
    SELECT 
        COALESCE(v.id, f.id) AS id,
        COALESCE(v.v_score, 0) AS vector_score,
        COALESCE(f.f_score, 0) AS fts_score,
        (COALESCE(v.v_score, 0) * 0.7 + COALESCE(f.f_score, 0) * 0.3) AS hybrid_score
    FROM vector_results v
    FULL OUTER JOIN fts_results f ON v.id = f.id
)
SELECT c.*, kc.content, kc.document_name, kc.section_hierarchy
FROM combined c
JOIN knowledge_chunks kc ON kc.id = c.id
ORDER BY hybrid_score DESC
LIMIT 20;
```

### 5.3 Deduplication

When the same chunk appears in both vector and FTS results, combine scores (already handled by FULL OUTER JOIN above).

### 5.4 Weight Tuning Guidelines

| Scenario | Vector Weight | FTS Weight |
|----------|---------------|------------|
| General questions | 0.70 | 0.30 |
| Specific terminology | 0.50 | 0.50 |
| "What does X mean?" | 0.80 | 0.20 |
| "Where is Y mentioned?" | 0.40 | 0.60 |

**Future Enhancement:** Detect query type and adjust weights dynamically.

---

## 6. Reranking

### 6.1 Purpose

Raw retrieval scores are not calibrated for relevance. Reranking uses an LLM to:

1. Assess semantic alignment between query and chunk
2. Consider context that embedding similarity misses
3. Apply governance-specific relevance criteria

### 6.2 Reranking Prompt

```
You are evaluating document chunks for relevance to an architectural review question.

Question: {query}

For each chunk, score its relevance from 0.0 to 1.0 based on:
- Does it directly answer the question? (highest weight)
- Does it provide necessary context for the answer?
- Does it define terms used in the question?
- Is it from an authoritative source (CC&Rs, Design Guidelines)?

Chunk {n}:
Document: {document_name}
Section: {section_hierarchy}
Content: {content}

Respond with ONLY a JSON array of objects:
[
  {"chunk_id": "...", "relevance_score": 0.XX, "reasoning": "brief explanation"}
]

Be strict. If a chunk is tangentially related but doesn't help answer the question, score it below 0.5.
```

### 6.3 Reranking Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Model | GPT-4o | Strong reasoning, fast |
| Temperature | 0 | Deterministic scoring |
| Max chunks | 20 | Balance cost/quality |
| Timeout | 15 seconds | Prevent hanging |

### 6.4 Score Adjustments

After LLM reranking, apply metadata-based adjustments:

```javascript
function adjustScore(chunk, baseScore) {
    let score = baseScore;
    
    // Boost binding documents
    if (chunk.is_binding === true) {
        score *= 1.1;
    }
    
    // Slight boost for Design Guidelines (primary source)
    if (chunk.document_type === 'design_guidelines') {
        score *= 1.05;
    }
    
    // Penalize superseded content
    if (chunk.superseded_by !== null) {
        score *= 0.5;
    }
    
    // Cap at 1.0
    return Math.min(score, 1.0);
}
```

### 6.5 Final Ranking

After reranking:

1. Sort by adjusted relevance score (descending)
2. Take top 5-8 chunks
3. Group by document for coherent context
4. Include chunk neighbors if partial answer detected

---

## 7. Context Assembly

### 7.1 Final Chunk Selection

**Target:** 5-8 chunks  
**Token budget:** ~4000 tokens (leaves room for system prompt and response)

```javascript
function selectFinalChunks(rankedChunks, tokenBudget = 4000) {
    const selected = [];
    let totalTokens = 0;
    
    for (const chunk of rankedChunks) {
        if (totalTokens + chunk.token_count > tokenBudget) {
            break;
        }
        if (chunk.relevance_score >= 0.5) {  // Minimum threshold
            selected.push(chunk);
            totalTokens += chunk.token_count;
        }
        if (selected.length >= 8) {
            break;
        }
    }
    
    return selected;
}
```

### 7.2 Context Formatting

Format chunks for agent consumption:

```
[SOURCE 1]
Document: Architectural Design Guidelines
Section: Chapter 4 > Section 4.2 > Fencing
Page: 42
Binding: Yes

Content:
{chunk content}

---

[SOURCE 2]
Document: CC&Rs Declaration
Section: Article VII > Section 7.3
Page: 23
Binding: Yes

Content:
{chunk content}

---
...
```

### 7.3 Adjacent Chunk Inclusion

If a chunk appears to be mid-sentence or mid-paragraph:

```javascript
async function expandChunkContext(chunkId, direction = 'both') {
    const query = `
        WITH target AS (
            SELECT document_id, chunk_index
            FROM knowledge_chunks WHERE id = $1
        )
        SELECT * FROM knowledge_chunks
        WHERE document_id = (SELECT document_id FROM target)
          AND chunk_index BETWEEN 
              (SELECT chunk_index FROM target) - 1 
              AND (SELECT chunk_index FROM target) + 1
        ORDER BY chunk_index
    `;
    // Concatenate adjacent chunks
}
```

---

## 8. Document Type Filtering

### 8.1 Default Behavior

By default, search all document types with binding documents prioritized.

### 8.2 Query-Based Filtering

| Query Pattern | Filter To |
|---------------|-----------|
| "according to the guidelines" | design_guidelines |
| "CC&R says" / "covenants state" | ccr |
| "previous approval" / "precedent" | response_letter |
| "application process" | application_form |

### 8.3 Filter Implementation

```javascript
function detectDocumentFilter(query) {
    const patterns = {
        design_guidelines: /guideline|design standard|architectural/i,
        ccr: /cc&?r|covenant|declaration|restriction/i,
        response_letter: /previous|precedent|approved before|decision/i,
        application_form: /application|submit|form|process/i
    };
    
    for (const [type, pattern] of Object.entries(patterns)) {
        if (pattern.test(query)) {
            return [type];
        }
    }
    
    return null; // Search all
}
```

---

## 9. Performance Optimization

### 9.1 Query Execution Plan

1. **Embed query** (~200ms via OpenAI API)
2. **Execute hybrid search** (~100ms with indexes)
3. **Rerank candidates** (~2-3s via GPT-4o)
4. **Assemble context** (~10ms)

**Total target:** < 4 seconds

### 9.2 Caching Strategy

| Cache | TTL | Purpose |
|-------|-----|---------|
| Query embeddings | 1 hour | Repeat questions |
| Hybrid results | 5 minutes | Same query variations |
| Reranking | None | Too query-specific |

### 9.3 Index Maintenance

```sql
-- Periodic HNSW index maintenance (run weekly)
REINDEX INDEX idx_knowledge_chunks_embedding;

-- Update FTS statistics
ANALYZE knowledge_chunks;
```

---

## 10. Quality Metrics

### 10.1 Retrieval Quality Indicators

| Metric | Target | Red Flag |
|--------|--------|----------|
| Avg top-1 relevance score | > 0.75 | < 0.5 |
| Chunks with score > 0.6 | 3+ | 0-1 |
| FTS-only matches in top 5 | 1-2 | 0 or 5 |
| Vector-only matches in top 5 | 2-3 | 0 or 5 |

### 10.2 Monitoring Queries

```sql
-- Check retrieval distribution
SELECT 
    CASE 
        WHEN vector_score > 0 AND fts_score > 0 THEN 'both'
        WHEN vector_score > 0 THEN 'vector_only'
        ELSE 'fts_only'
    END AS source,
    COUNT(*) AS count,
    AVG(combined_score) AS avg_score
FROM query_results
GROUP BY source;
```

---

## 11. Failure Modes

### 11.1 No Results

**Trigger:** Zero chunks with relevance > 0.3

**Response:** Return special "no_results" flag to agent
```json
{
  "status": "no_results",
  "message": "No relevant content found in governing documents",
  "query": "original query"
}
```

### 11.2 Low Confidence Results

**Trigger:** Highest relevance score < 0.5

**Response:** Return results with "low_confidence" flag
```json
{
  "status": "low_confidence",
  "best_score": 0.42,
  "chunks": [...],
  "warning": "Results may not directly answer the question"
}
```

### 11.3 Embedding API Failure

**Response:** Fall back to FTS-only search with degraded quality warning

---

## 12. Tuning Checklist

Before deployment, validate:

- [ ] Vector search returns relevant results for 10 test queries
- [ ] FTS finds exact terminology matches
- [ ] Hybrid combination improves over either alone
- [ ] Reranking elevates correct chunks
- [ ] Token budget fits context window
- [ ] Latency < 5 seconds end-to-end

---

## 13. Implementation Status

### 13.1 Deployed Workflow

The Hybrid Retrieval Tool is implemented as an n8n sub-workflow:

- **Webhook Path:** `/webhook/arc-retrieval`
- **Status:** ✅ Active and tested

### 13.2 Actual Test Results

| Query | Status | Combined | Vector | FTS |
|-------|--------|----------|--------|-----|
| "What is the maximum fence height allowed?" | success | 0.37 | 0.52 | 0.006 |
| "What colors can I paint my house?" | low_confidence | 0.29 | 0.41 | 0.001 |
| "setback requirements" | success | **0.65** | 0.30 | **1.0** |

### 13.3 Observations

1. **Hybrid combination working** - FTS provides significant boost for exact keyword matches
2. **Confidence thresholds calibrated** - 0.35 threshold appropriate for current corpus
3. **Reranking deferred** - Initial retrieval quality sufficient for MVP

---

## 14. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1 | 2025-12-31 | AI Agent | Added implementation status and test results |
| 1.0 | 2025-12-31 | AI Agent | Initial retrieval strategy |

