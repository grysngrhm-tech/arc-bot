-- ============================================================
-- ARC Bot - Exhibit Supplement Data (Simple Version)
-- Run this in the Supabase SQL Editor
-- ============================================================
-- STEP 1: First, find your document_id by running:
-- SELECT id, name FROM documents;
-- Copy the UUID for "Architectural Design Guidelines"
-- ============================================================

-- STEP 2: Replace 'YOUR_DOCUMENT_ID_HERE' below with the actual UUID
-- Then run this entire script

-- ============================================================
-- EXHIBIT B - Prototype Tables
-- ============================================================
INSERT INTO knowledge_chunks (
    content, content_hash, document_id, document_name, document_type,
    section_hierarchy, section_title, page_number, chunk_index, is_binding
) VALUES (
'Exhibit B - Prototype Tables

Discovery West Residential Prototype Table

PROTOTYPE SPECIFICATIONS:
                                    R-1 Small Lot    R-2 Medium Lot    R-3 Large Lot

Maximum Home Height:                30 feet          30 feet           30 feet
Floor Area Ratio (FAR):             50%              50%               50%

LOT REQUIREMENTS:
Width:                              < 65 ft          65-90 ft          > 90 ft
Typical Depth:                      105 ft           120 ft            200+ ft
Maximum Coverage:                   50%              50%               35%

LOT SETBACKS:
Front Minimum:                      10 ft            10 ft             20 ft
Front Maximum:                      20 ft            20 ft             N/A
Side:                               7.5 ft           10 ft             20 ft
Rear:                               5 ft             5 ft              20 ft
Garage - Alley Loaded:              5 ft             5 ft              5 ft
Garage - Front Loaded:              26 ft            26 ft             26 ft

FOOTNOTES:
(1) When abutting an alley, 5 feet plus 1 foot for each foot by which the Home exceeds 15 feet.
(2) Corner lots will have two front and two rear setbacks.
(3) Garage must be accessed from the alley if an alley exists.
(4) Maximum Home square footage including garage shall not exceed 50% of Lot square footage. Lots with an ADU have a 55% FAR.
(5) Exceptions will be considered by the ARC on an individual design review basis.
(6) Garages must be setback from the front face/living space of the Home by 16 feet.
(7) A 1:1 slope setback applies from Non-Development Easement lines.',
    md5('exhibit_b_v2'),
    'YOUR_DOCUMENT_ID_HERE'::uuid,
    'Architectural Design Guidelines',
    'design_guidelines',
    ARRAY['Exhibits', 'Exhibit B - Prototype Tables'],
    'Exhibit B - Prototype Tables',
    110,
    200,
    true
);

-- ============================================================
-- EXHIBIT C - Floor Area Ratio (FAR) - THE CRITICAL ONE!
-- ============================================================
INSERT INTO knowledge_chunks (
    content, content_hash, document_id, document_name, document_type,
    section_hierarchy, section_title, page_number, chunk_index, is_binding
) VALUES (
'Exhibit C - Floor Area Ratio (FAR) for Residential Prototypes R-1, R-2, R-3

WHAT IS FAR?
The Floor Area Ratio (FAR) is a percentage of a home''s massing/volume in proportion to the size of the lot.

FAR CALCULATION:
Maximum Home Size = Lot Size × FAR (50%)

EXAMPLE:
A 5500 square foot lot × 0.5 = 2750 square feet maximum home size (including garage)

WHAT COUNTS TOWARD FAR:
- All floor area calculated to the face of exterior walls
- Attic space 25 feet or more above ground floor (two story portion)
- Attic space 15 feet or more above ground floor (one story portion)
- Crawl areas with heights of 5 feet or higher
- Garage floor area
- Porches, decks, and patios more than 5 feet above grade

WHAT DOES NOT COUNT TOWARD FAR:
- Basements and daylight basements (if they comply with diagrams)
- Area wells for basement windows
- Attics, crawlspaces, or basements with less than 5 feet height
- Stairwells (counted only once)

DISCOVERY WEST FAR RULES:
- FAR applies to all single family detached homes/lots
- Standard FAR: 50%
- FAR for homes with ADU: 55%
- Discovery West FAR is MORE restrictive than City of Bend FAR standard

IMPORTANT NOTE:
The ARC is available to assist with the FAR calculation.',
    md5('exhibit_c_v2'),
    'YOUR_DOCUMENT_ID_HERE'::uuid,
    'Architectural Design Guidelines',
    'design_guidelines',
    ARRAY['Exhibits', 'Exhibit C - Floor Area Ratio'],
    'Exhibit C - Floor Area Ratio (FAR)',
    112,
    201,
    true
);

