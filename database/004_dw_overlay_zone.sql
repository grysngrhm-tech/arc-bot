-- ============================================================================
-- Discovery West Master Planned Development (City of Bend Development Code)
-- Article XIX of BDC Chapter 2.7
-- Source: https://bend.municipal.codes/BDC/2.7_ArtXIX
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Document Record
-- ============================================================================
INSERT INTO documents (
    document_name,
    document_type,
    storage_path,
    is_current,
    uploaded_at,
    metadata
) VALUES (
    'City of Bend Development Code - Discovery West',
    'city_code',
    'https://bend.municipal.codes/BDC/2.7_ArtXIX',
    true,
    NOW(),
    '{"source": "City of Bend Municipal Code", "chapter": "2.7", "article": "XIX", "is_binding": true}'
) ON CONFLICT (document_name) DO UPDATE SET
    is_current = true,
    metadata = EXCLUDED.metadata
RETURNING id;

-- ============================================================================
-- STEP 2: Create Knowledge Chunks
-- Note: Replace 'DOCUMENT_ID_HERE' with the actual document ID from Step 1
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Chunk 1: Section 2.7.3700 - Discovery West Master Planned Development (Intro)
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    1,
    '2.7.3700 Discovery West Master Planned Development.

The Discovery West Master Planned Development establishes special development standards for the West UGB Expansion Area (Master Plan Area 1) under BCP Chapter 11. These standards implement the Bend Comprehensive Plan policies for westward urban expansion.

[Ord. NS-2338, 2019]',
    '2.7.3700 Discovery West Master Planned Development',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3700"]',
    '{"section_number": "2.7.3700", "is_binding": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3700"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 2: Section 2.7.3710 - Purpose
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    2,
    '2.7.3710 Purpose.

The purpose of the Discovery West Master Planned Development is to implement Bend Comprehensive Plan policies regarding the West UGB Expansion Area (Master Plan Area 1 under BCP Chapter 11), and to create a new mixed-use neighborhood with the following goals:

A. Provide a variety of housing types and employment opportunities.

B. Locate higher density housing and employment lands adjacent to collector and arterial streets or public parks.

C. Create opportunities for live/work townhomes and small-scale businesses in selected locations to foster a mixed-use residential neighborhood.

D. Promote pedestrian and other multi-modal transportation options.

E. Ensure compatibility of uses within the development and with the surrounding area.

F. Create an interconnected system of streets with standards appropriate to the intensity and type of adjacent land use.

G. Create safe and attractive streetscapes that will meet emergency access requirements and enhance pedestrian and bicycle access and safety.

H. Implement the relevant policies of the Bend Comprehensive Plan:

  1. The central planning concepts are to: provide a limited westward expansion that complements the pattern of complete communities that began with NorthWest Crossing with the existing concentration of commercial, employment, cultural and recreational uses along Century Drive, provide variety of lot sizes and housing types that support family housing, provide a pedestrian and bicycle-friendly neighborhood, and include fire resistant structures and defensible space.

  2. Establishing appropriate development regulations to implement the transect concept; develop measures to make the development and structures fire resistant; and implement RL plan designation densities consistent with policies for the West Area.

  3. Include a minimum of 8.4 percent townhomes (minimum of 54) and a minimum of 28 percent multi-unit and duplex/triplex/quadplex units (minimum 187 units). The minimum required units (total and by housing type) shall be monitored and enforced through the subdivision process, with deed restrictions recorded against individual lots to specify unit minimums and ranges by housing type.

  4. Provide a minimum of 12 units of affordable housing.

[Ord. NS-2431, 2022; Ord. NS-2423, 2021; Ord. NS-2338, 2019]',
    '2.7.3710 Purpose',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3710"]',
    '{"section_number": "2.7.3710", "is_binding": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3710"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 3: Section 2.7.3720 - Applicability
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    3,
    '2.7.3720 Applicability.

The Discovery West Master Planned Development standards apply to the property identified in Figure 2.7.3720, further identified as West Area Master Plan Area 1 in BCP Chapter 11. The special standards of this article establish the permitted uses, special use standards and development standards applicable to the Discovery West Master Planned Development.

