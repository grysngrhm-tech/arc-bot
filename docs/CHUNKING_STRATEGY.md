# ARC Bot (Architectural Review Console) — Chunking Strategy

**Version:** 1.2  
**Last Updated:** December 31, 2025  
**Status:** Canonical Reference

---

## 1. Overview

This document specifies how source documents are processed into chunks for the knowledge base. Chunking quality directly impacts retrieval accuracy — poor chunks create poor answers.

### 1.1 Design Principles

1. **Structure-aware** — Respect document hierarchy (chapters, sections, subsections)
2. **Semantically complete** — Each chunk should be meaningful standalone
3. **Metadata-rich** — Preserve location, context, and provenance
4. **Consistent** — Apply same rules across all document types
5. **Retrievable** — Optimize for both vector and keyword search

### 1.2 Chunking Anti-Patterns

**AVOID:**
- Fixed character/token splits that break mid-sentence
- Ignoring document structure (headers, sections)
- Losing page number information
- Creating chunks too small to be meaningful
- Creating chunks too large for embedding quality

---

## 2. Document Types and Processing

### 2.1 Processing Pipeline

```
Source Document (PDF/DOC)
         │
         ▼
┌─────────────────────────────────┐
│     TEXT EXTRACTION             │
│  • Extract raw text             │
│  • Preserve structure markers   │
│  • Map to page numbers          │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│     STRUCTURE PARSING           │
│  • Identify headers/sections    │
│  • Build hierarchy tree         │
│  • Extract tables/lists         │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│     SECTION CHUNKING            │
│  • Split at section boundaries  │
│  • Respect size limits          │
│  • Handle long sections         │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│     METADATA ATTACHMENT         │
│  • Document info                │
│  • Section hierarchy            │
│  • Page numbers                 │
│  • Content hash                 │
└─────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│     EMBEDDING GENERATION        │
│  • OpenAI text-embedding-3-large│
│  • 1536 dimensions              │
└─────────────────────────────────┘
         │
         ▼
Knowledge Base (Supabase)
```

### 2.2 Document-Specific Handling

| Document Type | Format | Special Handling |
|---------------|--------|------------------|
| Design Guidelines | PDF | Structure-heavy, numbered sections |
| CC&Rs | DOC/PDF | Legal structure (Articles, Sections) |
| Rules & Regulations | PDF | Mixed structure |
| Application Forms | PDF | Form fields, instructions |
| Response Letters | PDF | Letter format, decision extraction |

---

## 3. Text Extraction

### 3.1 PDF Extraction

**Tool:** PDF text extraction library (e.g., pdf-parse, pdfplumber)

**Requirements:**
- Preserve reading order
- Maintain paragraph boundaries
- Extract page numbers
- Handle multi-column layouts
- Preserve tables as structured text

**Example Output:**
```json
{
  "pages": [
    {
      "pageNumber": 42,
      "text": "4.2 Fencing\n\nAll fencing must comply with...",
      "tables": [...]
    }
  ]
}
```

### 3.2 DOC Extraction

**Tool:** Document parser (e.g., mammoth for .docx)

**Requirements:**
- Convert to clean text/HTML
- Preserve heading hierarchy
- Maintain list formatting
- Extract embedded images descriptions

### 3.3 Structure Markers

Detect and preserve:
- Chapter headers (e.g., "CHAPTER 4: EXTERIOR ELEMENTS")
- Section headers (e.g., "4.2 Fencing")
- Subsection headers (e.g., "4.2.1 Materials")
- List items (numbered and bulleted)
- Table boundaries

---

## 4. Structure Parsing

### 4.1 TOC-Based Section Detection (Implemented)

The implemented approach uses the document's **Table of Contents** for reliable section detection:

```
flowchart LR
    A[GPT extracts TOC] --> B[Find section titles in text]
    B --> C[Build char-position boundaries]
    C --> D[Match chunks by char_start]
    D --> E[Assign section_title & hierarchy]
```

**Why TOC-based?**
- Section titles appear **exactly** as written in TOC
- Avoids regex pattern fragility across document styles
- Natural hierarchy already defined in TOC
- Works across different document formats

