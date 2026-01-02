# ARC Bot (Architectural Review Console) — Answer Contract

**Version:** 2.3  
**Last Updated:** January 2, 2026  
**Status:** Canonical Reference

---

## 1. Overview

This document defines the required structure, format, and components of all substantive answers from ARC Bot. This contract ensures consistency, traceability, and user trust.

### 1.1 Design Principles

1. **Scannable** — Users should find the answer quickly
2. **Verifiable** — Every claim has a traceable source
3. **Actionable** — Users know what to do next
4. **Honest** — Confidence reflects actual certainty

---

## 2. Answer Types

### 2.1 Substantive Answer

For questions about requirements, rules, processes, or definitions.

**Required when:**
- User asks about specific requirements
- User asks about allowed/prohibited items
- User asks about processes or procedures
- User asks for clarification on document content

### 2.2 Clarification Request

For ambiguous questions requiring user input.

**Required when:**
- Question has multiple valid interpretations
- Key terms are undefined
- Scope is unclear

### 2.3 Scope Redirect

For questions outside ARC Bot's domain.

**Required when:**
- Question is about legal matters
- Question is about HOA fees/finances
- Question is unrelated to architectural guidelines

### 2.4 No-Results Response

When retrieval finds no relevant content.

**Required when:**
- Hybrid search returns no results
- All results have relevance < 0.3
- Topic is not covered in documents

---

## 3. Substantive Answer Format

### 3.1 Response Structure Overview

ARC Bot v2.0 uses a **structured JSON response** that the frontend renders into an interactive UI. The response separates the answer text from sources and confidence metadata.

### 3.2 JSON Response Format

```json
{
  "answer": "Comprehensive answer text without section headers...",
  "sources": [
    {
      "document_name": "Architectural Design Guidelines",
      "section_title": "Section 4.2 - Fencing",
      "section_hierarchy": ["Chapter 4", "Section 4.2"],
      "page_number": 42,
      "is_binding": true,
      "requirements": [
        "Maximum height: 6 feet (rear yard)",
        "Allowed materials: Wood, vinyl, wrought iron, or masonry"
      ],
      "content": "Full text from the source document chunk..."
    }
  ],
  "confidence": {
    "level": "High",
    "explanation": "Multiple sections directly address this topic with clear requirements."
  }
}
```

### 3.3 Component Details

#### Answer

**Purpose:** Give the user a comprehensive, direct answer to their question.

**Guidelines:**
- Focus on directly answering the user's **specific question** — not everything related to the topic
- Be concise: **1-2 short paragraphs maximum**
- Provide helpful context but do NOT list all requirements (sources section handles that)
- Do NOT include section headers like "Short Answer:", "Requirements:", or "Sources:"
- Do NOT include confidence at the end of the text
- Think: "What is the direct answer?" not "What is everything I know about this topic?"
- No hedging words ("perhaps", "maybe", "possibly")

**Good:**
```
Yes, wild strawberries are considered fire-resistant plants. They are specifically listed as approved fire-resistant ground covers in the Architectural Design Guidelines. Fragaria species (wild strawberries) appear on the approved plant list under the ground cover category.
```

**Bad:**
```
**Short Answer:** Based on my search, I found information that may be relevant...

**Requirements:**
- Wild strawberries are listed...

**Confidence:** High — ...
```

#### Sources (with Nested Requirements)

**Purpose:** Group requirements by their source document for traceability.

**Guidelines:**
- Each source should include its specific requirements as an array
- Requirements are extracted from that source only (not duplicated)
- Include `is_binding` to distinguish CC&Rs (legally binding) from guidelines
- The `content` field contains the full source text for user reference

**Structure per source:**
| Field | Type | Description |
|-------|------|-------------|
| `document_name` | string | Name of the source document |
| `section_title` | string | Specific section title |
| `section_hierarchy` | array | Path to the section |
| `page_number` | number | Page reference |
| `is_binding` | boolean | true for CC&Rs, false for guidelines |
| `requirements` | array | Bullet points extracted from this source |
| `content` | string | Full text of the source chunk |

