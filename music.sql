-- initial checks 
SELECT * FROM popular_songs
ORDER BY bpm DESC;

-- change names of song feature fields for easy query
ALTER TABLE popular_songs
CHANGE COLUMN `danceability_%` danceability INT,
CHANGE COLUMN `energy_%` energy INT,
CHANGE COLUMN `valence_%` valence INT,
CHANGE COLUMN `acousticness_%` acousticness INT,
CHANGE COLUMN `instrumentalness_%` instrumentalness INT,
CHANGE COLUMN `liveness_%` liveness INT,
CHANGE COLUMN `speechiness_%` speechiness INT;

-- to see the most popular artists and their streams
 SELECT 
  `artist(s)_name`,
  COUNT(*) AS num_songs,
  SUM(streams) AS total_streams,
  AVG(streams) AS avg_streams,
  AVG(`danceability_%`) AS avg_danceability,
  AVG(`energy_%`) AS avg_energy
FROM popular_songs
GROUP BY `artist(s)_name`
ORDER BY total_streams DESC;

-- to make quartiles to see top 25 and bottom 25 

SELECT * FROM vw_popsong_tier 
WHERE released_year BETWEEN 2000 AND 2023; 

-- label the quartiles for ease of understanding
CREATE OR REPLACE VIEW vw_popsong_labeled AS
SELECT *,
CASE quartile
    WHEN 1 THEN 'Top 25%'
    WHEN 2 THEN '25–50%'
    WHEN 3 THEN '50–75%'
    ELSE 'Bottom 25%'
  END AS popularity_tier
FROM vw_popsong_tier;

SELECT * FROM vw_popsong_labeled;


-- see averages of each song feature to see if there is a correlation w/ # of streams
-- order it by top 25 quartile down to bottom 25 quartile

CREATE OR REPLACE VIEW vw_song_features_avg AS
SELECT
popularity_tier,
AVG(`danceability`) AS avg_danceability,
AVG(`energy`) AS avg_energy,
AVG(`valence`) AS avg_valence,
AVG(`bpm`) AS avg_bpm,
COUNT(*) AS songs
FROM vw_popsong_labeled
GROUP BY popularity_tier
ORDER BY CASE popularity_tier
WHEN 'Top 25%' THEN 1 WHEN '25–50%' THEN 2 WHEN '50–75%' THEN 3 ELSE 4 END;

SELECT * FROM vw_song_features_avg;

-- for this initial test we find that song features do not have a correlation with popularity, although maybe BPM.

-- i have a hypothesis that time (season and year) has a correlation with number of streams
-- since it has something to do w/ popularity of streaming platforms etc

-- going to check the proportion of top 25% songs by tier
-- in other words going to see if there is a range of years that dominate top streams

CREATE OR REPLACE VIEW yw_yearly_top25 AS
SELECT released_year, quartile, SUM(streams) AS total_streams, ROUND(AVG(streams), 0) AS avg_streams_per_song, COUNT(*) AS top_25
FROM vw_popsong_labeled
WHERE released_year BETWEEN 2000 AND 2023 
	AND quartile = 1
GROUP BY released_year
ORDER BY released_year;

SELECT * FROM yw_yearly_top25;

-- checking where the month ends for 2023 in the dataset 
SELECT track_name, released_year, released_month
FROM vw_popsong_labeled
WHERE released_year = 2023;

-- Takeaways:
-- Most Top 25% songs are from 2019–2022 (recency bias, peak streaming years).
-- Very few songs before 2015 (music streaming surpassed downloads) made it into the Top 25%.
-- rose after 2016, boomed after 2019
-- 2023 has fewer because new releases haven’t had time to gain streams yet in the database.

-- now to see if there is a correlation of popularity of songs in each season from 2015-2023, also seeing if there is a bpm correlation in each season
-- ex) summer top 25 percent has a high bpm and most streams out of any season

CREATE OR REPLACE VIEW vw_seasonal_streams AS 
WITH result AS (
  SELECT
    CASE
      WHEN released_month IN (12, 1, 2)  THEN 'Winter'
      WHEN released_month IN (3, 4, 5)   THEN 'Spring'
      WHEN released_month IN (6, 7, 8)   THEN 'Summer'
      ELSE 'Fall'
    END AS season,
    quartile,
    streams,
    bpm
  FROM vw_popsong_labeled
  WHERE released_year BETWEEN 2015 AND 2023
    AND quartile IN (1,4)   -- Top & Bottom 25% only
)
SELECT
  season,
  CASE 
    WHEN quartile = 1 THEN 'Top 25%'
    WHEN quartile = 4 THEN 'Bottom 25%'
  END AS tier,
  SUM(streams) AS total_streams,
  COUNT(*)     AS songs,
  ROUND(SUM(streams) / COUNT(*), 0) AS avg_streams_per_song,
  ROUND(AVG(bpm), 2)                AS avg_bpm
FROM result
GROUP BY season, tier
ORDER BY
  FIELD(season,'Winter','Spring','Summer','Fall'),
  FIELD(tier,'Top 25%','Bottom 25%');

SELECT * FROM vw_seasonal_streams;

-- Takeaways (2015–2023):
-- Summer & Spring drive the most Top 25% streams (Spring = highest total, Summer = highest BPM hits).
-- Top hits are consistently faster (125–131 BPM) vs Bottom 25% (116–123 BPM).
-- Winter & Fall see fewer hits; many songs released, but fewer break into Top 25%.

-- Spring delivers the strongest Top 25% hits (~915M avg streams per song).
-- Summer hits are fastest (avg BPM ~131) but slightly lower avg streams.
-- Winter songs also perform well (~826M avg streams per song).
-- Fall underperforms (lowest avg streams, slower tempo ~120 BPM).
-- Bottom 25% songs across all seasons stream far less and have slower BPM.

-- Now we will be seeing if there is a correlation with key/mode in each season of the "streaming era", as well its relation to popularity
CREATE OR REPLACE VIEW vw_keymode_season_counts AS
SELECT
  CASE
    WHEN released_month IN (12,1,2) THEN 'Winter'
    WHEN released_month IN (3,4,5)  THEN 'Spring'
    WHEN released_month IN (6,7,8)  THEN 'Summer'
    ELSE 'Fall'
  END AS season,                   
  `key`        AS musical_key,
  `mode`       AS mode_label,
  COUNT(*)     AS songs,
  SUM(streams) AS total_streams,
  ROUND(AVG(bpm),2) AS avg_bpm
FROM vw_popsong_labeled
WHERE released_year >= 2015
  AND `key` IS NOT NULL
  
GROUP BY season, musical_key, mode_label
ORDER BY FIELD(season,'Winter','Spring','Summer','Fall'),
         musical_key,
         FIELD(mode_label,'Major','Minor');
         
CREATE OR REPLACE VIEW vw_top_keymode_by_season AS
WITH ranked AS (
  SELECT
    season,
    musical_key,
    mode_label,
    songs,
    total_streams,
    RANK() OVER (
      PARTITION BY season
      ORDER BY songs DESC, total_streams DESC
    ) AS rnk
  FROM vw_keymode_season_counts
)
SELECT season, musical_key, mode_label, songs, total_streams
FROM ranked
WHERE rnk = 1
ORDER BY FIELD(season,'Winter','Spring','Summer','Fall');
         
SELECT * FROM vw_top_keymode_by_season;

-- found that the Major key is constant throughout the 4 seasons
-- also found that similar keys (G, C#, D, G#) are also frequently used.
-- this shows the preference for bright and stable tonalities in popular tracks
