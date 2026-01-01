-- ============================================================
-- ARC Bot - Exhibit Supplement Data
-- Run this AFTER the initial schema (001_initial_schema.sql)
-- These chunks add critical exhibit content that PDF extraction missed
-- ============================================================

-- First, get the document_id for "Architectural Design Guidelines"
-- You'll need to replace 'YOUR_DOCUMENT_ID' with the actual UUID from your documents table
-- Run this query first: SELECT id FROM documents WHERE name LIKE '%Architectural Design Guidelines%';

-- For now, we'll use a variable approach
DO $$
DECLARE
    doc_id UUID;
    next_chunk_index INT;
BEGIN
    -- Get the document ID
    SELECT id INTO doc_id FROM documents WHERE name LIKE '%Architectural%' LIMIT 1;
    
    -- Get the next chunk index
    SELECT COALESCE(MAX(chunk_index), 0) + 1 INTO next_chunk_index 
    FROM knowledge_chunks WHERE document_id = doc_id;

    -- ============================================================
    -- EXHIBIT B - Prototype Tables
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit B - Prototype Tables

Discovery West Residential Prototype Table

PROTOTYPE SPECIFICATIONS:
                                    R-1 Small Lot    R-2 Medium Lot    R-3 Large Lot
                                    (SFD RS)         (SFD RS)          (SFD RS)

Maximum Home Height:                30''              30''               30''
(See Exhibit E - Home Height)

Floor Area Ratio (FAR):             50%              50%               50%
(See footnote 4)

LOT REQUIREMENTS:
Width:                              < 65''            65''-90''          > 90''
Typical Depth:                      105''             120''              200'' +
Maximum Coverage:                   50%              50%               35%

LOT SETBACKS:
Front Minimum:                      10''              10''               20''
Front Maximum:                      20'' (5)          20'' (5)           N/A
Front Preferred:                    10''              10''               10''
Side:                               7.5''             10''               20''
Rear:                               5''               5''                20''
Garage - Alley Loaded:              5''               5''                5''
Garage - Front Loaded:              26''              26''               26''

ENCROACHMENTS INTO SETBACKS ALLOWED:
Eaves and gables (regardless of setback): 3''        3''                3''
See City of Bend Development Code 2.1.300 Section F for others