#### Confidence (Metadata Only)

**Purpose:** Signal reliability via UI badge, not in answer text.

**Guidelines:**
- Confidence is provided as separate metadata, NOT in the answer text
- Frontend renders this as a clickable badge showing level (High/Medium/Low)
- User can click badge to see the explanation
- Do NOT write "Confidence: High" in the answer field

**Structure:**
```json
{
  "level": "High",
  "explanation": "Multiple sections directly address this topic with clear requirements."
}
```

### 3.4 Frontend Rendering

The frontend renders the JSON response as:

1. **Header** — "ARC Bot" label + clickable confidence badge + copy button
2. **Answer Section** — Clean prose answer with "Answer" label
3. **Sources & Requirements** — Expandable accordions per source:
   - Source title with page number and authority badge (Binding/Guidance)
   - Requirements bullets from that source
   - Expandable "Show source text" to reveal full content

### 3.5 Authority Badges

Sources are tagged with authority level based on their document type:

| Badge | Documents | Meaning |
|-------|-----------|---------|
| **Binding** | CC&Rs, City of Bend Code | Legally enforceable requirements |
| **ARC Guidance** | Design Guidelines | Enforced by Architectural Review Committee |
| **DWOA Guidance** | Rules & Regulations | Community policies enforced by DWOA |

This helps users understand the weight and enforcement mechanism of each requirement.

---

## 4. Confidence Level Definitions

### 4.1 High Confidence

**Criteria:**
- 2+ directly relevant chunks with relevance score > 0.8
- Clear, unambiguous language in source documents
- No conflicting information found
- Question is well-defined

**User Interpretation:**
The answer is well-supported by official documents. Proceed with reasonable certainty.

**Example Scenario:**
User asks "What is the maximum fence height allowed?"
Sources clearly state "6 feet maximum in rear yards"
→ High confidence

### 4.2 Medium Confidence

**Criteria:**
- 1+ relevant chunk with relevance score 0.6-0.8
- Source language requires some interpretation
- Answer applies generally but specific case may vary
- Some ambiguity in question or sources

**User Interpretation:**
The answer is probably correct but verify with ARC if your situation is unusual.

**Example Scenario:**
User asks "Can I paint my door a different color?"
Sources say "exterior colors must be from approved palette" but don't specifically address doors
→ Medium confidence

### 4.3 Low Confidence

**Criteria:**
- Chunks are tangentially related (score < 0.6)
- Answer requires significant interpretation
- Sources don't directly address the question
- Multiple possible interpretations exist

**User Interpretation:**
This information may be helpful but contact the ARC for a definitive answer.

**Example Scenario:**
User asks about a unique architectural feature not mentioned in guidelines
Best match discusses "architectural compatibility" generally
→ Low confidence

---

## 5. Citation Format

### 5.1 Standard Citation

```
[Document Name], [Section Hierarchy], Page [X]
```

**Examples:**
```
- Architectural Design Guidelines, Chapter 4 > Section 4.2 "Fencing", Page 42
- CC&Rs Declaration, Article VII > Section 7.3, Page 23
- Rules and Regulations, Section 3 "Exterior Modifications", Page 8
```

### 5.2 Citation Rules

1. **Always cite** — Every factual claim needs a source
2. **Be specific** — Include section numbers, not just document name
3. **Include page** — Enable users to find the original
4. **Multiple sources** — List all relevant sources, not just the primary one

### 5.3 In-Line Citations (Optional)

For complex answers, cite inline:

```
Fences must not exceed 6 feet in height (Design Guidelines §4.2, p.42) and must use approved materials including wood, vinyl, or wrought iron (CC&Rs Art. VII §7.3, p.23).
```

---

## 6. Special Response Formats

### 6.1 No Results Found

