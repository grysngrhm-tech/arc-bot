# Discovery West Overlay Zone - Upload Instructions

## Overview
This file contains the SQL to add the Discovery West Master Planned Development code (City of Bend Development Code Article XIX) to the ARC Bot knowledge base.

- **Source:** https://bend.municipal.codes/BDC/2.7_ArtXIX
- **Chunks:** 12 total
- **Document Type:** `city_code` (legally binding)

---

## Step 1: Run the SQL in Supabase

1. Open **Supabase Dashboard** → SQL Editor
2. Copy the entire contents of `004_dw_overlay_zone.sql`
3. Execute the SQL

This will:
- Create the document record
- Insert 12 chunks (without embeddings)

---

## Step 2: Generate Embeddings via n8n

Since the chunks don't have embeddings yet, you need to generate them.

### Option A: Use Existing Ingestion Workflow (Recommended)

The ingestion workflow already has an embedding generation loop. However, these chunks are already inserted without embeddings. You'll need a small SQL query + manual embedding:

1. **Get chunks without embeddings:**
```sql
SELECT id, content
FROM knowledge_chunks
WHERE document_id = (
  SELECT id FROM documents 
  WHERE document_name = 'City of Bend Development Code - Discovery West'
)
AND embedding IS NULL;
```

2. **For each chunk, call OpenAI API** to generate embedding and update:
```sql
UPDATE knowledge_chunks
SET embedding = '[... 1536 dimension vector ...]'::vector
WHERE id = 'chunk-uuid-here';
```

### Option B: Create a Quick n8n Workflow

1. **Create new workflow** with these nodes:

```
Manual Trigger
    │
    ▼
Get Chunks Without Embeddings (Supabase)
    - SELECT id, content FROM knowledge_chunks WHERE embedding IS NULL
    │
    ▼
Loop Over Items
    │
    ├── Generate Embedding (HTTP Request)
    │       POST https://api.openai.com/v1/embeddings
    │       Body: { "model": "text-embedding-3-small", "input": "{{ $json.content }}" }
    │
    ├── Update Chunk (Supabase)
    │       UPDATE knowledge_chunks SET embedding = '{{ $json.data[0].embedding }}'
    │       WHERE id = '{{ $('Get Chunks').item.json.id }}'
    │
    └── Next Item
```

2. Run the workflow once

### Option C: Batch SQL with Generated Embeddings

If you have the OpenAI API, you can generate embeddings externally and paste them into UPDATE statements.

---

## Step 3: Verify

After generating embeddings, run this verification query:

```sql
SELECT 
    kc.chunk_index,
    kc.section_title,
    CASE WHEN kc.embedding IS NOT NULL THEN '✅' ELSE '❌' END as has_embedding,
    LENGTH(kc.content) as content_length
FROM knowledge_chunks kc
JOIN documents d ON kc.document_id = d.id
WHERE d.document_name = 'City of Bend Development Code - Discovery West'
ORDER BY kc.chunk_index;
```

Expected output: 12 rows, all with ✅ in the `has_embedding` column.

---

## Step 4: Test in ARC Bot

Try these queries:
- "What are the Discovery West districts?"
- "What is the purpose of the Residential Mixed-Use District?"
- "What are the special street standards in Discovery West?"
- "Can I have a live/work townhome in Discovery West?"
- "What is cluster housing in Discovery West?"

---

## Chunk Summary

| # | Section | Content Focus |
|---|---------|---------------|
| 1 | 2.7.3700 | Introduction |
| 2 | 2.7.3710 | Purpose (Goals A-H) |
| 3 | 2.7.3720 | Applicability |
| 4 | 2.7.3730 | Districts + Definitions |
| 5 | 2.7.3740 | Review Procedures |
| 6 | 2.7.3750 | Large Lot Residential District |
| 7 | 2.7.3760 | Standard Lot Residential District |
| 8 | 2.7.3770 Part 1 | RMUD Uses & Standards |
| 9 | 2.7.3770 Part 2 | Live/Work Townhomes |
| 10 | 2.7.3770 Part 3 | Cluster Housing |
| 11 | 2.7.3780 | Commercial/Mixed Employment |
| 12 | 2.7.3790 | Special Street Standards |

