// Run database migration to add 'city_code' document type
// Run with: node scripts/run_migration.js

const SUPABASE_URL = 'https://wdouifomlipmlsksczsv.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indkb3VpZm9tbGlwbWxza3NjenN2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzIwNDc1MSwiZXhwIjoyMDgyNzgwNzUxfQ.D8mwFo3yXzFq-lFsJBDewlowscdTF0zAfQw8lrG_7pI';

async function runMigration() {
  console.log('='.repeat(60));
  console.log('Running Migration: Add city_code document type');
  console.log('='.repeat(60));

  const migrationSQL = `
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
  `;

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ query: migrationSQL })
    });

    if (!response.ok) {
      // RPC function might not exist, try alternative approach
      console.log('Note: exec_sql RPC not available, migration must be run manually.');
      console.log('\nPlease run this SQL in Supabase SQL Editor:');
      console.log('-'.repeat(60));
      console.log(migrationSQL);
      console.log('-'.repeat(60));
      console.log('\nAfter running, execute: node scripts/upload_dw_chunks.js');
      return false;
    }

    console.log('✅ Migration completed successfully!');
    return true;
  } catch (error) {
    console.error('Migration error:', error.message);
    console.log('\nPlease run migration manually in Supabase SQL Editor.');
    return false;
  }
}

runMigration();

