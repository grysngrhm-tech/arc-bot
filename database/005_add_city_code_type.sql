-- ============================================================================
-- Migration: Add 'city_code' as valid document_type
-- Run this in Supabase SQL Editor before uploading Discovery West data
-- ============================================================================

-- Add 'city_code' to documents table CHECK constraint
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_valid_type;
ALTER TABLE documents ADD CONSTRAINT documents_valid_type CHECK (
    document_type IN (
        'design_guidelines',
        'ccr',
        'rules_regulations',
        'application_form',
        'submittal',
        'response_letter',
        'amendment',
        'city_code'
    )
);

-- Add 'city_code' to knowledge_chunks table CHECK constraint
ALTER TABLE knowledge_chunks DROP CONSTRAINT IF EXISTS chunks_valid_document_type;
ALTER TABLE knowledge_chunks ADD CONSTRAINT chunks_valid_document_type CHECK (
    document_type IN (
        'design_guidelines',
        'ccr',
        'rules_regulations',
        'application_form',
        'submittal',
        'response_letter',
        'amendment',
        'city_code'
    )
);

-- Verification: Check constraints were updated
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname IN ('documents_valid_type', 'chunks_valid_document_type');

