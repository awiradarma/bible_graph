:param {
  // Define the file path root and the individual file names required for loading.
  // https://neo4j.com/docs/operations-manual/current/configuration/file-locations/
  file_path_root: 'file:///', // Change this to the folder your script can access the files at.
  file_0: 'BibleData-Book.csv',
  file_1: 'AlamoPolyglot.csv',
  file_2: 'BibleData-Person.csv',
  file_3: 'BibleData-Reference.csv',
  file_4: 'BibleData-PersonLabel.csv',
  file_5: 'BibleData-PersonRelationship.csv',
  file_6: 'BibleData-PersonVerse.csv'
};

// CONSTRAINT creation
// -------------------
//
// Create node uniqueness constraints, ensuring no duplicates for the given node label and ID property exist in the database. This also ensures no duplicates are introduced in future.
//
// NOTE: The following constraint creation syntax is generated based on the current connected database version 5.26.0.
CREATE CONSTRAINT `book_id_Book_uniq` IF NOT EXISTS
FOR (n: `Book`)
REQUIRE (n.`book_id`) IS UNIQUE;
CREATE CONSTRAINT `id_Verse_uniq` IF NOT EXISTS
FOR (n: `Verse`)
REQUIRE (n.`id`) IS UNIQUE;
CREATE CONSTRAINT `id_Person_uniq` IF NOT EXISTS
FOR (n: `Person`)
REQUIRE (n.`id`) IS UNIQUE;
CREATE CONSTRAINT `reference_id_VerseID_uniq` IF NOT EXISTS
FOR (n: `VerseID`)
REQUIRE (n.`reference_id`) IS UNIQUE;
CREATE CONSTRAINT `person_label_id_PersonLabel_uniq` IF NOT EXISTS
FOR (n: `PersonLabel`)
REQUIRE (n.`person_label_id`) IS UNIQUE;

:param {
  idsToSkip: []
};

// NODE load
// ---------
//
// Load nodes in batches, one node label at a time. Nodes will be created using a MERGE statement to ensure a node with the same label and ID property remains unique. Pre-existing nodes found by a MERGE statement will have their other properties set to the latest values encountered in a load file.
//
// NOTE: Any nodes with IDs in the 'idsToSkip' list parameter will not be loaded.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row
WHERE NOT row.`book_id` IN $idsToSkip AND NOT toInteger(trim(row.`book_id`)) IS NULL
CALL {
  WITH row
  MERGE (n: `Book` { `book_id`: toInteger(trim(row.`book_id`)) })
  SET n.`book_id` = toInteger(trim(row.`book_id`))
  SET n.`book_name` = row.`book_name`
  SET n.`chapter_count` = toInteger(trim(row.`chapter_count`))
  SET n.`verse_count` = toInteger(trim(row.`verse_count`))
  SET n.`christian_sequence` = toInteger(trim(row.`christian_sequence`))
  SET n.`usx_code` = row.`usx_code`
  SET n.`writer_id` = row.`writer_id`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_1) AS row
WITH row
WHERE NOT row.`id` IN $idsToSkip AND NOT toInteger(trim(row.`id`)) IS NULL
CALL {
  WITH row
  MERGE (n: `Verse` { `id`: toInteger(trim(row.`id`)) })
  SET n.`id` = toInteger(trim(row.`id`))
  SET n.`book_id` = toLower(trim(row.`book_id`)) IN ['1','true','yes']
  SET n.`chapter` = toInteger(trim(row.`chapter`))
  SET n.`verse` = toInteger(trim(row.`verse`))
  SET n.`web` = row.`world_english_bible_web`
  SET n.`kjv` = row.`king_james_bible_kjv`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_2) AS row
WITH row
WHERE NOT row.`person_id` IN $idsToSkip AND NOT row.`person_id` IS NULL
CALL {
  WITH row
  MERGE (n: `Person` { `id`: row.`person_id` })
  SET n.`id` = row.`person_id`
  SET n.`name` = row.`person_name`
  SET n.`surname` = row.`surname`
  SET n.`unique_attribute` = row.`unique_attribute`
  SET n.`sex` = row.`sex`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_3) AS row
