# ARC Bot (Architectural Review Console) — Risks and Mitigations

**Version:** 1.3  
**Last Updated:** December 31, 2025  
**Status:** Canonical Reference

---

## 1. Overview

This document catalogs known risks in the ARC Bot system, their potential impact, mitigation strategies, and monitoring approaches. This is a living document that should be updated as new risks are identified.

### 1.1 Risk Categories

| Category | Description |
|----------|-------------|
| **Accuracy** | Risks affecting answer correctness |
| **Trust** | Risks affecting user confidence |
| **Security** | Risks affecting data or system integrity |
| **Operational** | Risks affecting system availability |
| **Legal** | Risks affecting compliance or liability |

### 1.2 Severity Levels

| Level | Definition | Response Time |
|-------|------------|---------------|
| **Critical** | System unusable or producing dangerous outputs | Immediate |
| **High** | Significant impact on accuracy or trust | Within 24 hours |
| **Medium** | Noticeable impact on user experience | Within 1 week |
| **Low** | Minor inconvenience or edge case | Next release |

---

## 2. Accuracy Risks

### 2.1 Hallucination

**Risk ID:** ACC-001  
**Severity:** Critical  
**Category:** Accuracy

**Description:**  
The AI generates information not present in source documents, potentially providing incorrect guidance on architectural requirements.

**Impact:**
- Users make decisions based on false information
- Trust in system destroyed
- Potential liability for incorrect guidance

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Retrieval-first architecture | Agent must call retrieval before answering | Design |
| Citation requirement | Every claim must cite a source | Design |
| System prompt guardrails | Explicit "only answer from retrieved content" | Design |
| Confidence scoring | Low confidence for weak matches | Design |
| "I don't know" responses | Explicit handling of no-match scenarios | Design |

**Monitoring:**
- Track responses containing hallucination indicators ("generally", "typically", "most HOAs")
- Sample audit of responses vs. retrieved sources
- User feedback mechanism for incorrect answers

**Residual Risk:** Medium — Despite guardrails, LLMs can still hallucinate. Human review of flagged responses recommended.

---

### 2.2 Outdated Information

**Risk ID:** ACC-002  
**Severity:** High  
**Category:** Accuracy

**Description:**  
Documents in the knowledge base may not reflect current guidelines if amendments or updates are not ingested.

**Impact:**
- Users receive outdated requirements
- Decisions based on superseded rules
- Disputes with ARC over "what the system said"

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Version tracking | `effective_date` and `superseded_by` fields | Design |
| Document registry | Track all source documents and versions | Design |
| Update alerts | Flag when documents may be stale | Future |
| Date disclaimers | Include document dates in citations | Design |

**Monitoring:**
- Track document ages in knowledge base
- Alert when documents exceed 1 year since last update
- Compare ingested documents to official ARC document list

**Residual Risk:** Medium — Requires manual process to update documents. Consider periodic verification.

---

### 2.3 Incomplete Coverage

**Risk ID:** ACC-003  
**Severity:** Medium  
**Category:** Accuracy

**Description:**  
Certain topics may not be adequately covered in the knowledge base due to chunking gaps, extraction errors, or missing documents.

**Impact:**
- "I can't find" responses for covered topics
- Users think topic isn't addressed when it is
- Reduced system utility

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Coverage validation | Gap detection after ingestion | Design |
| Page coverage check | Verify all pages represented | Design |
| Section validation | Compare chunks to TOC | Design |
| Hybrid search | FTS catches keyword misses | Design |

**Monitoring:**
- Track "no results" query rate
- Log queries that produce zero results
- Periodic coverage audits against source documents

**Residual Risk:** Low — Good chunking and validation should catch most gaps.

---

### 2.4 Poor Retrieval Quality

**Risk ID:** ACC-004  
**Severity:** High  
**Category:** Accuracy

**Description:**  
Retrieved chunks may not be the most relevant ones due to embedding quality issues, query formulation problems, or index configuration.

**Impact:**
- Correct information exists but isn't retrieved
- Answers based on tangentially related content
- Confidence appears high but answer is wrong

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Hybrid search | Combine vector and keyword search | Design |
| Reranking | LLM-based relevance scoring | Design |
| Multiple candidates | Retrieve 20, use 5-8 after reranking | Design |
| Embedding model | text-embedding-3-large for quality | Design |

