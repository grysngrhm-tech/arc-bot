# ARC Bot (Architectural Review Console) — Data Model Specification

**Version:** 1.0  
**Last Updated:** December 31, 2025  
**Status:** Canonical Reference

---

## 1. Overview

This document defines the database schema for ARC Bot's knowledge store. All document chunks, embeddings, metadata, and search indexes are specified here.

### 1.1 Design Principles

1. **Single source of truth** — One canonical table for all knowledge chunks
2. **Rich metadata** — Every chunk carries full provenance information
3. **Future-proof** — Schema accommodates submittals and response letters
4. **Hybrid search ready** — Both vector and full-text indexes
5. **Audit trail** — Track document ingestion and updates

---

## 2. Database Configuration

### 2.1 Supabase Project

- **Project:** New dedicated project for ARC Bot
- **Region:** Recommended: us-west-1 (closest to user base)
- **Plan:** Free tier sufficient for initial deployment

### 2.2 Required Extensions

```sql
-- Enable pgvector for embedding storage and similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable pg_trgm for fuzzy text matching (optional enhancement)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

### 2.3 Dimension Constraint

**Important:** Supabase's HNSW index has a maximum of 2000 dimensions. We use **1536 dimensions** with `text-embedding-3-large` by specifying `dimensions: 1536` in the OpenAI API call. This provides excellent quality while staying within the index limit.

---

## 3. Primary Table: `knowledge_chunks`

### 3.1 Table Schema

```sql
CREATE TABLE knowledge_chunks (
    -- Primary identification
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Content
    content             TEXT NOT NULL,
    content_hash        TEXT NOT NULL,  -- SHA-256 for deduplication
    
    -- Embedding (1536 dimensions - text-embedding-3-large with dimensions=1536)
    embedding           VECTOR(1536),
    
    -- Full-text search vector
    fts_vector          TSVECTOR GENERATED ALWAYS AS (
                            to_tsvector('english', content)
                        ) STORED,
    
    -- Document identification
    document_id         UUID NOT NULL,
    document_name       TEXT NOT NULL,
    document_type       TEXT NOT NULL,  -- See 3.3 for allowed values
    
    -- Location within document
    section_hierarchy   TEXT[],         -- ['Chapter 4', 'Section 4.2', 'Fencing']
    section_title       TEXT,
    page_number         INTEGER,
    chunk_index         INTEGER NOT NULL,  -- Order within document
    
    -- Chunk boundaries
    char_start          INTEGER,
    char_end            INTEGER,
    token_count         INTEGER,
    
    -- Governance metadata
    is_binding          BOOLEAN DEFAULT TRUE,
    effective_date      DATE,
    superseded_by       UUID REFERENCES knowledge_chunks(id),
    
    -- Future: Submittal/Response specific
    lot_number          TEXT,
    address             TEXT,
    submittal_date      DATE,
    decision            TEXT,           -- 'approved', 'denied', 'conditional'
    
    -- Audit fields
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    source_file_path    TEXT,           -- Path in Supabase Storage
    ingestion_batch_id  UUID,
    
    -- Constraints
    CONSTRAINT valid_document_type CHECK (
        document_type IN (
            'design_guidelines',
            'ccr',
            'rules_regulations',
            'application_form',
            'submittal',
            'response_letter',
            'amendment'
        )
    ),
    CONSTRAINT valid_decision CHECK (
        decision IS NULL OR decision IN ('approved', 'denied', 'conditional', 'withdrawn')
    )
);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER knowledge_chunks_updated_at
    BEFORE UPDATE ON knowledge_chunks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

### 3.2 Column Reference

