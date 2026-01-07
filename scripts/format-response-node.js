// Format Response Node - Defense in Depth JSON Parsing
// Source: scripts/format-response-node.js
// Last synced: 2026-01-07
//
// This is the canonical source for the Format Response node code.
// Copy this to n8n when deploying workflow updates.

const agentOutput = $input.first().json;
const sessionData = $('Load Session Memory').first().json;

const rawOutput = agentOutput.output || agentOutput.text || agentOutput.response || '';

let answer = '';
let sources = [];
let confidence = { level: 'Medium', explanation: '' };

// Extract requirements from content text
function extractRequirementsFromContent(content) {
  if (!content) return [];
  const requirements = [];
  
  // 1. Explicit bullets (-, •, *, numbered)
  const bulletMatches = content.match(/^[\s]*[-•*]\s+(.+)$/gm);
  if (bulletMatches) {
    bulletMatches.forEach(match => {
      const text = match.replace(/^[\s]*[-•*]\s+/, '').trim();
      if (text.length > 15 && text.length < 200) {
        requirements.push(text);
      }
    });
  }
  
  const numberedMatches = content.match(/^[\s]*\d+[.)]\s+(.+)$/gm);
  if (numberedMatches) {
    numberedMatches.forEach(match => {
      const text = match.replace(/^[\s]*\d+[.)]\s+/, '').trim();
      if (text.length > 15 && text.length < 200) {
        requirements.push(text);
      }
    });
  }
  
  // 2. Measurement patterns (numbers with units)
  const measurementPattern = /[^.]*\b(\d+)\s*(feet|foot|ft|inches|inch|days?|percent|%|square feet|sq\.?\s*ft)[^.]*\./gi;
  const measurementMatches = content.match(measurementPattern);
  if (measurementMatches) {
    measurementMatches.forEach(match => {
      const text = match.trim();
      if (text.length > 15 && text.length < 200 && !requirements.includes(text)) {
        requirements.push(text);
      }
    });
  }
  
  // 3. Requirement keywords
  const keywordPattern = /[^.]*\b(must|shall|required|prohibited|not permitted|not allowed|maximum|minimum|limited to|cannot exceed|may not)[^.]*\./gi;
  const keywordMatches = content.match(keywordPattern);
  if (keywordMatches) {
    keywordMatches.forEach(match => {
      const text = match.trim();
      if (text.length > 15 && text.length < 200 && !requirements.includes(text)) {
        requirements.push(text);
      }
    });
  }
  
  // Dedupe and limit to 7
  const unique = [...new Set(requirements)];
  return unique.slice(0, 7);
}

// Merge sources by document + section (not by chunk)
function mergeSourcesBySection(sources) {
  const grouped = {};
  
  for (const source of sources) {
    const hierarchy = (source.section_hierarchy || []).join(' > ');
    const key = `${source.document_name}|${hierarchy}|${source.section_title}`;
    
    if (!grouped[key]) {
      grouped[key] = {
        document_name: source.document_name || 'Unknown Document',
        section_title: source.section_title || '',
        section_hierarchy: source.section_hierarchy || [],
        is_binding: source.is_binding !== false,
        requirements: [],
        content_parts: []
      };
    }
    
    // Merge requirements (will dedupe later)
    if (source.requirements && source.requirements.length > 0) {
      grouped[key].requirements.push(...source.requirements);
    }
    
    // Collect content parts
    if (source.content) {
      grouped[key].content_parts.push(source.content);
    }
  }
  
  // Convert back to array, dedupe requirements, join content
  return Object.values(grouped).map(g => {
    const combinedContent = g.content_parts.join('\n\n---\n\n');
    let requirements = [...new Set(g.requirements)]; // dedupe
    
    // If no requirements provided, try to extract from content
    if (requirements.length === 0 && combinedContent) {
      requirements = extractRequirementsFromContent(combinedContent);
    }
    
    return {
      document_name: g.document_name,
      section_title: g.section_title,
      section_hierarchy: g.section_hierarchy,
      is_binding: g.is_binding,
      requirements: requirements,
      content: combinedContent
    };
  });
}

// Multi-strategy JSON extraction for defense in depth
let parsed = null;
let parseStrategy = 'none';

try {
  // Strategy 1: Code fence wrapped JSON (```json ... ```)
  const fenceMatch = rawOutput.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) {
    try {
      parsed = JSON.parse(fenceMatch[1].trim());
      parseStrategy = 'code-fence';
    } catch (e) {
      // Continue to next strategy
    }
  }
  
  // Strategy 2: Raw JSON starting with {
  if (!parsed && rawOutput.trim().startsWith('{')) {
    try {
      parsed = JSON.parse(rawOutput.trim());
      parseStrategy = 'raw-json';
    } catch (e) {
      // Continue to next strategy
    }
  }
  
  // Strategy 3: JSON embedded after prose text
  if (!parsed) {
    const lastBrace = rawOutput.lastIndexOf('}');
    const firstBrace = rawOutput.indexOf('{');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      try {
        parsed = JSON.parse(rawOutput.slice(firstBrace, lastBrace + 1));
        parseStrategy = 'embedded-json';
      } catch (e) {
        // Continue to fallback
      }
    }
  }
  
  if (parsed) {
    answer = parsed.answer || '';
    
    // Map sources and then merge by section
    const rawSources = (parsed.sources || []).map(source => ({
      document_name: source.document_name || 'Unknown Document',
      section_title: source.section_title || '',
      section_hierarchy: source.section_hierarchy || [],
      is_binding: source.is_binding !== false,
      requirements: source.requirements || [],
      content: source.content || ''
    }));
    
    // Merge sources by document + section
    sources = mergeSourcesBySection(rawSources);
    
    confidence = {
      level: parsed.confidence?.level || 'Medium',
      explanation: parsed.confidence?.explanation || ''
    };
  } else {
    // Fallback: use raw output as answer
    answer = rawOutput;
    parseStrategy = 'fallback-raw';
    console.warn('JSON parsing failed - using raw output. Input:', rawOutput.substring(0, 200));
  }
} catch (e) {
  answer = rawOutput;
  parseStrategy = 'error-fallback';
  console.error('Format Response error:', e.message);
  
  // Try to extract confidence from markdown format as last resort
  const confidenceMatch = rawOutput.match(/\*\*Confidence:\*\*\s*(High|Medium|Low)\s*[—–-]?\s*([^\n]*)/i);
  if (confidenceMatch) {
    confidence = {
      level: confidenceMatch[1],
      explanation: confidenceMatch[2]?.trim() || ''
    };
    answer = answer.replace(/\*\*Confidence:\*\*[^\n]*/gi, '').trim();
  }
}

// Log parse strategy for monitoring
console.log('Parse strategy used: ' + parseStrategy);

return [{
  json: {
    status: 'success',
    session_id: sessionData.session_id,
    answer: answer,
    sources: sources,
    confidence: confidence,
    history_length: sessionData.history_count + 1,
    _debug: { parseStrategy: parseStrategy }
  }
}];