```
I could not find information about [topic] in the governing documents.

**This could mean:**
- The topic is not specifically addressed in current guidelines
- My search terms didn't match the document language
- This may be handled on a case-by-case basis by the ARC

**Recommended Next Steps:**
- Contact the ARC directly at [contact info if available]
- Submit a pre-application inquiry
- Review the full guidelines document (available at [location])

**Confidence:** N/A — No relevant sources found
```

### 6.2 Clarification Request

```
I want to make sure I answer the right question. Your question about "[topic]" could mean:

1. **[Interpretation A]** — Asking about [specific aspect]
2. **[Interpretation B]** — Asking about [different aspect]
3. **[Interpretation C]** — Asking about [another aspect]

Which of these best matches what you're looking for? Or please provide more details.
```

### 6.3 Out of Scope Redirect

```
This question is outside what I can help with.

**What I can help with:**
- Architectural design requirements and guidelines
- CC&R rules and restrictions
- ARC application and approval processes

**For your question about [topic], please contact:**
- [Appropriate contact based on question type]

Is there anything about architectural guidelines I can help you with?
```

### 6.4 Partial Answer

When some aspects can be answered but not all:

```
I can partially answer this question.

**What I found:**
[Answer the parts with sources]

**What I couldn't find:**
- [Aspect not found in documents]
- [Another aspect]

For the parts I couldn't address, please contact the ARC directly.

**Sources:**
[Sources for answered parts]

**Confidence:** Medium — I could only address part of your question.
```

---

## 7. Edge Cases

### 7.1 Conflicting Sources

When documents appear to conflict:

```
**Short Answer**
[State the most authoritative/recent interpretation]

**Note on Conflicting Information:**
The Design Guidelines (§X.X) and CC&Rs (Art. X) appear to address this differently:
- Design Guidelines state: [quote]
- CC&Rs state: [quote]

The CC&Rs are the legally binding document and generally take precedence. For your specific situation, I recommend consulting with the ARC.

**Sources:**
[Both sources]

**Confidence:** Medium — Sources contain potentially conflicting information.
```

### 7.2 Superseded Information

When content may be outdated:

```
**Short Answer**
[Answer with current understanding]

**Important Note:**
This information is from [date/version]. Guidelines are periodically updated. Please verify with the ARC that these requirements are still current.

**Sources:**
[Sources with dates noted]

**Confidence:** Medium — Document version may not be current.
```

### 7.3 Precedent vs. Policy

When response letters differ from guidelines:

```
**Short Answer**
[Answer based on official guidelines]

**Previous ARC Decisions:**
I found [X] past ARC response(s) that addressed similar situations:
- [Summary of past decision]

**Important:** Past decisions are informational only and do not guarantee similar outcomes. Each application is reviewed individually based on current guidelines.

**Sources:**
- [Official guideline sources]
- [Response letter references - marked as "precedent only"]

**Confidence:** [Based on official sources, not precedent]
```

---

## 8. Formatting Guidelines

### 8.1 Markdown Usage

| Element | Usage |
|---------|-------|
| `**Bold**` | Section headers, key terms |
| `- Bullet` | Requirements lists, source lists |
| `>` Quote | Direct quotes from documents |
| `[link]` | Document references (if URLs available) |

### 8.2 Length Guidelines

| Component | Target Length |
|-----------|---------------|
| Short Answer | 1-2 sentences |
| Requirements | 3-7 bullets |
| What to Submit | 3-6 items |
| Additional Notes | 0-3 bullets |
| Sources | 1-4 citations |
| Total Response | 150-400 words |

### 8.3 Avoid

- Walls of text without structure
- Excessive qualifiers and hedging
- Repeating the question back
- Unnecessary pleasantries
- Technical jargon without explanation

---

## 9. Response Examples

### 9.1 Example: Fence Height Question

**User:** What's the maximum height for a backyard fence?