| Column | Type | Purpose | Required |
|--------|------|---------|----------|
| `id` | UUID | Primary key | Auto |
| `content` | TEXT | The actual chunk text | Yes |
| `content_hash` | TEXT | SHA-256 hash for deduplication | Yes |
| `embedding` | VECTOR(1536) | OpenAI embedding | Yes |
| `fts_vector` | TSVECTOR | Auto-generated FTS index | Auto |
| `document_id` | UUID | Groups chunks from same document | Yes |
| `document_name` | TEXT | Human-readable document name | Yes |
| `document_type` | TEXT | Classification of source | Yes |
| `section_hierarchy` | TEXT[] | Breadcrumb path to section | No |
| `section_title` | TEXT | Immediate section header | No |
| `page_number` | INTEGER | Page in source PDF | No |
| `chunk_index` | INTEGER | Order within document | Yes |
| `char_start` | INTEGER | Start position in source | No |
| `char_end` | INTEGER | End position in source | No |
| `token_count` | INTEGER | Token count for context management | No |
| `is_binding` | BOOLEAN | Official rule vs. precedent | Yes |
| `effective_date` | DATE | When rule became effective | No |
| `superseded_by` | UUID | If replaced by newer chunk | No |
| `lot_number` | TEXT | For submittal-specific chunks | No |
| `address` | TEXT | For address-specific guidance | No |
| `submittal_date` | DATE | For response letters | No |
| `decision` | TEXT | ARC decision on submittal | No |
| `created_at` | TIMESTAMPTZ | Ingestion timestamp | Auto |
| `updated_at` | TIMESTAMPTZ | Last modification | Auto |
| `source_file_path` | TEXT | Location in Storage bucket | No |
| `ingestion_batch_id` | UUID | Groups chunks from same run | No |

### 3.3 Document Types

| Type | Description | is_binding Default |
|------|-------------|-------------------|
| `design_guidelines` | Architectural Design Guidelines | TRUE |
| `ccr` | CC&Rs Declaration | TRUE |
| `rules_regulations` | Community Rules and Regulations | TRUE |
| `application_form` | ARC Application/Process docs | TRUE |
| `submittal` | Homeowner submittal package | FALSE |
| `response_letter` | ARC response/decision letter | FALSE |
| `amendment` | Amendments to governing docs | TRUE |

---

## 4. Indexes

### 4.1 Vector Index (HNSW)

```sql
-- HNSW index for fast approximate nearest neighbor search
-- Using cosine distance (most common for text embeddings)
CREATE INDEX idx_knowledge_chunks_embedding ON knowledge_chunks 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,              -- Max connections per node
    ef_construction = 64 -- Build-time search depth
);
```

**HNSW Parameters Rationale:**
- `m = 16`: Good balance of recall and index size for ~1000 chunks
- `ef_construction = 64`: Higher quality index at build time
- Query-time `ef_search` set to 40 (in SQL query)

### 4.2 Full-Text Search Index

```sql
-- GIN index for full-text search
CREATE INDEX idx_knowledge_chunks_fts ON knowledge_chunks 
USING GIN (fts_vector);
```

### 4.3 Supporting Indexes

```sql
-- Document filtering
CREATE INDEX idx_knowledge_chunks_document_type ON knowledge_chunks (document_type);
CREATE INDEX idx_knowledge_chunks_document_id ON knowledge_chunks (document_id);

-- Section navigation
CREATE INDEX idx_knowledge_chunks_section ON knowledge_chunks USING GIN (section_hierarchy);

-- Deduplication lookup
CREATE INDEX idx_knowledge_chunks_content_hash ON knowledge_chunks (content_hash);

-- Submittal/address queries (future)
CREATE INDEX idx_knowledge_chunks_lot ON knowledge_chunks (lot_number) WHERE lot_number IS NOT NULL;
CREATE INDEX idx_knowledge_chunks_address ON knowledge_chunks (address) WHERE address IS NOT NULL;
```

---

## 5. Search Functions

### 5.1 Hybrid Search Function