WITH row
WHERE NOT row.`reference_id` IN $idsToSkip AND NOT row.`reference_id` IS NULL
CALL {
  WITH row
  MERGE (n: `VerseID` { `reference_id`: row.`reference_id` })
  SET n.`reference_id` = row.`reference_id`
  SET n.`book_id` = toLower(trim(row.`book_id`)) IN ['1','true','yes']
  SET n.`usx_code` = row.`usx_code`
  SET n.`chapter` = toInteger(trim(row.`chapter`))
  SET n.`verse` = toInteger(trim(row.`verse`))
  SET n.`verse_sequence` = toInteger(trim(row.`verse_sequence`))
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row
WHERE NOT row.`person_label_id` IN $idsToSkip AND NOT row.`person_label_id` IS NULL
CALL {
  WITH row
  MERGE (n: `PersonLabel` { `person_label_id`: row.`person_label_id` })
  SET n.`person_label_id` = row.`person_label_id`
  SET n.`person_id` = row.`person_id`
  SET n.`english_label` = row.`english_label`
  SET n.`hebrew_label` = row.`hebrew_label`
  SET n.`hebrew_label_transliterated` = row.`hebrew_label_transliterated`
  SET n.`hebrew_label_meaning` = row.`hebrew_label_meaning`
  SET n.`hebrew_strongs_number` = row.`hebrew_strongs_number`
  SET n.`greek_label` = row.`greek_label`
  SET n.`greek_label_transliterated` = row.`greek_label_transliterated`
  SET n.`greek_label_meaning` = row.`greek_label_meaning`
  SET n.`greek_strongs_number` = row.`greek_strongs_number`
  SET n.`label_reference_id` = row.`label_reference_id`
  SET n.`label_type` = row.`label_type`
  SET n.`label-given_by_god` = row.`label-given_by_god`
  SET n.`label_notes` = row.`label_notes`
  SET n.`person_label_count` = toInteger(trim(row.`person_label_count`))
} IN TRANSACTIONS OF 10000 ROWS;


// RELATIONSHIP load
// -----------------
//
// Load relationships in batches, one relationship type at a time. Relationships are created using a MERGE statement, meaning only one relationship of a given type will ever be created between a pair of nodes.
LOAD CSV WITH HEADERS FROM ($file_path_root + $file_1) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `Book` { `book_id`: toInteger(trim(row.`book_id`)) })
  MATCH (target: `Verse` { `id`: toInteger(trim(row.`id`)) })
  MERGE (source)-[r: `CONTAINS`]->(target)
  SET r.`chapter` = row.`chapter`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_0) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `Person` { `id`: row.`writer_id` })
  MATCH (target: `Book` { `book_id`: toInteger(trim(row.`book_id`)) })
  MERGE (source)-[r: `WROTE`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_5) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `Person` { `id`: row.`person_id_1` })
  MATCH (target: `Person` { `id`: row.`person_id_2` })
  MERGE (source)-[r: `IS_RELATED_TO`]->(target)
  SET r.`type` = row.`relationship_type`
  SET r.`category` = row.`relationship_category`
  SET r.`verse` = row.`reference_id`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_3) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `VerseID` { `reference_id`: row.`reference_id` })
  MATCH (target: `Verse` { `id`: toInteger(trim(row.`verse_sequence`)) })
  MERGE (source)-[r: `REFERENCES`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_6) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `VerseID` { `reference_id`: row.`reference_id` })
  MATCH (target: `Person` { `id`: row.`person_id` })
  MERGE (source)-[r: `MENTIONS`]->(target)
  SET r.`label` = row.`person_label`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_3) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `Book` { `book_id`: toInteger(trim(row.`book_id`)) })
  MATCH (target: `VerseID` { `reference_id`: row.`reference_id` })
  MERGE (source)-[r: `HAS`]->(target)
  SET r.`usx_code` = row.`usx_code`
  SET r.`chapter` = toInteger(trim(row.`chapter`))
  SET r.`verse` = toInteger(trim(row.`verse`))
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `Person` { `id`: row.`person_id` })
  MATCH (target: `PersonLabel` { `person_label_id`: row.`person_label_id` })
  MERGE (source)-[r: `ALSO_KNOWN_AS`]->(target)
  SET r.`sequence` = row.`person_label_count`
  SET r.`alias` = row.`english_label`
} IN TRANSACTIONS OF 10000 ROWS;

LOAD CSV WITH HEADERS FROM ($file_path_root + $file_4) AS row
WITH row 
CALL {
  WITH row
  MATCH (source: `PersonLabel` { `person_label_id`: row.`person_label_id` })
  MATCH (target: `VerseID` { `reference_id`: row.`label_reference_id` })
  MERGE (source)-[r: `FOUND_IN`]->(target)
} IN TRANSACTIONS OF 10000 ROWS;
