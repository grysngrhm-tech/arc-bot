// Format the agent response for the frontend
const agentOutput = $input.first().json;
const sessionData = $('Load Session Memory').first().json;

const rawOutput = agentOutput.output || agentOutput.text || agentOutput.response || '';

let answer = '';
let sources = [];
let confidence = { level: 'Medium', explanation: '' };

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
    sources = (parsed.sources || []).map(source => ({
      document_name: source.document_name || 'Unknown Document',
      section_title: source.section_title || '',
      section_hierarchy: source.section_hierarchy || [],
      page_number: source.page_number || null,
      is_binding: source.is_binding !== false,
      requirements: source.requirements || [],
      content: source.content || ''
    }));
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