**JSON Response:**
```json
{
  "answer": "Backyard fences are limited to a maximum height of 6 feet in rear yards, measured from finished grade. Side yard fences forward of the rear building line have a lower maximum of 4 feet. Front yard fences are generally not permitted, though decorative elements up to 3 feet may be considered on a case-by-case basis.\n\nTo install a fence, you'll need to submit an ARC Application Form along with a site plan showing the fence location and dimensions, elevation drawings showing the proposed height, and material and color specifications.",
  "sources": [
    {
      "document_name": "Architectural Design Guidelines",
      "section_title": "Section 4.2 - Fencing",
      "section_hierarchy": ["Chapter 4", "Section 4.2"],
      "page_number": 42,
      "is_binding": true,
      "requirements": [
        "Maximum height: 6 feet in rear yards (measured from finished grade)",
        "Side yard fences: 4 feet maximum forward of rear building line",
        "Front yard fences: Generally not permitted; decorative elements up to 3 feet may be considered"
      ],
      "content": "Fencing in rear yards shall not exceed six feet (6') in height as measured from the finished grade..."
    }
  ],
  "confidence": {
    "level": "High",
    "explanation": "The guidelines clearly specify these height limits with specific measurements."
  }
}
```

### 9.2 Example: Fire-Resistant Plants Question

**User:** Are strawberries a fire-resistant plant?

**JSON Response:**
```json
{
  "answer": "Yes, wild strawberries are considered fire-resistant plants. Specifically, wild strawberry species (Fragaria species) are listed as approved fire-resistant ground covers in the Architectural Design Guidelines.",
  "sources": [
    {
      "document_name": "Architectural Design Guidelines",
      "section_title": "Exhibit F - Approved Fire-Resistant Plants",
      "section_hierarchy": ["Exhibits", "Exhibit F", "Ground Covers"],
      "page_number": 115,
      "is_binding": true,
      "requirements": [
        "Wild strawberry species (Fragaria species) are listed as approved fire-resistant ground covers"
      ],
      "content": "The following ground covers are approved fire-resistant plants for use in Discovery West landscaping: ... Wild Strawberry (Fragaria species) ..."
    }
  ],
  "confidence": {
    "level": "High",
    "explanation": "The document explicitly lists wild strawberries as fire-resistant."
  }
}
```

### 9.3 Example: No Results

**User:** Can I have chickens in my backyard?

**JSON Response:**
```json
{
  "answer": "I could not find specific information about keeping chickens or livestock in the Discovery West governing documents. This topic may be governed by local city or county ordinances rather than HOA rules, or it may be addressed under general nuisance provisions.\n\nI recommend checking local city/county regulations for residential livestock, contacting HOA management to inquire about pet and animal policies, or submitting a formal inquiry to the ARC if you believe this is an architectural matter.",
  "sources": [],
  "confidence": {
    "level": "Low",
    "explanation": "No relevant sources found in architectural guidelines or CC&Rs."
  }
}
```

---

## 10. Quality Checklist

Before sending a response, verify:

- [ ] Answer text is comprehensive and directly addresses the question
- [ ] Answer text does NOT contain section headers (Short Answer, Requirements, Sources, Confidence)
- [ ] All requirements are grouped under their source in the sources array
- [ ] Each source includes document_name, section_title, page_number, and is_binding
- [ ] Requirements array contains specific, actionable items from that source
- [ ] Confidence is provided as separate metadata (level + explanation)
- [ ] No information invented or assumed beyond retrieved documents
- [ ] Response is valid JSON

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.3 | 2026-01-02 | AI Agent | Updated authority badges: Binding, ARC Guidance, DWOA Guidance with document mapping |
| 2.2 | 2026-01-02 | AI Agent | Updated answer guidelines to be more concise and focused; sources remain comprehensive |
| 2.1 | 2026-01-01 | AI Agent | Added CC&Rs and Rules & Regulations to knowledge base; minor formatting updates |
| 2.0 | 2025-12-31 | AI Agent | Major restructure: JSON response format, requirements grouped by source, confidence as metadata |
| 1.0 | 2025-12-31 | AI Agent | Initial answer contract |