**Monitoring:**
- Track average retrieval relevance scores
- A/B test retrieval configurations
- User feedback on answer relevance

**Residual Risk:** Medium — Retrieval is inherently imperfect. Reranking mitigates but doesn't eliminate.

---

## 3. Trust Risks

### 3.1 Over-Reliance on Bot

**Risk ID:** TRU-001  
**Severity:** High  
**Category:** Trust

**Description:**  
Users may treat ARC Bot as an authoritative decision-maker rather than an informational tool.

**Impact:**
- Users skip official ARC review process
- Disputes over "the bot said it was okay"
- Liability for decisions based on bot advice

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Clear disclaimers | "This is guidance, not approval" messaging | Design |
| Redirect to ARC | Always mention official process | Design |
| No approval language | System prompt prohibits approval phrasing | Design |
| Confidence levels | Signal uncertainty appropriately | Design |

**Monitoring:**
- Review responses for approval-like language
- Track user follow-up questions indicating confusion
- Survey users on how they use the information

**Residual Risk:** Medium — User behavior cannot be fully controlled. Clear messaging reduces risk.

---

### 3.2 Perceived Inconsistency

**Risk ID:** TRU-002  
**Severity:** Medium  
**Category:** Trust

**Description:**  
Same or similar questions may produce noticeably different answers due to retrieval variability or prompt sensitivity.

**Impact:**
- Users lose confidence in system
- Confusion about "correct" answer
- Perceived unreliability

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Low temperature | GPT-4o with temperature 0-0.1 | Design |
| Deterministic retrieval | Consistent scoring and ranking | Design |
| Answer structure | Enforced format reduces variability | Design |
| Caching | Cache similar queries (optional) | Future |

**Monitoring:**
- Test response consistency with repeated queries
- Track variance in answers to common questions
- User reports of inconsistent answers

**Residual Risk:** Low — Deterministic settings and structured output minimize variability.

---

### 3.3 Source Credibility

**Risk ID:** TRU-003  
**Severity:** Medium  
**Category:** Trust

**Description:**  
Users may not trust or understand the cited sources, especially if citations are unclear or sources seem incomplete.

**Impact:**
- Users dismiss accurate information
- Requests for "proof" or "where exactly"
- Friction in adoption

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Specific citations | Document, section, page | Design |
| Link to source | URL to PDF page if possible | Future |
| Source transparency | Explain what documents are included | Design |
| Quote key text | Direct quotes for critical rules | Design |

**Monitoring:**
- User questions about sources
- Requests for more specific citations
- Click-through on source links (if implemented)

**Residual Risk:** Low — Detailed citations with page numbers should satisfy most users.

---

## 4. Security Risks

### 4.1 Prompt Injection

**Risk ID:** SEC-001  
**Severity:** High  
**Category:** Security

**Description:**  
Malicious users may attempt to manipulate the system through crafted inputs that override system instructions.

**Impact:**
- System behaves unexpectedly
- Leaks system prompt or internal details
- Provides harmful outputs

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Input sanitization | Filter suspicious patterns | Design |
| Strict system prompt | Clear behavioral boundaries | Design |
| Output validation | Check for anomalous responses | Design |
| Rate limiting | Prevent rapid attack attempts | Design |

**Monitoring:**
- Log unusual input patterns
- Alert on responses mentioning system prompt
- Track failed validation attempts

**Residual Risk:** Medium — Complete prevention is difficult. Monitoring and response critical.

---

### 4.2 API Key Exposure

**Risk ID:** SEC-002  
**Severity:** Critical  
**Category:** Security

**Description:**  
OpenAI or Supabase API keys could be exposed through client-side code, logs, or misconfiguration.

**Impact:**
- Unauthorized API usage
- Cost overruns
- Data access compromise

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Server-side keys | All API calls from n8n, not frontend | Design |
| n8n credentials | Keys stored in n8n credential store | Design |
| No client secrets | Frontend has no API access | Design |
| Key rotation | Rotate keys quarterly | Operational |

**Monitoring:**
- Monitor API usage for anomalies
- Alert on usage spikes
- Audit credential access

**Residual Risk:** Low — Server-side only architecture minimizes exposure.

---

### 4.3 Data Exfiltration

**Risk ID:** SEC-003  
**Severity:** Low  
**Category:** Security