**GPT Prompt for TOC Extraction:**
```
You are a document structure analyzer. Extract the Table of Contents from this document.
Return ONLY a valid JSON array with this structure:
[
  {
    "title": "Exact Section Title",
    "hierarchy": ["Parent Section", "Child Section", "Title"],
    "level": 1
  }
]
```

### 4.2 Character-Position Boundary Building

**Critical Implementation Detail:**
Section titles appear **twice** in documents with a TOC:
1. In the Table of Contents (beginning of document)
2. In the actual content section

The `buildSectionBoundaries()` function must search **AFTER the TOC ends**:

```javascript
function buildSectionBoundaries(fullText, sections) {
  // Find where TOC ends (after last TOC entry + buffer)
  const tocEndPos = findTocEndPosition(fullText, sections);
  
  for (const section of sections) {
    // Search starting AFTER TOC
    const searchText = fullText.substring(tocEndPos);
    const pos = searchText.indexOf(section.title);
    
    if (pos >= 0) {
      boundaries.push({
        title: section.title,
        hierarchy: section.hierarchy,
        char_start: tocEndPos + pos  // Offset by TOC end
      });
    }
  }
  
  // Sort by position and calculate end boundaries
  boundaries.sort((a, b) => a.char_start - b.char_start);
  // ...
}
```

### 4.3 Section Matching for Chunks

```javascript
function findSectionByPosition(charStart, boundaries) {
  // Binary search or linear scan from end
  for (let i = boundaries.length - 1; i >= 0; i--) {
    if (charStart >= boundaries[i].char_start) {
      return boundaries[i];
    }
  }
  return null;
}
```

### 4.4 Legacy: Pattern-Based Detection (Reference Only)

For documents without a TOC, pattern matching can be used as fallback:

```javascript
const headerPatterns = [
  // Chapter headers
  { pattern: /^CHAPTER\s+(\d+)[:.]?\s*(.+)$/im, level: 1 },
  // Section headers (e.g., "4.2 Fencing")
  { pattern: /^(\d+\.\d+)\s+(.+)$/m, level: 2 },
  // Subsection headers (e.g., "4.2.1 Materials")
  { pattern: /^(\d+\.\d+\.\d+)\s+(.+)$/m, level: 3 },
  // All-caps headers
  { pattern: /^([A-Z][A-Z\s]{3,})$/m, level: 2 }
];
```

---

## 5. Chunking Rules

### 5.1 Size Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Target chunk size | 500-800 tokens | Balance context and embedding quality |
| Minimum chunk size | 100 tokens | Avoid fragments |
| Maximum chunk size | 1200 tokens | Embedding quality degrades beyond this |
| Overlap | 50-100 tokens | Maintain continuity |

### 5.2 Primary Split: Section Boundaries

**Rule:** Always split at section boundaries first.

```javascript
function chunkBySection(section) {
  const tokens = countTokens(section.content);
  
  // If section fits, keep as single chunk
  if (tokens <= 800) {
    return [createChunk(section)];
  }
  
  // If section has subsections, recurse
  if (section.children.length > 0) {
    return section.children.flatMap(child => chunkBySection(child));
  }
  
  // Large section with no subsections: split by paragraph
  return splitLargeSectionByParagraph(section);
}
```

### 5.3 Secondary Split: Paragraphs

For sections exceeding maximum size:

```javascript
function splitLargeSectionByParagraph(section) {
  const paragraphs = section.content.split(/\n\n+/);
  const chunks = [];
  let currentChunk = {
    content: '',
    tokens: 0
  };
  
  for (const para of paragraphs) {
    const paraTokens = countTokens(para);
    
    if (currentChunk.tokens + paraTokens > 800) {
      // Save current chunk if not empty
      if (currentChunk.tokens >= 100) {
        chunks.push(finalizeChunk(currentChunk, section));
      }
      currentChunk = { content: para, tokens: paraTokens };
    } else {
      currentChunk.content += '\n\n' + para;
      currentChunk.tokens += paraTokens;
    }
  }
  
  // Don't forget last chunk
  if (currentChunk.tokens >= 100) {
    chunks.push(finalizeChunk(currentChunk, section));
  }
  
  return chunks;
}
```

