# ARC Bot (Architectural Review Console) — Database Setup

## Status: ✅ COMPLETE

All database components have been deployed and verified.

## Current Data

| Table | Records | Notes |
|-------|---------|-------|
| `documents` | 1 | Architectural Design Guidelines |
| `knowledge_chunks` | 124 | Ingested chunks with embeddings and section metadata |
| `ingestion_batches` | 0 | Audit trail |
| `query_log` | 0 | Analytics |

### Section Metadata

Chunks include accurate section metadata:
- **172 sections** extracted from Table of Contents
- **section_title**: Varied titles (Fencing, Roofing, Site Design, etc.)
- **section_hierarchy**: Full parent→child paths
- **char_start/char_end**: Character positions for citations

## Setup Instructions

### Prerequisites

- Supabase project with pgvector extension enabled
- Service role key for backend access

### Step 1: Run Main Schema

1. Go to your Supabase project SQL Editor
2. Copy the contents of `001_initial_schema.sql`
3. Paste into the SQL Editor
4. Click **Run**

This creates:
- `documents` table (source document registry)
- `knowledge_chunks` table (main data store with embeddings)
- `ingestion_batches` table (audit trail)
- `query_log` table (analytics)
- HNSW index for vector search
- GIN index for full-text search
- `hybrid_search()`, `vector_search()`, `fts_search()` functions
- Row-Level Security policies

### Step 2: Create Storage Bucket

1. Go to your Supabase project SQL Editor
2. Copy the contents of `002_storage_bucket.sql`
3. Paste and run

Or manually:
1. Go to Storage in your Supabase dashboard
2. Click **New bucket**
3. Name: `arc-documents`
4. Public: **OFF** (private)
5. File size limit: 50MB
6. Allowed MIME types: `application/pdf`, `application/msword`

### Step 3: Verify Setup

Run these queries to confirm everything is working:

```sql
-- Check extensions are enabled
SELECT * FROM pg_extension WHERE extname IN ('vector', 'pg_trgm');

-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';

-- Check indexes exist
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename = 'knowledge_chunks';
```

## API Keys

Store these securely in n8n credentials:

| Key Type | Usage |
|----------|-------|
| **Service Role Key** | Backend (n8n) - full access |
| **Anon Key** | Frontend (if needed) - read only |

See `env.example` in the project root for environment variable format.

## Schema Reference

See `docs/DATA_MODEL.md` for complete schema documentation.

## Troubleshooting

### "extension vector does not exist"
The pgvector extension needs to be enabled. It's included in all Supabase projects. Try:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### "permission denied for table"
Make sure you're using the service role key, not the anon key, for write operations.

### Index creation timeout
On large datasets, HNSW index creation can take time. For initial setup with no data, it should be instant.
