// Format the agent response for the frontend
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

try {
  let parsed;
  const jsonMatch = rawOutput.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    parsed = JSON.parse(jsonMatch[1].trim());
  } else if (rawOutput.trim().startsWith('{')) {
    parsed = JSON.parse(rawOutput);
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
    answer = rawOutput;
  }
} catch (e) {
  answer = rawOutput;
  const confidenceMatch = rawOutput.match(/\*\*Confidence:\*\*\s*(High|Medium|Low)\s*[—–-]?\s*([^\n]*)/i);
  if (confidenceMatch) {
    confidence = {
      level: confidenceMatch[1],
      explanation: confidenceMatch[2]?.trim() || ''
    };
    answer = answer.replace(/\*\*Confidence:\*\*[^\n]*/gi, '').trim();
  }
}

return [{
  json: {
    status: 'success',
    session_id: sessionData.session_id,
    answer: answer,
    sources: sources,
    confidence: confidence,
    history_length: sessionData.history_count + 1
  }
}];