### 5.4 Tertiary Split: Sentences

For very long paragraphs (rare):

```javascript
function splitLargeParagraph(paragraph, maxTokens = 800) {
  const sentences = paragraph.match(/[^.!?]+[.!?]+/g) || [paragraph];
  // Group sentences into chunks
  // ...
}
```

### 5.5 Overlap Strategy

Add context overlap between adjacent chunks:

```javascript
function addOverlap(chunks, overlapTokens = 75) {
  return chunks.map((chunk, index) => {
    let prefix = '';
    let suffix = '';
    
    // Add end of previous chunk as prefix
    if (index > 0) {
      prefix = getLastNTokens(chunks[index - 1].content, overlapTokens);
      prefix = `[...] ${prefix}\n\n---\n\n`;
    }
    
    // Add start of next chunk as suffix (optional)
    // Usually not needed if chunks are well-formed
    
    return {
      ...chunk,
      content: prefix + chunk.content
    };
  });
}
```

---

## 6. Metadata Extraction

### 6.1 Required Metadata

Every chunk must have:

| Field | Source | Example |
|-------|--------|---------|
| document_id | Generated UUID per document | "abc-123-..." |
| document_name | Document title | "Architectural Design Guidelines" |
| document_type | Classification | "design_guidelines" |
| section_hierarchy | Parsed headers | ["Chapter 4", "Section 4.2", "Fencing"] |
| section_title | Immediate header | "Fencing" |
| page_number | PDF extraction | 42 |
| chunk_index | Sequential order | 127 |
| char_start | Character offset | 45230 |
| char_end | Character offset | 46891 |
| token_count | Calculated | 523 |
| content_hash | SHA-256 | "a1b2c3..." |

### 6.2 Conditional Metadata

For specific document types:

**Response Letters:**
```json
{
  "lot_number": "123",
  "address": "456 Example St",
  "submittal_date": "2024-06-15",
  "decision": "approved",
  "conditions": ["Must use approved color palette", "..."]
}
```

**Amendments:**
```json
{
  "effective_date": "2024-01-01",
  "supersedes": ["uuid-of-old-section"]
}
```

### 6.3 Metadata Extraction Functions

```javascript
function extractMetadata(chunk, document, section) {
  return {
    id: generateUUID(),
    document_id: document.id,
    document_name: document.name,
    document_type: document.type,
    section_hierarchy: buildHierarchy(section),
    section_title: section.title,
    page_number: section.pageStart,
    chunk_index: chunk.index,
    char_start: chunk.charStart,
    char_end: chunk.charEnd,
    token_count: countTokens(chunk.content),
    content_hash: sha256(chunk.content),
    is_binding: document.type !== 'response_letter',
    created_at: new Date().toISOString()
  };
}

function buildHierarchy(section) {
  const hierarchy = [];
  let current = section;
  while (current) {
    hierarchy.unshift(current.title);
    current = current.parent;
  }
  return hierarchy;
}
```

---

## 7. Special Content Handling

### 7.1 Tables

Tables should be preserved as structured text:

```
**Original Table:**
| Material | Allowed | Notes |
|----------|---------|-------|
| Wood     | Yes     | Cedar, redwood preferred |
| Vinyl    | Yes     | Must match home color |
| Chain link | No    | Not permitted |

**Chunk Content:**
Fencing Materials Table:
- Wood: Allowed (Cedar, redwood preferred)
- Vinyl: Allowed (Must match home color)
- Chain link: Not permitted
```

### 7.2 Lists

Preserve list structure:

```
**Requirements for fence approval:**
1. Submit site plan showing fence location
2. Provide material specifications
3. Include color samples
4. Show dimensions and heights
```

### 7.3 Images and Diagrams

For images that contain important information:

```
[DIAGRAM: Site setback requirements showing minimum distances from property lines. 
Front: 25 feet, Side: 5 feet, Rear: 10 feet]
```

### 7.4 Cross-References

Preserve references to other sections:

```
See Section 4.2 for additional fencing requirements.
(Refer to Exhibit A for application form)
```

---

## 8. Quality Validation

### 8.1 Chunk Validation Rules

