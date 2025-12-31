# ARC Bot — Answer Contract

**Version:** 1.0  
**Last Updated:** December 31, 2025  
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

### 3.1 Required Components

```
**Short Answer**
[1-2 sentences directly answering the question]

**Requirements** (if applicable)
- [Requirement 1 from documents]
- [Requirement 2 from documents]
- [Requirement 3 from documents]

**What to Submit** (if applicable)
- [Required submittal item 1]
- [Required submittal item 2]

**Additional Notes** (if applicable)
- [Relevant context or exceptions]

**Sources**
- [Document Name], [Section], Page [X]
- [Document Name], [Section], Page [X]

**Confidence:** [High/Medium/Low] — [Brief explanation]
```

### 3.2 Component Details

#### Short Answer

**Purpose:** Give the user an immediate, direct answer.

**Guidelines:**
- Maximum 2 sentences
- No hedging words ("perhaps", "maybe", "possibly")
- State the answer, not that you found an answer

**Good:**
```
Fences in rear yards are limited to 6 feet in height. Front yard fences are not permitted except as approved decorative elements.
```

**Bad:**
```
Based on my search of the documents, I found some information that may be relevant to your question about fence heights which I will explain below.
```

#### Requirements

**Purpose:** List specific rules or requirements from documents.

**Guidelines:**
- Use bullet points
- One requirement per bullet
- Include measurements/specifics when available
- Quote document language when precise wording matters

**Good:**
```
**Requirements:**
- Maximum height: 6 feet (rear yard), 4 feet (side yard forward of rear building line)
- Allowed materials: Wood, vinyl, wrought iron, or masonry
- Color must complement the home's exterior palette
- Gates must swing inward, not into common areas
```

**Bad:**
```
**Requirements:**
- Fences should generally be reasonable in height
- Use appropriate materials
- Try to match your house
```

#### What to Submit

**Purpose:** Tell users what they need for ARC approval.

**Guidelines:**
- List specific documents/drawings required
- Mention if samples are needed
- Include application form references

**Good:**
```
**What to Submit:**
- ARC Application Form (Exhibit A)
- Site plan showing fence location and setbacks
- Elevation drawings showing height and design
- Material samples or manufacturer specifications
- Color samples if different from home exterior
```

#### Additional Notes

**Purpose:** Provide relevant context, exceptions, or warnings.

**Guidelines:**
- Use only when genuinely helpful
- Keep brief (1-3 bullets max)
- Include exceptions or special cases

**Good:**
```
**Additional Notes:**
- Pool safety fences may have different requirements per city code
- Temporary construction fencing does not require ARC approval
- Corner lots may have additional visibility requirements
```

#### Sources

**Purpose:** Enable verification of all claims.

**Guidelines:**
- List every document chunk used in the answer
- Include document name, section path, and page number
- Order by relevance or document hierarchy

**Format:**
```
**Sources:**
- Architectural Design Guidelines, Chapter 4 > Section 4.2 "Fencing", Page 42
- CC&Rs Declaration, Article VII > Section 7.3 "Exterior Modifications", Page 23
```

#### Confidence

**Purpose:** Signal reliability of the answer.

**Guidelines:**
- Always include at end of substantive answers
- Include brief explanation of why

**Format:**
```
**Confidence:** High — Multiple sections directly address this topic with clear requirements.

**Confidence:** Medium — The guidelines discuss this generally but your specific case may vary.

**Confidence:** Low — I found related information but nothing that directly answers this question.
```

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

```
**Short Answer**
Backyard fences are limited to a maximum height of 6 feet in rear yards.

**Requirements:**
- Maximum height: 6 feet (measured from finished grade)
- Side yard fences: 4 feet maximum forward of rear building line
- Front yard fences: Generally not permitted; decorative elements up to 3 feet may be considered

**What to Submit:**
- ARC Application Form
- Site plan showing fence location with dimensions
- Elevation drawing showing proposed height
- Material and color specifications

**Sources:**
- Architectural Design Guidelines, Chapter 4 > Section 4.2 "Fencing", Page 42-43

**Confidence:** High — The guidelines clearly specify these height limits.
```

### 9.2 Example: Process Question

**User:** How do I apply for ARC approval?

```
**Short Answer**
Submit an ARC Application Form (Exhibit A) with required drawings and specifications at least 30 days before starting work.

**Process:**
1. Download ARC Application Form (Exhibit A)
2. Complete all sections of the form
3. Attach required documentation (site plan, elevations, materials)
4. Submit to ARC via [submission method]
5. ARC reviews within 30 days
6. Receive written response with approval, denial, or modification request

**What to Submit:**
- Completed ARC Application Form
- Site plan (to scale) showing proposed changes
- Elevation drawings if applicable
- Material samples or specifications
- Color samples
- Contractor information (if using)

**Sources:**
- Architectural Design Guidelines, Chapter 2 "Application Process", Pages 8-12
- ARC Application Form (Exhibit A)

**Confidence:** High — The application process is clearly documented.
```

### 9.3 Example: No Results

**User:** Can I have chickens in my backyard?

```
I could not find specific information about keeping chickens or livestock in the Discovery West governing documents.

**This could mean:**
- The topic may be governed by local city/county ordinances rather than HOA rules
- It may be addressed under general "nuisance" provisions
- The ARC may evaluate such requests on a case-by-case basis

**Recommended Next Steps:**
- Check local city/county regulations for residential livestock
- Contact HOA management to inquire about pet/animal policies
- Submit a formal inquiry to the ARC if you believe this is an architectural matter

**Confidence:** N/A — No relevant sources found in architectural guidelines or CC&Rs.
```

---

## 10. Quality Checklist

Before sending a response, verify:

- [ ] Short answer directly addresses the question
- [ ] All requirements are from retrieved documents
- [ ] Every factual claim has a citation
- [ ] Sources include document name, section, and page
- [ ] Confidence level is appropriate and explained
- [ ] Response follows the required structure
- [ ] No information invented or assumed
- [ ] Length is appropriate (not too long/short)

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-31 | AI Agent | Initial answer contract |

