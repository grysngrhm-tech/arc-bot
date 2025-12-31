-- =============================================================================
-- ARC Bot Storage Bucket Setup
-- Run this AFTER the main schema (001_initial_schema.sql)
-- =============================================================================

-- Create the storage bucket for source documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'arc-documents', 
    'arc-documents', 
    false,
    52428800,  -- 50MB limit
    ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for the bucket

-- Allow service role full access
CREATE POLICY "Service role full access on arc-documents"
ON storage.objects FOR ALL
USING (bucket_id = 'arc-documents' AND auth.role() = 'service_role')
WITH CHECK (bucket_id = 'arc-documents' AND auth.role() = 'service_role');

-- Allow authenticated users to read (optional - for signed URL access)
CREATE POLICY "Authenticated read access on arc-documents"
ON storage.objects FOR SELECT
USING (bucket_id = 'arc-documents' AND auth.role() = 'authenticated');