```sql
CREATE OR REPLACE FUNCTION hybrid_search(
    query_embedding VECTOR(1536),
    query_text TEXT,
    match_count INT DEFAULT 20,
    vector_weight FLOAT DEFAULT 0.7,
    fts_weight FLOAT DEFAULT 0.3,
    filter_document_types TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    document_name TEXT,
    document_type TEXT,
    section_hierarchy TEXT[],
    section_title TEXT,
    page_number INTEGER,
    is_binding BOOLEAN,
    vector_score FLOAT,
    fts_score FLOAT,
    combined_score FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH vector_results AS (
        SELECT 
            kc.id,
            1 - (kc.embedding <=> query_embedding) AS v_score
        FROM knowledge_chunks kc
        WHERE 
            (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
        ORDER BY kc.embedding <=> query_embedding
        LIMIT match_count * 2
    ),
    fts_results AS (
        SELECT 
            kc.id,
            ts_rank_cd(kc.fts_vector, plainto_tsquery('english', query_text)) AS f_score
        FROM knowledge_chunks kc
        WHERE 
            kc.fts_vector @@ plainto_tsquery('english', query_text)
            AND (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
        ORDER BY f_score DESC
        LIMIT match_count * 2
    ),
    combined AS (
        SELECT 
            COALESCE(vr.id, fr.id) AS chunk_id,
            COALESCE(vr.v_score, 0) AS vec_score,
            COALESCE(fr.f_score, 0) AS full_score
        FROM vector_results vr
        FULL OUTER JOIN fts_results fr ON vr.id = fr.id
    )
    SELECT 
        kc.id,
        kc.content,
        kc.document_name,
        kc.document_type,
        kc.section_hierarchy,
        kc.section_title,
        kc.page_number,
        kc.is_binding,
        c.vec_score AS vector_score,
        c.full_score AS fts_score,
        (c.vec_score * vector_weight + c.full_score * fts_weight) AS combined_score
    FROM combined c
    JOIN knowledge_chunks kc ON kc.id = c.chunk_id
    ORDER BY combined_score DESC
    LIMIT match_count;
END;
$$;
```

### 5.2 Vector-Only Search Function

```sql
CREATE OR REPLACE FUNCTION vector_search(
    query_embedding VECTOR(1536),
    match_count INT DEFAULT 10,
    filter_document_types TEXT[] DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    content TEXT,
    document_name TEXT,
    document_type TEXT,
    section_hierarchy TEXT[],
    section_title TEXT,
    page_number INTEGER,
    is_binding BOOLEAN,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        kc.id,
        kc.content,
        kc.document_name,
        kc.document_type,
        kc.section_hierarchy,
        kc.section_title,
        kc.page_number,
        kc.is_binding,
        1 - (kc.embedding <=> query_embedding) AS similarity
    FROM knowledge_chunks kc
    WHERE 
        (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
```

---

## 6. Supporting Tables

### 6.1 Documents Registry

```sql
CREATE TABLE documents (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,
    document_type       TEXT NOT NULL,
    file_path           TEXT,           -- Path in Supabase Storage
    file_hash           TEXT,           -- SHA-256 of source file
    version             TEXT,
    effective_date      DATE,
    total_pages         INTEGER,
    total_chunks        INTEGER,
    ingested_at         TIMESTAMPTZ DEFAULT NOW(),
    status              TEXT DEFAULT 'active',
    
    CONSTRAINT valid_status CHECK (status IN ('active', 'superseded', 'archived'))
);
```

### 6.2 Ingestion Batches (Audit)

```sql
CREATE TABLE ingestion_batches (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    started_at          TIMESTAMPTZ DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    document_id         UUID REFERENCES documents(id),
    chunks_created      INTEGER DEFAULT 0,
    chunks_updated      INTEGER DEFAULT 0,
    chunks_deleted      INTEGER DEFAULT 0,
    status              TEXT DEFAULT 'running',
    error_message       TEXT,
    
    CONSTRAINT valid_batch_status CHECK (status IN ('running', 'completed', 'failed'))
);
```

### 6.3 Query Audit Log (Optional)

```sql
CREATE TABLE query_log (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text          TEXT NOT NULL,
    query_embedding     VECTOR(1536),
    retrieved_chunk_ids UUID[],
    final_chunk_ids     UUID[],         -- After reranking
    response_text       TEXT,
    confidence_level    TEXT,
    latency_ms          INTEGER,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 7. Storage Bucket

### 7.1 Bucket Configuration

```sql
-- Create storage bucket for source documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('arc-documents', 'arc-documents', false);

-- Allow authenticated access (service role)
CREATE POLICY "Service role access" ON storage.objects
    FOR ALL
    USING (bucket_id = 'arc-documents')
    WITH CHECK (bucket_id = 'arc-documents');
