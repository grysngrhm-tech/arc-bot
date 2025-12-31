-- =============================================================================
-- ARC Bot Database Schema
-- Version: 1.0
-- Project: wdouifomlipmlsksczsv
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/wdouifomlipmlsksczsv/sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. EXTENSIONS
-- -----------------------------------------------------------------------------

-- Enable pgvector for embedding storage and similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable pg_trgm for fuzzy text matching (optional enhancement)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- -----------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS
-- -----------------------------------------------------------------------------

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 3. DOCUMENTS TABLE (Registry of source documents)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS documents (
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
    
    CONSTRAINT documents_valid_type CHECK (
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
    CONSTRAINT documents_valid_status CHECK (
        status IN ('active', 'superseded', 'archived')
    )
);

-- -----------------------------------------------------------------------------
-- 4. INGESTION BATCHES TABLE (Audit trail)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingestion_batches (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    started_at          TIMESTAMPTZ DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    document_id         UUID REFERENCES documents(id),
    chunks_created      INTEGER DEFAULT 0,
    chunks_updated      INTEGER DEFAULT 0,
    chunks_deleted      INTEGER DEFAULT 0,
    status              TEXT DEFAULT 'running',
    error_message       TEXT,
    
    CONSTRAINT batches_valid_status CHECK (
        status IN ('running', 'completed', 'failed')
    )
);

-- -----------------------------------------------------------------------------
-- 5. KNOWLEDGE CHUNKS TABLE (Primary data store)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS knowledge_chunks (
    -- Primary identification
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Content
    content             TEXT NOT NULL,
    content_hash        TEXT NOT NULL,  -- SHA-256 for deduplication
    
    -- Embedding (1536 dimensions - text-embedding-3-large with dimensions=1536)
    -- Note: Supabase HNSW index limit is 2000 dimensions
    embedding           VECTOR(1536),
    
    -- Full-text search vector (auto-generated)
    fts_vector          TSVECTOR GENERATED ALWAYS AS (
                            to_tsvector('english', content)
                        ) STORED,
    
    -- Document identification
    document_id         UUID NOT NULL REFERENCES documents(id),
    document_name       TEXT NOT NULL,
    document_type       TEXT NOT NULL,
    
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
    ingestion_batch_id  UUID REFERENCES ingestion_batches(id),
    
    -- Constraints
    CONSTRAINT chunks_valid_document_type CHECK (
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
    CONSTRAINT chunks_valid_decision CHECK (
        decision IS NULL OR decision IN ('approved', 'denied', 'conditional', 'withdrawn')
    )
);

-- Trigger for auto-updating updated_at
CREATE TRIGGER knowledge_chunks_updated_at
    BEFORE UPDATE ON knowledge_chunks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- -----------------------------------------------------------------------------
-- 6. QUERY LOG TABLE (Optional - for analytics)
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS query_log (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query_text          TEXT NOT NULL,
    retrieved_chunk_ids UUID[],
    final_chunk_ids     UUID[],         -- After reranking
    response_text       TEXT,
    confidence_level    TEXT,
    latency_ms          INTEGER,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 7. INDEXES
-- -----------------------------------------------------------------------------

-- HNSW index for fast approximate nearest neighbor search (vector)
-- Note: This may take a moment to create on large datasets
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding 
ON knowledge_chunks 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,              -- Max connections per node
    ef_construction = 64 -- Build-time search depth
);

-- GIN index for full-text search
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_fts 
ON knowledge_chunks 
USING GIN (fts_vector);

-- Document filtering indexes
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_document_type 
ON knowledge_chunks (document_type);

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_document_id 
ON knowledge_chunks (document_id);

-- Section navigation (for GIN array search)
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_section 
ON knowledge_chunks USING GIN (section_hierarchy);

-- Deduplication lookup
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_content_hash 
ON knowledge_chunks (content_hash);

-- Submittal/address queries (future use)
CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_lot 
ON knowledge_chunks (lot_number) 
WHERE lot_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_address 
ON knowledge_chunks (address) 
WHERE address IS NOT NULL;

-- Documents table indexes
CREATE INDEX IF NOT EXISTS idx_documents_type 
ON documents (document_type);

CREATE INDEX IF NOT EXISTS idx_documents_status 
ON documents (status);

-- -----------------------------------------------------------------------------
-- 8. SEARCH FUNCTIONS
-- -----------------------------------------------------------------------------

-- Hybrid Search Function (Vector + FTS combined)
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
            kc.embedding IS NOT NULL
            AND (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
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
        ORDER BY ts_rank_cd(kc.fts_vector, plainto_tsquery('english', query_text)) DESC
        LIMIT match_count * 2
    ),
    combined AS (
        SELECT 
            COALESCE(vr.id, fr.id) AS chunk_id,
            COALESCE(vr.v_score, 0.0) AS vec_score,
            -- Normalize FTS score to 0-1 range (roughly)
            LEAST(1.0, COALESCE(fr.f_score, 0.0) * 10) AS full_score
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
        c.vec_score::FLOAT AS vector_score,
        c.full_score::FLOAT AS fts_score,
        (c.vec_score * vector_weight + c.full_score * fts_weight)::FLOAT AS combined_score
    FROM combined c
    JOIN knowledge_chunks kc ON kc.id = c.chunk_id
    ORDER BY (c.vec_score * vector_weight + c.full_score * fts_weight) DESC
    LIMIT match_count;
END;
$$;

-- Vector-Only Search Function (simpler, for fallback)
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
        (1 - (kc.embedding <=> query_embedding))::FLOAT AS similarity
    FROM knowledge_chunks kc
    WHERE 
        kc.embedding IS NOT NULL
        AND (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Full-Text Search Only Function (for keyword-heavy queries)
CREATE OR REPLACE FUNCTION fts_search(
    query_text TEXT,
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
    fts_rank FLOAT
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
        ts_rank_cd(kc.fts_vector, plainto_tsquery('english', query_text))::FLOAT AS fts_rank
    FROM knowledge_chunks kc
    WHERE 
        kc.fts_vector @@ plainto_tsquery('english', query_text)
        AND (filter_document_types IS NULL OR kc.document_type = ANY(filter_document_types))
    ORDER BY ts_rank_cd(kc.fts_vector, plainto_tsquery('english', query_text)) DESC
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. ROW-LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE knowledge_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingestion_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE query_log ENABLE ROW LEVEL SECURITY;

-- Service role has full access (for n8n backend)
CREATE POLICY "Service role full access on knowledge_chunks" 
ON knowledge_chunks FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role full access on documents" 
ON documents FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role full access on ingestion_batches" 
ON ingestion_batches FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role full access on query_log" 
ON query_log FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Anon role can read chunks and documents (for potential direct API access)
CREATE POLICY "Anon read access on knowledge_chunks" 
ON knowledge_chunks FOR SELECT 
USING (auth.role() = 'anon');

CREATE POLICY "Anon read access on documents" 
ON documents FOR SELECT 
USING (auth.role() = 'anon');

-- -----------------------------------------------------------------------------
-- 10. STORAGE BUCKET (Run separately in Storage section or via API)
-- -----------------------------------------------------------------------------

-- Note: Storage bucket creation is typically done via the Supabase Dashboard
-- or Storage API, not SQL. Here's the configuration for reference:
--
-- Bucket Name: arc-documents
-- Public: false (private)
-- File size limit: 50MB
-- Allowed MIME types: application/pdf, application/msword, 
--                     application/vnd.openxmlformats-officedocument.wordprocessingml.document

-- If using SQL (requires appropriate permissions):
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES (
--     'arc-documents', 
--     'arc-documents', 
--     false,
--     52428800,  -- 50MB
--     ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
-- );

-- -----------------------------------------------------------------------------
-- 11. VERIFICATION QUERIES
-- -----------------------------------------------------------------------------

-- Run these after setup to verify everything is in place:

-- Check extensions
-- SELECT * FROM pg_extension WHERE extname IN ('vector', 'pg_trgm');

-- Check tables
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check indexes
-- SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public';

-- Check functions
-- SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public';

-- Test vector dimension (should be 1536)
-- SELECT atttypmod FROM pg_attribute 
-- WHERE attrelid = 'knowledge_chunks'::regclass AND attname = 'embedding';

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================