Figure 2.7.3720 shows the boundary of the Discovery West Master Planned Development area within the City of Bend.

[Ord. NS-2338, 2019]',
    '2.7.3720 Applicability',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3720"]',
    '{"section_number": "2.7.3720", "is_binding": true, "has_figure": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3720"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 4: Section 2.7.3730 - Districts
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    4,
    '2.7.3730 Districts.

This section was recently amended by Ordinance NS-2541, codified in December 2025.

A. Large Lot Residential District.
  1. Purpose. The purpose of the Large Lot Residential District is to implement the low-density residential lot component of the west side transect as identified in the Bend Comprehensive Plan. The increased setback requirements reflect the proximity to National Forest lands and serve as a wildfire protection measure.

B. Standard Lot Residential District.
  1. Purpose. The purpose of the Standard Lot Residential District is to allow higher density detached single-unit and duplex lots on smaller lots than otherwise permitted in the underlying Low-Density Residential zone.

C. Residential Mixed-Use District.
  1. Purpose. The Residential Mixed-Use District is applied in locations adjacent to collector or arterial streets, Commercial Limited or Mixed Employment zones, or public parks to satisfy BCP Policy by locating higher density residential in these locations.
  2. Density. The Residential Mixed-Use District will accommodate at least 54 townhomes and at least 187 multi-unit, duplex, triplex or quadplex residential units as required by BCP Policy 11-124.

D. Commercial/Mixed Employment District.
  1. Purpose and Applicability. The Commercial/Mixed Employment District applies to all land zoned Commercial Limited and Mixed Employment within the Discovery West Master Planned Development. The purpose is to provide commercial and employment opportunities while ensuring compatibility with adjacent residential uses.

E. Definitions. The following definitions apply to uses, building types and standards that are specific to the Discovery West Master Planned Development:

  - Attached single-unit as used in Bend Comprehensive Plan Policy 11-124, and as applicable to the Discovery West Master Planned Development, refers to townhomes, live-work townhomes, and any type of cluster housing development.

  - Cluster housing development refers to detached single-unit cottages or attached mews houses in a cluster around a central shared open space. Cottages or mews houses must be located on platted lots or as units in a condominium.

  - Cottage means a detached dwelling unit in a cluster housing development.

  - Live/work townhome means a residential townhome in which a business may be operated on the ground floor. A live/work dwelling is allowed instead of, or in addition to, a home business as defined by this Code.

  - Mews house means an attached dwelling unit in a cluster housing development, with common walls on one or both side lot lines.

  - Transect as used herein refers to a gradient from higher densities along Skyline Ranch Road to lower density and open space along the western edge in this area which approaches National Forest land and wildland-urban interface.