**Description:**  
Attackers may attempt to extract the entire knowledge base through repeated queries.

**Impact:**
- Intellectual property exposure (if applicable)
- Competitive disadvantage (minimal for public governance docs)

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Rate limiting | Limit queries per session/IP | Design |
| Chunk limits | Don't return entire documents | Design |
| Public documents | Source docs are community documents | N/A |

**Monitoring:**
- Track high-volume query patterns
- Alert on systematic querying

**Residual Risk:** Very Low — Source documents are already publicly available to community members.

---

## 5. Operational Risks

### 5.1 Service Unavailability

**Risk ID:** OPS-001  
**Severity:** High  
**Category:** Operational

**Description:**  
n8n server, Supabase, or OpenAI API may become unavailable, causing complete system failure.

**Impact:**
- Users cannot get answers
- Frustration and loss of trust
- Potential escalation to manual ARC support

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Error handling | Graceful failure messages | Design |
| Retry logic | Retry transient failures | Design |
| Status page | Communicate known issues | Future |
| Fallback | Basic FAQ for common questions | Future |

**Monitoring:**
- Health checks on all services
- Alert on consecutive failures
- Track uptime metrics

**Residual Risk:** Medium — Dependent on third-party services. Accept some unavailability risk.

---

### 5.2 Performance Degradation

**Risk ID:** OPS-002  
**Severity:** Medium  
**Category:** Operational

**Description:**  
Response times may exceed acceptable thresholds due to slow retrieval, API latency, or resource constraints.

**Impact:**
- Poor user experience
- Abandoned queries
- Perceived system issues

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Performance targets | < 10s total response time | Design |
| Index optimization | HNSW for fast vector search | Design |
| Streaming | Stream responses as generated | Future |
| Caching | Cache common queries | Future |

**Monitoring:**
- Track query latency percentiles
- Alert on P95 > 15 seconds
- Identify slow query patterns

**Residual Risk:** Medium — LLM API calls have inherent latency. Streaming can improve perceived performance.

---

### 5.3 Cost Overrun

**Risk ID:** OPS-003  
**Severity:** Medium  
**Category:** Operational

**Description:**  
High usage or inefficient queries may result in unexpected OpenAI API costs.

**Impact:**
- Budget exceeded
- Service throttled or disabled
- Difficult to sustain operation

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Cost estimation | Estimate per-query cost | Design |
| Usage limits | Cap queries per day | Future |
| Efficient prompts | Minimize token usage | Design |
| Model selection | Use appropriate model tiers | Design |

**Cost Estimates:**
| Component | Est. Cost/Query | Notes |
|-----------|-----------------|-------|
| Query embedding | $0.0001 | text-embedding-3-large |
| Vector search | ~$0 | Supabase (within free tier) |
| Reranking (GPT-4o) | $0.01-0.03 | Depends on candidate count |
| Answer generation | $0.02-0.05 | Depends on response length |
| **Total** | ~$0.03-0.08 | Per substantive query |

**Monitoring:**
- Track daily/monthly API costs
- Alert on cost spikes
- Review high-cost queries

**Residual Risk:** Low — Moderate usage expected. Costs manageable with monitoring.

---

## 6. Legal Risks

### 6.1 Liability for Incorrect Guidance

**Risk ID:** LEG-001  
**Severity:** High  
**Category:** Legal

**Description:**  
Users may claim damages from following incorrect guidance from ARC Bot.

**Impact:**
- Legal claims against HOA/ARC
- Costly disputes
- System shutdown

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Disclaimer | Clear "informational only" messaging | Design |
| No approvals | System never approves requests | Design |
| Source transparency | Always cite official documents | Design |
| Confidence signals | Flag uncertain answers | Design |
| Terms of use | User acknowledgment of limitations | Future |

**Monitoring:**
- Track user complaints about incorrect info
- Review disputed answers
- Document all changes to system behavior

**Residual Risk:** Medium — Disclaimer and design choices reduce but don't eliminate risk. Legal review recommended.

---

### 6.2 Accessibility Compliance

**Risk ID:** LEG-002  
**Severity:** Medium  
**Category:** Legal

**Description:**  
Frontend may not meet accessibility standards (WCAG), potentially excluding users with disabilities.