```

### 7.2 File Organization

```
arc-documents/
├── design-guidelines/
│   ├── 2025-02-18_arc_guidelines_v1.pdf
│   └── ...
├── ccrs/
│   ├── 2019-12-04_declaration_ccrs.pdf
│   └── amendments/
│       └── ...
├── rules-regulations/
│   └── rules_and_regulations.pdf
├── submittals/          (future)
│   └── {lot_number}/
│       └── {date}_{type}.pdf
└── response-letters/    (future)
    └── {lot_number}/
        └── {date}_response.pdf
```

---

## 8. Row-Level Security (RLS)

### 8.1 Security Policy

```sql
-- Enable RLS
ALTER TABLE knowledge_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Service role has full access (for n8n)
CREATE POLICY "Service role full access" ON knowledge_chunks
    FOR ALL
    USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access" ON documents
    FOR ALL
    USING (auth.role() = 'service_role');

-- Anon role can read (if needed for direct queries)
CREATE POLICY "Anon read access" ON knowledge_chunks
    FOR SELECT
    USING (auth.role() = 'anon');
```

---

## 9. Data Migration Strategy

### 9.1 Initial Ingestion

1. Upload source PDFs to Storage bucket
2. Extract text with structure preservation
3. Chunk using section-aware strategy
4. Generate embeddings via OpenAI
5. Insert chunks with full metadata
6. Verify chunk count and coverage

### 9.2 Re-Embedding Procedure

When changing embedding models:

```sql
-- 1. Add new embedding column
ALTER TABLE knowledge_chunks ADD COLUMN embedding_new VECTOR(1536);

-- 2. Populate new embeddings (via n8n workflow)
-- 3. Verify quality

-- 4. Swap columns
ALTER TABLE knowledge_chunks DROP COLUMN embedding;
ALTER TABLE knowledge_chunks RENAME COLUMN embedding_new TO embedding;

-- 5. Rebuild index
DROP INDEX idx_knowledge_chunks_embedding;
CREATE INDEX idx_knowledge_chunks_embedding ON knowledge_chunks 
USING hnsw (embedding vector_cosine_ops);
```

### 9.3 Adding New Document Types

1. Add to `document_type` CHECK constraint if needed
2. Create document record in `documents` table
3. Run ingestion workflow
4. Verify retrieval quality with test queries

---

## 10. Sample Queries

### 10.1 Hybrid Search Example

```sql
-- Example: Search for fence requirements
SELECT * FROM hybrid_search(
    '[0.123, 0.456, ...]'::vector(1536),  -- Query embedding
    'fence height requirements',            -- Query text
    20,                                     -- Match count
    0.7,                                    -- Vector weight
    0.3,                                    -- FTS weight
    ARRAY['design_guidelines', 'ccr']       -- Document types
);
```

### 10.2 Get Chunk with Context

```sql
-- Get a chunk and its neighbors for context
WITH target AS (
    SELECT document_id, chunk_index
    FROM knowledge_chunks
    WHERE id = 'target-uuid-here'
)
SELECT *
FROM knowledge_chunks
WHERE document_id = (SELECT document_id FROM target)
  AND chunk_index BETWEEN 
      (SELECT chunk_index FROM target) - 1 
      AND (SELECT chunk_index FROM target) + 1
ORDER BY chunk_index;
```

### 10.3 Document Coverage Report

```sql
-- Check chunk distribution by document
SELECT 
    document_name,
    document_type,
    COUNT(*) as chunk_count,
    MIN(page_number) as first_page,
    MAX(page_number) as last_page,
    SUM(token_count) as total_tokens
FROM knowledge_chunks
GROUP BY document_name, document_type
ORDER BY document_type, document_name;
```

---

## 11. Future Expansion

### 11.1 Planned Enhancements

| Feature | Schema Change | Timeline |
|---------|---------------|----------|
| Submittal tracking | Populate lot_number, address, submittal_date | Phase 2 |
| Decision precedent | Populate decision field | Phase 2 |
| Multi-version support | Use superseded_by, effective_date | Phase 3 |
| Conversation memory | New conversations table | Phase 3 |

### 11.2 Schema Evolution Rules

1. **Additive changes** (new columns) — No migration needed
2. **New document types** — Update CHECK constraint
3. **Breaking changes** — Require migration plan document

---

## 12. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-31 | AI Agent | Initial schema specification |