[Ord. NS-2541, 2025; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3730 Districts',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3730"]',
    '{"section_number": "2.7.3730", "is_binding": true, "has_definitions": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3730"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 5: Section 2.7.3740 - Review Procedures
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    5,
    '2.7.3740 Review Procedures.

The following review procedures are applicable to uses within the Discovery West Master Planned Development:

A. Design Review. Townhomes, live/work townhomes, cluster housing, duplexes, triplexes and quadplexes located on lots specifically approved as such will not be subject to design standards of the underlying zone but must comply with residential design standards in BDC Chapter 3.6.

B. Site Plan/Design Review. Multi-unit development greater than four units and buildings in the Commercial/Mixed Employment District will not be subject to the provisions of BDC 4.2.600, Design Review, but must comply with the applicable residential or commercial design standards in BDC 3.6 and Site Plan Review standards in BDC 4.2.500.

C. Conditional Use Permit. Conditionally permitted uses require a Conditional Use Permit in accordance with BDC Chapter 4.4.

D. Shelters are subject to BDC 3.6.600, Shelters, single-room occupancies are subject to BDC 3.6.200(O), Single-Room Occupancy, and the conversion of a building or a portion of a building from commercial or industrial use to a residential use is subject to BDC 3.6.200(C).

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3740 Review Procedures',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3740"]',
    '{"section_number": "2.7.3740", "is_binding": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3740"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 6: Section 2.7.3750 - Large Lot Residential District
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    6,
    '2.7.3750 Large Lot Residential District.

A. Permitted Uses.
  1. Detached single-unit dwelling.
  2. Accessory uses and structures.
  3. Accessory dwelling unit.
  4. Family childcare home (16 or fewer children).
  5. Neighborhood, community, and regional parks.
  6. Home business (Class A, Class B) subject to the provisions of BDC 3.6.200(N).
  7. Duplexes.
  8. Triplexes on lots specifically designated for development as such on an approved subdivision tentative plan.
  9. Shelters. See BDC 3.6.600, Shelters.
  10. Single-Room Occupancy. See BDC 3.6.200(O), Single-Room Occupancy.
  11. For income qualified housing, see BDC 3.6.250.

B. Height Standards. The height standards of the RL Zone apply.

C. Lot Area and Dimensions. The lot area and dimensions of the RL Zone apply.

D. Lot Coverage. The lot coverage standards of the RL Zone apply.

E. Setbacks. The setbacks of the RL Zone apply, with exception that a 20-foot side yard setback is required as a wildfire protection measure. Notwithstanding BDC 2.1.300(F)(5), Architectural Features, eaves and similar architectural projections may not extend into this setback.

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3750 Large Lot Residential District',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3750"]',
    '{"section_number": "2.7.3750", "is_binding": true, "district_type": "Large Lot Residential", "source_url": "https://bend.municipal.codes/BDC/2.7.3750"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 7: Section 2.7.3760 - Standard Lot Residential District
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    7,
    '2.7.3760 Standard Lot Residential District.

A. Permitted Uses.
  1. Detached single-unit dwelling.
  2. Accessory uses and structures.
  3. Accessory dwelling unit.
  4. Family childcare home (16 or fewer children).
  5. Neighborhood, community, and regional parks.
  6. Home business (Class A, Class B) subject to the provisions of BDC 3.6.200(N).
  7. Duplexes.
  8. Triplexes on lots specifically designated for development as such on an approved subdivision tentative plan.
  9. Shelters. See BDC 3.6.600, Shelters.
  10. Single-Room Occupancy. See BDC 3.6.200(O), Single-Room Occupancy.
  11. For income qualified housing, see BDC 3.6.250.

B. Height Standards. The height standards of the RL Zone apply.

C. Lot Area and Dimensions. The lot area and dimensions of the RL Zone apply.

D. Lot Coverage. The lot coverage standards of the RL Zone apply.

E. Setbacks. The setbacks of the RL Zone apply, with exception that a 20-foot side yard setback is required as a wildfire protection measure. Notwithstanding BDC 2.1.300(F)(5), Architectural Features, eaves and similar architectural projections may not extend into this setback.

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3760 Standard Lot Residential District',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3760"]',
    '{"section_number": "2.7.3760", "is_binding": true, "district_type": "Standard Lot Residential", "source_url": "https://bend.municipal.codes/BDC/2.7.3760"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 8: Section 2.7.3770 - Residential Mixed-Use District (Part 1: Uses & Standards)
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    8,
    '2.7.3770 Residential Mixed-Use District.

A. Permitted Uses.
  1. All uses permitted or conditionally permitted in the Standard Lot Residential District.
  2. Multi-unit housing.
  3. Townhomes.
  4. Live/work townhomes subject to the provisions of this district.
  5. Cluster housing development.
  6. Quadplexes.
  7. For income qualified housing, see BDC 3.6.250.

B. Setbacks. The setbacks of the RM Zone apply unless otherwise specified in the special use standards below (e.g., zero setback for common walls of townhome or mews house).

C. Height Standards. The following height standards apply in the Residential Mixed-Use District:
  - Maximum building height follows RM Zone standards unless otherwise specified.

D. Lot Area and Dimensions. Except as otherwise specified in this section, the standards of the RM Zone apply.

E. Lot Coverage. The lot coverage standards of the RM Zone apply to detached single-unit dwellings, duplexes, and triplexes. There is no lot coverage limitation for other uses in the Residential Mixed-Use District.

F. Platting Lots for Specific Uses. The following standards apply for the Residential Mixed-Use District:
  1. The tentative plan application for a subdivision phase in the Residential Mixed-Use District must specify the housing type and a minimum and maximum number of residential units intended for each lot.
  2. A deed restriction must be recorded with each lot in the RMUD intended for duplex, triplex, quadplex, multi-unit or townhome dwellings specifying a minimum and maximum range of housing units to ensure minimum housing density requirements are met.

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3770 Residential Mixed-Use District - Uses and Standards',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3770"]',
    '{"section_number": "2.7.3770", "is_binding": true, "district_type": "Residential Mixed-Use", "source_url": "https://bend.municipal.codes/BDC/2.7.3770"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 9: Section 2.7.3770 - Residential Mixed-Use District (Part 2: Live/Work Standards)
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    9,
    '2.7.3770 Residential Mixed-Use District - Special Standards for Live/Work Townhomes.

G. Special Standards for Live/Work Townhomes.

  1. The location of lots where live/work dwellings may be sited must be specified in the tentative plan application for that development phase.

  2. Live/work townhome lots may be designed without frontage on a public street when the lots abut the commercial lot to be developed as a plaza at the northwest corner of the Skyline Ranch Road/Ochoco Lane intersection.

  3. The commercial or office portion of the building may not exceed 50 percent of the square footage of the entire building, excluding any garage.

  4. Vehicle and bicycle parking must be in accordance with BDC Chapter 3.3, Vehicle Parking, Loading and Bicycle Parking.

  5. No outside storage of materials or goods related to the work occupation or business is permitted.

  6. If the business is open to the public, public access must be through the work area front door and the business may not be open to clients or the public before 7:00 a.m. or after 10:00 p.m.

  7. The residential portion of live/work townhomes may include a primary residence as well as an accessory dwelling unit. Residential units on any designated live/work townhome lot may be operated as short-term rentals subject to BDC 3.6.500.

  8. The following uses are allowed in live/work townhomes:
    a. Offices and clinics;
    b. Childcare facility (13 or more children);
    c. Food and beverage services less than 2,000 square feet (with or without alcohol) excluding automobile-dependent and automobile-oriented, drive-in, and drive-through uses;
    d. Laundromats and dry cleaners;
    e. Retail goods and services;
    f. Personal services (e.g., barber shops, salons, similar uses);
    g. Repair services, conducted entirely within building; excluding vehicle repair, small engine repair and similar services;
    h. Home business (Class A, B and C) subject to the provisions of BDC 3.6.200(N).

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3770 Residential Mixed-Use District - Live/Work Townhomes',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3770"]',
    '{"section_number": "2.7.3770.G", "is_binding": true, "district_type": "Residential Mixed-Use", "use_type": "Live/Work Townhomes", "source_url": "https://bend.municipal.codes/BDC/2.7.3770"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 10: Section 2.7.3770 - Residential Mixed-Use District (Part 3: Cluster Housing)
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    10,
    '2.7.3770 Residential Mixed-Use District - Special Standards for Cluster Housing Developments.

H. Special Standards for Cluster Housing Developments.

Cluster housing development provides an alternative housing type to satisfy the attached single-unit housing requirement of BCP Policy. The cluster housing concept includes the following characteristics:

  • The development standards for cottage and mews houses foster the creation of a small community within the larger overall Discovery West Master Planned Development.

  • The site is designed with a coherent concept in mind, including shared functional open space, off-street parking areas, access within the site and from the site, and consistent landscaping.

  • A cluster housing development must have a homeowners association for the ownership and management of shared open space and any common parking areas.

1. General Development Requirements.
  a. There is no minimum lot size for cluster housing developments;
  b. Cottages or mews houses must be located on platted lots or as units in a condominium development and may share use of common facilities such as, but not limited to, a party room, tool shed, garden, playground, or similar facility;
  c. New lots created as a part of a cluster housing development within Discovery West are not required to have frontage on either a public or private street;

  d. Setbacks. A minimum setback of 10 feet and a maximum of 20 feet is required from any property line abutting a street. A minimum setback of five feet is required abutting all other outer boundaries of the cluster housing development site. No minimum setback is required between lots within the cluster housing development.

  e. Height. Maximum building height is 25 feet for cottages and 35 feet for mews houses.

  f. Building Coverage. Maximum building coverage per lot is 65 percent.

  g. Open Space. A minimum of 250 square feet of common open space per dwelling unit is required. Required open space must be a minimum of 500 square feet in size with a minimum dimension of 20 feet.

  h. Parking. Parking must comply with BDC Chapter 3.3, Vehicle Parking, Loading and Bicycle Parking.

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3770 Residential Mixed-Use District - Cluster Housing',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3770"]',
    '{"section_number": "2.7.3770.H", "is_binding": true, "district_type": "Residential Mixed-Use", "use_type": "Cluster Housing", "source_url": "https://bend.municipal.codes/BDC/2.7.3770"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 11: Section 2.7.3780 - Commercial/Mixed Employment District
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    11,
    '2.7.3780 Commercial/Mixed Employment District.

A. Development Standards. The development standards of the underlying zone apply within the Commercial/Mixed Employment District, with the exception of the additional limitations below for lots with frontage on Skyliners Road:

  1. Height Limitation. For lots that abut Skyliners Road, the maximum building height is 35 feet.

  2. Site Access. No vehicular access driveways are allowed onto Skyliners Road.

B. For income qualified housing, see BDC 3.6.250.

[Ord. NS-2515, 2024; Ord. NS-2431, 2022; Ord. NS-2338, 2019]',
    '2.7.3780 Commercial/Mixed Employment District',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3780"]',
    '{"section_number": "2.7.3780", "is_binding": true, "district_type": "Commercial/Mixed Employment", "source_url": "https://bend.municipal.codes/BDC/2.7.3780"}'
);