**Impact:**
- Exclusion of community members
- ADA compliance issues
- Reputational damage

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| Semantic HTML | Proper heading structure | Design |
| Keyboard navigation | All functions keyboard accessible | Design |
| Screen reader support | ARIA labels where needed | Design |
| Color contrast | Meet WCAG AA standards | Design |

**Monitoring:**
- Accessibility audit before launch
- User feedback on accessibility issues
- Periodic automated scans

**Residual Risk:** Low — Standard web accessibility practices should suffice.

---

### 6.3 Data Privacy

**Risk ID:** LEG-003  
**Severity:** Low  
**Category:** Legal

**Description:**  
System may inadvertently collect or expose personal information.

**Impact:**
- Privacy violations
- Regulatory issues
- User distrust

**Mitigation Strategies:**
| Strategy | Implementation | Status |
|----------|----------------|--------|
| No PII storage | Don't store user queries long-term | Design |
| Anonymous usage | No user accounts required | Design |
| No sensitive docs | Exclude personal submittals (initially) | Design |
| Clear privacy policy | Communicate data handling | Future |

**Monitoring:**
- Audit stored data for PII
- Review query logs for sensitive content
- User complaints about privacy

**Residual Risk:** Very Low — Public governance documents, no user identification.

---

## 7. Risk Monitoring Dashboard

### 7.1 Key Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Response accuracy (sampled) | > 95% | < 90% |
| "I can't find" rate | < 10% | > 20% |
| Average relevance score | > 0.7 | < 0.5 |
| Response latency (P95) | < 10s | > 15s |
| Error rate | < 1% | > 5% |
| Daily cost | < $50 | > $100 |

### 7.2 Audit Schedule

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Response quality sampling | Weekly | Admin |
| Coverage gap analysis | Monthly | Admin |
| Security review | Quarterly | Admin |
| Document freshness check | Monthly | Admin |
| Cost analysis | Monthly | Admin |

---

## 8. Incident Response

### 8.1 Response Procedures

**Critical Incident (Hallucination, Security Breach):**
1. Immediately disable system if needed
2. Assess scope of impact
3. Notify stakeholders
4. Implement fix
5. Post-incident review

**High Severity (Major Accuracy Issue):**
1. Assess impact
2. Determine if system should stay online
3. Implement fix within 24 hours
4. Document issue and resolution

**Medium/Low Severity:**
1. Log issue
2. Schedule fix for next release
3. Monitor for escalation

### 8.2 Rollback Procedure

If a change causes issues:

1. n8n: Restore previous workflow version from backup
2. Knowledge base: Query previous ingestion batch, restore if needed
3. Frontend: Redeploy previous GitHub Pages commit

---

## 9. Risk Acceptance

### 9.1 Accepted Risks

The following risks are acknowledged and accepted:

| Risk | Reason for Acceptance |
|------|----------------------|
| LLM inherent imperfection | Mitigation in place; perfect accuracy not achievable |
| Third-party service dependency | Benefits outweigh risks; monitoring in place |
| User behavior | Cannot control how users interpret information |

### 9.2 Unacceptable Risks

The following would require immediate action:

| Condition | Response |
|-----------|----------|
| Repeated confirmed hallucinations | System offline until fixed |
| API key exposure | Immediate key rotation |
| Legal claim | Legal review, potential shutdown |

---

## 10. Implementation Issues Encountered

During development, the following issues were encountered and resolved:

### 10.1 Technical Issues

| Issue | Severity | Category | Resolution |
|-------|----------|----------|------------|
| HNSW dimension limit (2000 max) | High | Operational | Reduced embedding dimensions from 3072 to 1536 |
| n8n sandbox lacks `crypto` module | Medium | Operational | Implemented custom UUID generator |
| PDF extractor returns non-string types | Medium | Accuracy | Added explicit String() conversion |
| OpenAI embedding token limit (8192) | High | Operational | Implemented multi-strategy chunking |
| Foreign key constraint on document_id | Medium | Operational | Create document record before chunks |
| n8n 2.0 batch node output order reversed | Low | Operational | Manual rewiring (top=done, bottom=loop) |
| Full workflow updates clear credentials | Low | Operational | Document and warn users |
| All chunks assigned same section title | High | Accuracy | Search for section titles AFTER TOC ends |
| Section boundaries clustered at TOC | High | Accuracy | Calculate `tocEndPos` and offset search |
| PDF exhibits not extracted (tables/diagrams) | High | Accuracy | Manual transcription + vectorization |
| Exhibit F multi-page plant lists missing | High | Coverage | Transcribed all 9 plant category lists manually |
| FAR calculation missing from retrieval | High | Accuracy | Manually added Exhibit C with FAR formula/rules |
| NDE diagram content not searchable | Medium | Coverage | Transcribed NDE-1, NDE-2, NDE-3 exhibit text |