-- ============================================================
-- EXHIBIT D - Alley Setback
-- ============================================================
INSERT INTO knowledge_chunks (
    content, content_hash, document_id, document_name, document_type,
    section_hierarchy, section_title, page_number, chunk_index, is_binding
) VALUES (
'Exhibit D - Alley Setback for Residential Prototypes R-1, R-2, R-3

ALLEY SETBACK REQUIREMENTS:
- Minimum setback from alley: 5 feet
- Distance from rear property line: 15 feet
- A 1:1 slope requirement applies

COMPLIANT DESIGN:
Structure must maintain minimum 5 feet from alley and 15 feet from rear property line. No portion of the home may extend beyond the 1:1 slope line.

NON-COMPLIANT:
Any building mass extending into the shaded zone (beyond 1:1 slope) violates setback rules.',
    md5('exhibit_d_v2'),
    'YOUR_DOCUMENT_ID_HERE'::uuid,
    'Architectural Design Guidelines',
    'design_guidelines',
    ARRAY['Exhibits', 'Exhibit D - Alley Setback'],
    'Exhibit D - Alley Setback',
    113,
    202,
    true
);

-- ============================================================
-- EXHIBIT E - Home Height
-- ============================================================
INSERT INTO knowledge_chunks (
    content, content_hash, document_id, document_name, document_type,
    section_hierarchy, section_title, page_number, chunk_index, is_binding
) VALUES (
'Exhibit E - Home Height for Residential Prototypes R-1, R-2, R-3

MAXIMUM HEIGHT: 30 feet

HOW HEIGHT IS MEASURED:
The ARC measures maximum height from the highest portion of the roof vertically to the natural or finished grade, whichever is lowest.

IMPORTANT:
The ARC reserves the right to require building heights less than city standards.',
    md5('exhibit_e_v2'),
    'YOUR_DOCUMENT_ID_HERE'::uuid,
    'Architectural Design Guidelines',
    'design_guidelines',
    ARRAY['Exhibits', 'Exhibit E - Home Height'],
    'Exhibit E - Home Height',
    114,
    203,
    true
);

-- ============================================================
-- EXHIBIT G - Street Tree Guidelines
-- ============================================================
INSERT INTO knowledge_chunks (
    content, content_hash, document_id, document_name, document_type,
    section_hierarchy, section_title, page_number, chunk_index, is_binding
) VALUES (
'Exhibit G - Street Tree Guidelines

PARK STRIP REQUIREMENTS:
- Plant entirely with sod and/or low-growing shrubs and groundcover
- Underground irrigation is required

STREET TREE REQUIREMENTS:
- Minimum: Two street trees per lot frontage
- Caliper: 2 inches (measured 6 inches above ground)
- Spacing: 30 feet on center

DESIGNED STREETSCAPE TREES (by street - see map):
- Red Oak, Pin Oak, Karpick/Bowhall/Armstrong Red Maple

NON-DESIGNED STREET TREES (other streets):
- Red Maple, Green Ash, Honeylocust, Crabapple, Spring Snow, Chokecherry, Canada Red, Hawthorn',
    md5('exhibit_g_v2'),
    'YOUR_DOCUMENT_ID_HERE'::uuid,
    'Architectural Design Guidelines',
    'design_guidelines',
    ARRAY['Exhibits', 'Exhibit G - Street Tree Guidelines'],
    'Exhibit G - Street Tree Guidelines',
    122,
    204,
    true
);

-- ============================================================
-- After running this, check results with:
-- SELECT section_title, LEFT(content, 100) FROM knowledge_chunks 
-- WHERE section_title LIKE 'Exhibit%' ORDER BY chunk_index;
-- ============================================================

