/**
 * top_density_songs: Find the top 50 most dense songs in the million song dataset.
 *
 * Required parameters:
 *
 * -param OUTPUT_PATH Output path for script data (e.g. s3n://my-output-bucket/millionsong)
 */

-- Default Parameters
-- %default OUTPUT_PATH 's3n://hawk-example-output-data/$MORTAR_EMAIL_S3_ESCAPED/top-density-songs'
%default OUTPUT_PATH 's3n://tedjgit-hawk-example-data/top_density_songs'

-- User-Defined Functions (UDFs)
REGISTER '../udfs/python/millionsong.py' USING streaming_python AS millionsong;

-- Macros
IMPORT '../macros/millionsong.pig';

-- Load up the million song dataset
-- using our ALL_SONGS() pig macro from millionsong.pig
-- (we can substitute ONE_SONGS_FILE() to get a smaller dataset)
songs = ONE_SONGS_FILE();

-- Use FILTER to get only songs that have a duration
filtered_songs = FILTER songs BY duration > 0;

-- Use FOREACH to run calculations on every row.
-- Here, we calculate density (sounds per second) using 
-- the the Python UDF density function from millionsong.py
song_density = FOREACH filtered_songs 
              GENERATE artist_name, 
                       title,
                       millionsong.density(segments_start, duration);

-- Get the top 50 most dense songs
-- by using ORDER and then LIMIT
density_ordered = ORDER song_density BY density DESC;
top_density     = LIMIT density_ordered 50;

-- STORE the top 50 songs into S3
-- We use the pig 'rmf' command to remove any
-- existing results first
rmf $OUTPUT_PATH;
STORE top_density 
 INTO '$OUTPUT_PATH' 
USING PigStorage('\t');