### 10.2 Lessons for Future Development

1. **Always validate n8n node behavior** - Node outputs may differ from documentation
2. **Conservative chunk sizes** - Stay well under API limits (50% margin recommended)
3. **Type safety for external data** - PDF libraries return unpredictable types
4. **Database constraints matter** - Plan insert order around foreign keys
5. **Test with batch size of 1 first** - Easier to debug failures
6. **Consider duplicate text patterns** - Section titles in TOC vs content body
7. **Verify section assignment variety** - Don't assume uniform section titles indicate success

### 10.3 Risk Status Updates

| Risk ID | Original Status | Current Status | Notes |
|---------|-----------------|----------------|-------|
| ACC-003 (Incomplete Coverage) | Design | **Resolved** | All exhibits A-O manually transcribed and vectorized |
| ACC-004 (Poor Retrieval) | Design | **Mitigated** | Hybrid search tested with 0.65 score on exact matches |
| OPS-002 (Performance) | Design | **Monitoring** | Response time ~2-3s in testing |
| SEC-002 (API Key Exposure) | Design | **Implemented** | Keys stored in n8n credentials only |

### 10.5 Exhibit Extraction Resolution

**Problem:** PDF extraction failed to capture exhibit content from pages with tables, diagrams, and multi-column plant lists (Exhibits B, C, F, K, L, M, N). Users searching for FAR calculations, fire-resistant plants, or NDE requirements received irrelevant results.

**Root Cause:** PDF text extraction libraries struggle with:
- Tabular data (Exhibit B prototype tables, Exhibit C FAR formula)
- Multi-column layouts (Exhibit F plant lists)
- Text embedded in diagrams (NDE compliance drawings)
- Image-heavy pages with minimal extractable text

**Solution:**
1. Identified missing exhibits by testing key queries
2. Manually transcribed exhibit content from source images
3. Created PowerShell scripts to:
   - Generate embeddings via OpenAI API
   - Insert chunks with proper metadata and content_hash
4. Vectorized 24 exhibit chunks covering all 15 exhibits (A-O)

**Verification:** FAR query now returns Exhibit C with 0.49 relevance score (previously no relevant results)

### 10.4 Section Title Detection Bug - Detailed Analysis

**Problem:** All 124 chunks were assigned `section_title: "Exhibit O - Compliant Porch Column Detail"`

**Root Cause:** The `indexOf()` function found section titles in the **Table of Contents** at the beginning of the document, rather than in the actual content sections. Since "Exhibit O" was the last entry in the TOC (around character 29,000), its boundary extended from there to the end of the document, encompassing all actual content.

**Solution:** 
1. Calculate where the TOC ends by finding the last TOC title position
2. Add a buffer (5000 chars) to skip past the TOC
3. Search for section titles only in `fullText.substring(tocEndPos)`
4. Offset found positions by `tocEndPos` for correct global character positions

**Code Pattern:**
```javascript
// Find TOC end position
let tocEndPos = 0;
for (const section of sections) {
  const pos = fullText.indexOf(section.title);
  if (pos > tocEndPos) tocEndPos = pos + section.title.length;
}
tocEndPos += 5000; // Buffer past TOC

// Search after TOC
const searchText = fullText.substring(tocEndPos);
const pos = searchText.indexOf(title);
if (pos >= 0) {
  actualPosition = tocEndPos + pos;  // Offset by TOC end
}
```

**Verification:** After fix, chunks now show varied section titles matching actual document structure (Fencing, Roofing, Site Design, etc.)

---

## 11. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.3 | 2025-12-31 | AI Agent | Added exhibit extraction resolution (148 total chunks) |
| 1.2 | 2025-12-31 | AI Agent | Added section title detection bug analysis |
| 1.1 | 2025-12-31 | AI Agent | Added implementation issues section |
| 1.0 | 2025-12-31 | AI Agent | Initial risk documentation |