```javascript
function validateChunk(chunk) {
  const errors = [];
  
  // Size validation
  if (chunk.token_count < 100) {
    errors.push('Chunk too small (< 100 tokens)');
  }
  if (chunk.token_count > 1200) {
    errors.push('Chunk too large (> 1200 tokens)');
  }
  
  // Content validation
  if (!chunk.content.trim()) {
    errors.push('Empty content');
  }
  if (chunk.content.match(/^\s*\.\.\.\s*$/)) {
    errors.push('Content is just ellipsis');
  }
  
  // Metadata validation
  if (!chunk.document_name) {
    errors.push('Missing document_name');
  }
  if (!chunk.section_hierarchy || chunk.section_hierarchy.length === 0) {
    errors.push('Missing section_hierarchy');
  }
  
  // Completeness check
  if (chunk.content.match(/^[a-z]/) && !chunk.content.startsWith('[...]')) {
    errors.push('Starts mid-sentence without overlap marker');
  }
  
  return errors;
}
```

### 8.2 Document Coverage Report

After chunking, verify:

```sql
-- Check chunk distribution
SELECT 
  document_name,
  COUNT(*) as chunk_count,
  MIN(page_number) as first_page,
  MAX(page_number) as last_page,
  SUM(token_count) as total_tokens,
  AVG(token_count) as avg_chunk_size
FROM knowledge_chunks
GROUP BY document_name;
```

### 8.3 Gap Detection

```javascript
function detectGaps(chunks, document) {
  const gaps = [];
  
  // Check for missing pages
  const pages = new Set(chunks.map(c => c.page_number));
  for (let p = 1; p <= document.totalPages; p++) {
    if (!pages.has(p)) {
      gaps.push({ type: 'missing_page', page: p });
    }
  }
  
  // Check for missing sections (from TOC)
  const sections = new Set(chunks.flatMap(c => c.section_hierarchy));
  for (const tocSection of document.tableOfContents) {
    if (!sections.has(tocSection)) {
      gaps.push({ type: 'missing_section', section: tocSection });
    }
  }
  
  return gaps;
}
```

---

## 9. Embedding Generation

### 9.1 Embedding Configuration

| Parameter | Value |
|-----------|-------|
| Model | text-embedding-3-large |
| Dimensions | 1536 |
| Batch size | 100 chunks |
| Rate limit | 3000 RPM |

### 9.2 Embedding Process

```javascript
async function embedChunks(chunks, batchSize = 100) {
  const results = [];
  
  for (let i = 0; i < chunks.length; i += batchSize) {
    const batch = chunks.slice(i, i + batchSize);
    const texts = batch.map(c => c.content);
    
    const response = await openai.embeddings.create({
      model: 'text-embedding-3-large',
      input: texts,
      dimensions: 1536
    });
    
    for (let j = 0; j < batch.length; j++) {
      results.push({
        ...batch[j],
        embedding: response.data[j].embedding
      });
    }
    
    // Rate limiting
    await sleep(100);
  }
  
  return results;
}
```

### 9.3 Embedding Quality Check

After embedding, spot-check with similarity queries:

```javascript
async function testEmbeddingQuality(chunks) {
  const testQueries = [
    { query: 'fence height limits', expected: 'fencing' },
    { query: 'roof materials allowed', expected: 'roofing' },
    { query: 'paint colors approved', expected: 'color' }
  ];
  
  for (const test of testQueries) {
    const results = await vectorSearch(test.query, 5);
    const topSection = results[0].section_title.toLowerCase();
    
    if (!topSection.includes(test.expected)) {
      console.warn(`Quality issue: "${test.query}" returned "${topSection}", expected "${test.expected}"`);
    }
  }
}
```

---

## 10. Ingestion Workflow

### 10.1 n8n Workflow Structure

```
[Manual Trigger / Webhook]
         │
         ▼
[Read Document from Storage]
         │
         ▼
[Extract Text & Structure]
         │
         ▼
[Parse Headers & Build Hierarchy]
         │
         ▼
[Chunk by Section]
         │
         ▼
[Validate Chunks]
         │
         ▼
[Generate Embeddings (Batch)]
         │
         ▼
[Upsert to Supabase]
         │
         ▼
[Generate Coverage Report]
```