-- ----------------------------------------------------------------------------
-- Chunk 12: Section 2.7.3790 - Special Street Standards
-- ----------------------------------------------------------------------------
INSERT INTO knowledge_chunks (
    document_id,
    chunk_index,
    content,
    section_title,
    section_hierarchy,
    metadata
) VALUES (
    (SELECT id FROM documents WHERE document_name = 'City of Bend Development Code - Discovery West'),
    12,
    '2.7.3790 Special Street Standards.

Figure 2.7.3790.A depicts the street type, tentative street location and alignment in the Discovery West Master Planned Development. Table 2.7.3790 defines the standards to correspond to the street types shown in the figure.

Any City street standard adopted after the effective date of the ordinance codified in this chapter, which permits a lesser street standard, may be applied to the Discovery West Master Planned Development area subject to meeting all of the following:

1. Average daily traffic volume does not exceed 300 ADT.

2. The street is connected to a grid street pattern at both block ends.

3. Blocks must have dedicated public alley access constructed to Discovery West standards.

4. "No Parking" zones must be established 55 feet from the centerline of intersecting local streets.

5. For block lengths exceeding 300 feet, "No Parking" zones must be established on both sides of the street spaced no greater than 250 feet apart. Each zone must be a minimum of 30 feet in length.

TABLE 2.7.3790 - STREET STANDARDS FOR DISCOVERY WEST

Street Type | Right-of-Way | Pavement Width | Sidewalk | Bike Lane | Parking
-----------|--------------|----------------|----------|-----------|--------
Collector | 70 feet | 42 feet | Both sides, 6 ft | Both sides | Both sides
Local Street | 54 feet | 32 feet | Both sides, 5 ft | None | Both sides
Alley | 20 feet | 16 feet | None | None | None
Shared Street | 40 feet | 24 feet | One side, 6 ft | Shared | One side

Note: Specific dimensions and requirements are subject to Figure 2.7.3790.A and City Engineering standards.

[Ord. NS-2338, 2019]',
    '2.7.3790 Special Street Standards',
    '["BDC Ch. 2.7", "Article XIX", "2.7.3790"]',
    '{"section_number": "2.7.3790", "is_binding": true, "has_figure": true, "has_table": true, "source_url": "https://bend.municipal.codes/BDC/2.7.3790"}'
);

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Run this after inserting to verify the chunks:
-- SELECT 
--     kc.chunk_index,
--     kc.section_title,
--     LEFT(kc.content, 80) as content_preview,
--     kc.metadata->>'section_number' as section_num
-- FROM knowledge_chunks kc
-- JOIN documents d ON kc.document_id = d.id
-- WHERE d.document_name = 'City of Bend Development Code - Discovery West'
-- ORDER BY kc.chunk_index;