FOOTNOTES:
(1) When abutting an alley, 5 feet plus 1 foot for each foot by which the Home exceeds 15 feet.
(2) Lot width calculation based on the width at the street frontage. Corner lots will have two front and two rear setbacks. The 20 foot side setbacks only applies to lots with 90 feet in width which are designated as Large Lot Residential District on Figure 2.7.3730 Districts in Bend Development Code.
(3) Garage must be accessed from the alley if an alley exists.
(4) The maximum Home square footage, including garage, shall not exceed 50% of Lot square footage. Lots with an ADU have a 55% FAR. This massing restriction is calculated based upon the total square feet of the Home including areas with heights of 5 feet or higher for all Lots. See Exhibit C. Refer to local zoning code for FAR vs. Lot Coverage.
(5) Exceptions will be considered by the ARC on an individual design review basis.
(6) Garages must be setback from the front face/living space of the Home by 16 feet.
(7) A line shall be drawn on a 1:1 slope from the actual grade at the setback line up towards the Home from the Non-Development Easement line and no portion of the proposed Home or Improvements shall encroach beyond this 1:1 slope setback.',
        md5('exhibit_b_prototype_tables'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit B - Prototype Tables'],
        'Exhibit B - Prototype Tables',
        110,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT C - Floor Area Ratio (FAR)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit C - Floor Area Ratio (FAR) for Residential Prototypes R-1, R-2, R-3

DEFINITION:
The Floor Area Ratio (FAR) is a percentage of a home''s massing/volume in proportion to the size of the lot. The maximum home size is determined by multiplying the lot size by the applicable FAR (50%).

CALCULATION EXAMPLE:
A 5500 square foot lot × 0.5 = 2750 sq ft maximum
Using the diagrams in this exhibit, the Home (including the garage floor area) for this 5500 square foot lot may not exceed 2750 square feet.

WHAT COUNTS TOWARD FAR:
- Floor area is calculated to the face of exterior walls
- All attic space 25 feet or more above the ground floor on the two story portion of a home contributes to the FAR
- Similarly, any attic space 15 feet or more above the ground floor on the one story portion of a home contributes to the FAR
- Width used to calculate the attic area contributing to the FAR (see diagram)
- Crawl area contributing to FAR: areas with heights of 5 feet or higher
- Porches, decks and patios are included in this calculation provided they are not more than five feet above finished or existing grade, whichever is lower

DISCOVERY WEST FAR RULES:
- Discovery West applies the FAR to single family detached homes/lots
- The maximum FAR for a home with an ADU is 55%
- Discovery West''s FAR is MORE restrictive than the City of Bend''s FAR standard
- Stairwells are counted once

BASEMENT EXCLUSIONS:
- Basements and daylight basements are NOT included in the FAR provided they comply with the diagrams
- Area wells for basement windows are permitted and do not impact FAR calculations, providing the grade surrounding the area well complies with the diagram
- Attics, crawlspaces or basements with less than 5''-0"" (per diagram) will not be included in the FAR calculation
- Must be less than 5''-0"": Distances greater than five feet measured from existing grade or finished grade, whichever is lower, will create floor space that will be included in FAR calculation',
        md5('exhibit_c_far_calculation'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit C - Floor Area Ratio (FAR)'],
        'Exhibit C - Floor Area Ratio (FAR)',
        112,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT D - Alley Setback
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit D - Alley Setback for Residential Prototypes R-1, R-2, R-3

ALLEY SETBACK REQUIREMENTS:
- Minimum setback from alley: 5''-0"" (5 feet)
- Distance from rear property line: 15''-0"" (15 feet)
- A 1:1 slope requirement applies from the setback line

COMPLIANT DESIGN:
A home complies with Discovery West setback requirements when:
- The structure maintains minimum 5 feet from the alley
- The structure maintains minimum 15 feet from the rear property line
- No portion of the home extends beyond the 1:1 slope line drawn from the setback

NON-COMPLIANT DESIGN:
The shaded area in the diagram does NOT comply with Discovery West setback requirements. Any building mass that extends into this zone violates the setback rules.

NOTE: The 1:1 slope is measured from actual grade at the setback line up towards the home.',
        md5('exhibit_d_alley_setback'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit D - Alley Setback'],
        'Exhibit D - Alley Setback',
        113,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT E - Home Height
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit E - Home Height for Residential Prototypes R-1, R-2, R-3

MAXIMUM HEIGHT REQUIREMENT:
- Maximum building height: 30 feet
- No building shall exceed 30 feet in height as noted in the graphic

HEIGHT MEASUREMENT METHOD:
The ARC measures maximum height from the highest portion of the roof vertically to the natural or finished grade, whichever is lowest. This measurement shall not exceed 30 feet (see example in diagram).

ADDITIONAL ARC AUTHORITY:
In addition to conforming to the City of Bend building height restrictions, the ARC reserves the right to require building heights less than city standards.

NOTE: Height is measured at the highest point of the roof to the lowest applicable grade (natural or finished).',
        md5('exhibit_e_home_height'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit E - Home Height'],
        'Exhibit E - Home Height',
        114,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT G - Street Tree Guidelines
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit G - Street Tree Guidelines

PARK STRIP REQUIREMENTS:
Park strips are to be planted entirely with sod and/or a combination of low-growing shrubs and groundcover. Underground irrigation is required.

STREET TREE REQUIREMENTS:
- A minimum of two street trees are required on all Lot frontages
- Tree caliper: 2"" (measured 6"" above ground level)
- Spacing: 30'' on center

DESIGNED STREETSCAPE TREES (by street location - see map):
- Red Oak (blue streets on map)
- Pin Oak (green streets on map)
- Karpick, Bowhall or Armstrong Red Maple (red/orange streets on map)

NON-DESIGNED STREET TREES (allowed on other streets):
- Red Maple (Red Sunset or Scarlet Sentinel)
- Green Ash (Summit or Patmore)
- Honeylocust (Skyline or Shademaster)
- Crabapple
- Spring Snow
- Chokecherry
- Canada Red
- Hawthorn (Paul''s Scarlet)

NOTE: Refer to the Discovery West Street Tree Map for specific street designations.',
        md5('exhibit_g_street_trees'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit G - Street Tree Guidelines'],
        'Exhibit G - Street Tree Guidelines',
        122,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT I - Non-Development Easement (NDE-1)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit I - Non-Development Easement (NDE-1)

NDE-1 DEFINITION:
Non-Development Easement-1 (NDE-1) - Up to 15 feet of structure may be placed up to the NBZ (No Build Zone) line as shown in the graphic. Eaves and overhangs may extend past the NBZ.

ALLOWED IN THE 15 FOOT AREA BETWEEN NBZ AND NDE:
- Fencing
- Patios
- Decks
- Natural rock retaining walls not exceeding 48 inches in total height
- Other hardscape and landscape

FENCING ADJACENT TO PARK:
Any fencing adjacent to the park must be transparent.

EXCEPTIONS:
Exceptions to these limitations may be made at the sole discretion of the ARC. Any exceptions granted are not considered to set a precedent for any other application.

NDE EASEMENT LANGUAGE:
NDE easement language recorded on the plat supercedes the language on this exhibit.

LANDSCAPING WITHIN NDE:
The area cleared within the NDE is to be stabilized with native grasses as approved in Exhibit F and boulders installed by small scale equipment that minimally disrupts the soil and doesn''t disturb vegetation to remain.

DIMENSIONS:
- NBZ to NDE boundary: 15''-0""
- Structure setback from NBZ: Up to 15''-0"" allowed
- NDE/NBZ are calculated from existing grade',
        md5('exhibit_i_nde1'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit I - Non-Development Easement (NDE-1)'],
        'Exhibit I - Non-Development Easement (NDE-1)',
        134,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT J - Non-Development Easement (NDE-2)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit J - Non-Development Easement (NDE-2)

NDE-2 DEFINITION:
Non-Development Easement 2 (NDE-2) - No structure or improvement (except reestablishment of native grade and wildfire resistant non-irrigated plantings) are allowed except within the NDE slope line from native grade up on a 1:1 slope.

VISIBILITY REQUIREMENTS:
Landscape improvements visible from below shall blend with the native environment as much as possible. The ARC will be the sole judge during design review.

EAVES AND OVERHANGS:
Eaves and overhangs are not prohibited and may intrude into this non-development easement line.

NDE EASEMENT LANGUAGE:
NDE language recorded on the plat supercedes the language on this exhibit.

LANDSCAPING WITHIN NDE:
The area cleared within the NDE is to be stabilized with native grasses as approved in Exhibit F and boulders installed by small scale equipment that minimally disrupts the soil and doesn''t disturb vegetation to remain.

KEY DIFFERENCE FROM NDE-1:
- NDE-1: Up to 15 feet of structure allowed up to NBZ line
- NDE-2: NO structure allowed except within the 1:1 slope line from native grade

1:1 SLOPE CALCULATION:
The 1:1 line is calculated from existing grade.',
        md5('exhibit_j_nde2'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit J - Non-Development Easement (NDE-2)'],
        'Exhibit J - Non-Development Easement (NDE-2)',
        136,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT O - Compliant Porch Column Detail
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit O - Compliant Porch Column Detail

APPROVED PORCH DESIGN:
- Porch floor does NOT extend past the column base in any direction
- Column base sits on or within the porch floor boundary
- Porch post is properly positioned on the column base

NOT APPROVED PORCH DESIGN:
- Porch floor extends past the column base
- This configuration is NOT approved and will not pass ARC review

KEY REQUIREMENT:
The covered entry porch floor must not extend beyond the column base in any direction. The porch post must sit squarely on the column base with the floor contained within.',
        md5('exhibit_o_porch_column'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit O - Compliant Porch Column Detail'],
        'Exhibit O - Compliant Porch Column Detail',
        143,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );

    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT H - Wildfire Mitigation (Part 1 - Construction)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit H - Wildfire Mitigation, Landscape and Construction Requirements For Residential Prototypes R-1, R-2, R-3

The information below outlines the landscape and construction requirements for single family detached Homes in Discovery West. The "Implementing Documents" are the governing documents that will explain the requirements and outline the ramifications if the requirements are not met. The "Authority Having Jurisdiction" is the governing body that enforces the requirements and/or levies fines if requirements are not met.

CONSTRUCTION REQUIREMENTS:

1. Meet special minimum side building setbacks
   - See requirements for Discovery West at City of Bend Development Code
   - Implementing Document: Architectural Guidelines (AG) and City of Bend Development Code (COB)
   - Authority: ARC and City of Bend (COB)

2. Pre-construction site visit with Fire Professional and ARC members required
   - Required after preliminary ARC approval and prior to Final ARC submittal
   - To validate NDE wildfire mitigation plans and other site-specific conditions
   - For lots with a Non-Development Easement: Phase 2, lots 40-45, 67-95 & Phase 4, lots 176-183, 187-188
   - Authority: ARC and COB

3. Use of non-combustible materials is encouraged
   - Such as metal, steel, or cite composite where a fence or screen connects to Home or Building
   - Implementing Document: AG and Rules and Regulations (R&R)
   - Authority: ARC and Owners Association (OA)

4. Use 1/8th inch metal screening for attic and foundation vents
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

5. Use fire-resistant exterior materials or finishes or meet a 20-minute rated exterior wall assembly
   - Implementing Document: AG and R&R
   - Authority: ARC and COB

6. Use concrete tile, slate, clay tile, high-relief asphalt composition shingles, metal, or other roof coverings equivalent to ASTM E108
   - Wood shingles are prohibited
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

7. Use pavers, concrete, wood alternative composite decking, or fire-retardant-treated wood for patios, decks, or outdoor living spaces
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

8. Minimum 12 ft wide driveway with 15 feet vertical clearances
   - Implementing Document: AG and R&R
   - Authority: ARC and OA',
        md5('exhibit_h_construction'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit H - Wildfire Mitigation'],
        'Exhibit H - Wildfire Mitigation',
        128,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT H - Wildfire Mitigation (Part 2 - Landscape Zone 1)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit H - Wildfire Mitigation Landscape Requirements Zone 1 (0''-30'' from home)

ZONE 1 LANDSCAPE REQUIREMENTS (0 to 30 feet from home):

1. Create a "fire-free" area within five feet of structures
   - Use non-flammable landscaping materials and high moisture plants
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

2. Keep conifer tree limbs at least 5 ft from structure (vertically and horizontally)
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

3. Mulch is a combustible material and is discouraged in Zone 1 outside of the "fire-free" area
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

4. Install non-combustible material underneath and within six inches adjacent to a fence
   - If bark is present, six inches of gravel is required
   - If bare dirt is adjacent to the fence, no gravel is required
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

5. Existing and new conifers must be 30'' apart from trunk to trunk on a Lot
   - Conifer trees in Zone 1 may be included in a group of two if the other tree is in Zone 2
   - Does not apply to lots with a Non-Development Easement (NDE) portion of Phases 2, lots 40-45, 67-95 and Phase 4, lots 176-183, 187-188
   - Authority: ARC and OA

FOR LOTS WITH A NON-DEVELOPMENT EASEMENT:
- No new conifer trees unless approved by ARC
- Deciduous trees from the Approved Fire-Resistant Plant list allowed
- Remove ponderosa pines (pp) less than 5-inch DBH, unless 20 feet or more from nearest pp or group of pp
- Group size determination is situational and will be reviewed during required site visit
- Remove Juniper trees',
        md5('exhibit_h_zone1'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit H - Wildfire Mitigation', 'Zone 1'],
        'Exhibit H - Wildfire Mitigation Zone 1',
        128,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT H - Wildfire Mitigation (Part 3 - Landscape Zone 2)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit H - Wildfire Mitigation Landscape Requirements Zone 2 (30''-100'' from home or to BPRD boundary)

ZONE 2 LANDSCAPE REQUIREMENTS (30 to 100 feet from home):

1. Groups of no more than two conifer trees are allowed
   - Trees in a group shall be of similar size
   - Spacing between a group of conifer trees as measured from the nearest trunk to the nearest trunk in a group or single conifer tree shall be no less than 30'' trunk to trunk
   - Does not apply to Non-Development Easement (NDE) portion of Phases 2, lots 40-45, 67-95 and Phase 4, lots 176-183, 187-188
   - Authority: ARC and OA

FOR PHASE 2, LOTS 40-45, 67-95 AND PHASE 4, LOTS 176-183, 187-188:
- Remove Juniper trees less than 12-inch DBH

2. Clear brush and cut grass under conifers and within drip lines
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

3. Prune mature conifers so the lowest hanging branches are 4 ft above the ground
   - Or 3x the height of any brush near the drip line
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

4. Mow or prune to break up dense vegetation
   - Does not apply to lots with a Non-Development Easement (NDE), Phase 2, lots 40-45, 67-95 and Phase 4, lots 176-183, 187-188
   - Authority: ARC and OA

FOR LOTS WITH NON-DEVELOPMENT EASEMENT:
- Thin native brush to individual plants spaced 3x the height of the plant
- Favor wax currant over Manzanita and Bitterbrush
- Non irrigated fire-resistant plants may be planted in the cleared area between native brush

5. Only approved, fire resistant plants and trees may be planted
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

6. Keep roofs, gutters, eaves, and decks clear of leaves, pine needles, and other flammable debris
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

7. Remove all juniper, sage, bitterbrush, manzanita and rabbitbrush
   - Does not apply to lots with a Non-Development Easement (NDE) Phase 2, lots, 40-45, 67-95 and Phase 4, lots 176-183, 187-188
   - Authority: ARC and OA

FOR LOTS WITH NON-DEVELOPMENT EASEMENT (alternative requirements):
- Thin native brush to individual plants spaced 3x the height of the plant
- Favor wax currant over Manzanita and Bitterbrush
- Non irrigated fire-resistant plants may be planted in the cleared area between native brush

8. Consider fire-resistant material for patio furniture, play structures, swing sets, etc.
   - Implementing Document: AG
   - Authority: Owner',
        md5('exhibit_h_zone2'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit H - Wildfire Mitigation', 'Zone 2'],
        'Exhibit H - Wildfire Mitigation Zone 2',
        129,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );
    
    next_chunk_index := next_chunk_index + 1;

    -- ============================================================
    -- EXHIBIT H - Wildfire Mitigation (Part 4 - Zone 3 and General)
    -- ============================================================
    INSERT INTO knowledge_chunks (
        content, content_hash, document_id, document_name, document_type,
        section_hierarchy, section_title, page_number, chunk_index,
        is_binding, source_file_path
    ) VALUES (
        'Exhibit H - Wildfire Mitigation Landscape Requirements Zone 3 (over 100'' from Home) and General Requirements

ZONE 3 LANDSCAPE REQUIREMENTS (over 100 feet from Home):
Does not apply to lots with a Non-Development Easement.

1. Only approved, fire resistant plants and trees may be planted
   - Existing native vegetation may remain
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

2. Stumps from recently cut trees to be cut at natural grade
   - Decorative aged stumps, root balls and ghost trees are not allowed within Zone 1
   - Implementing Document: AG
   - Authority: AG and OA

3. Clear brush and cut grass under conifers and within drip lines
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

4. Prune mature conifers so lowest hanging branches are 4 ft above ground
   - Or 3x the height of any brush near drip line
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

5. Mow or prune to break up dense vegetation
   - Implementing Document: AG and R&R
   - Authority: ARC and OA

6. Consider fire-resistant material for patio furniture, play structures, swing sets, etc.
   - Implementing Document: AG
   - Authority: Owner

7. Stumps from recently cut trees to be cut at natural grade
   - Decorative aged stumps, root balls and ghost trees are not allowed within Zone 1
   - Implementing Document: AG
   - Authority: ARC and OA

GENERAL LANDSCAPE REQUIREMENTS (all zones):

1. Attain and maintain Firewise USA recognition
   - Implementing Document: CCRs
   - Authority: OA

2. During wildfire season, leave a hose connected to each outside hose bib
   - Implementing Document: AG and R&R
   - Authority: ARC, OA',
        md5('exhibit_h_zone3_general'),
        doc_id,
        'Architectural Design Guidelines',
        'design_guidelines',
        ARRAY['Exhibits', 'Exhibit H - Wildfire Mitigation', 'Zone 3'],
        'Exhibit H - Wildfire Mitigation Zone 3 and General',
        130,
        next_chunk_index,
        true,
        'design-guidelines/Discovery-West-Architectural-Guidelines.pdf'
    );

    RAISE NOTICE 'Successfully inserted 12 exhibit chunks for document_id: %', doc_id;
END $$;

-- ============================================================
-- IMPORTANT: After running this SQL, you need to generate embeddings
-- for these new chunks using the Document Ingestion workflow
-- or a separate embedding script
-- ============================================================