### 10.2 Idempotency

Use content_hash for deduplication:

```sql
-- Check if chunk already exists
SELECT id FROM knowledge_chunks 
WHERE content_hash = $1 AND document_id = $2;

-- If exists, update; if not, insert
INSERT INTO knowledge_chunks (...)
ON CONFLICT (content_hash, document_id) 
DO UPDATE SET updated_at = NOW(), embedding = EXCLUDED.embedding;
```

### 10.3 Re-Ingestion Process

When documents are updated:

1. Mark old chunks with `superseded_by` or delete
2. Process new document version
3. Re-embed all chunks
4. Verify coverage
5. Log changes in ingestion_batches

---

## 11. Document-Specific Strategies

### 11.1 Architectural Design Guidelines

**Characteristics:**
- Highly structured with numbered sections
- Contains tables and lists
- ~250 pages

**Strategy:**
- Chunk at Section level (e.g., 4.2 Fencing)
- Preserve tables as structured text
- Keep section numbers in hierarchy

### 11.2 CC&Rs Declaration

**Characteristics:**
- Legal document structure (Articles, Sections)
- Dense legal language
- Cross-references common

**Strategy:**
- Chunk at Section level (e.g., Section 7.3)
- Preserve cross-reference text
- Note: is_binding = true for all

### 11.3 Response Letters (Future)

**Characteristics:**
- Letter format
- Contains decisions and conditions
- Address/lot specific

**Strategy:**
- Extract: lot_number, address, date, decision
- Chunk entire letter as single unit (typically short)
- Note: is_binding = false
- Flag as precedent for search boost control

---

## 12. Implementation Status

### 12.1 Deployed Workflow

Document ingestion is implemented as n8n workflow `wonZrB2BxGufGsE9`:

- **Trigger:** Manual
- **Status:** ✅ Complete

### 12.2 Actual Chunk Parameters Used

| Parameter | Documented | Actual | Rationale |
|-----------|------------|--------|-----------|
| Target size | 500-800 tokens | ~600 tokens (2400 chars) | More conservative for safety |
| Maximum size | 1200 tokens | ~1500 tokens (6000 chars) | Safe margin under 8192 API limit |
| Minimum size | 100 tokens | ~25 tokens (100 chars) | Practical minimum |
| Overlap | 50-100 tokens | ~75 tokens (300 chars) | Good continuity |

### 12.3 Splitting Strategy Implemented

The actual chunking uses a fallback cascade:

1. **Double newline split** (`\n\n+`) - Primary for well-formatted text
2. **Single newline split** (`\n`) - Fallback for tightly formatted text
3. **Sentence split** (`(?<=[.!?])\s+`) - For dense paragraphs
4. **Force split by character count** - Last resort for unstructured text

### 12.4 Section Detection Implemented

| Component | Approach |
|-----------|----------|
| Section extraction | GPT-4o parses Table of Contents |
| Position finding | Search for titles AFTER TOC ends |
| Chunk matching | `char_start` within section boundaries |
| Hierarchy tracking | Full parent→child paths from TOC |

**Example Results:**
- 172 sections extracted from Design Guidelines TOC
- Varied section titles across chunks (Fencing, Roofing, Site Design, etc.)
- Hierarchies like `["Residential Architectural Guidelines", "Fencing"]`

### 12.5 Ingestion Results

| Document | Pages | Chunks | Sections | Avg Chunk Size |
|----------|-------|--------|----------|----------------|
| Architectural Design Guidelines | 69 | 124 | 172 | ~1.8 chunks/page |

### 12.6 Lessons Learned

- PDF extractor returns non-string types; always use `String()` conversion
- n8n sandbox lacks `crypto` module; use custom UUID generator
- Large text blocks need multiple split strategies
- Batch size of 1 prevents bulk failures during embedding
- **Section titles appear twice** (TOC and content) - search after TOC ends
- **Character position matching** more reliable than page-based matching

---

## 13. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.2 | 2025-12-31 | AI Agent | Added TOC-based section detection implementation |
| 1.1 | 2025-12-31 | AI Agent | Added implementation status and actual parameters |
| 1.0 | 2025-12-31 | AI Agent | Initial chunking strategy |

