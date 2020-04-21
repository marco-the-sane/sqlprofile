-- data preparation - a table with deliberately
-- unfavourable data types

DROP TABLE IF EXISTS public.foo cascade;

CREATE TABLE public.foo (
  id         NUMERIC      -- becomes NUMERIC(37,15)
-- frequent example: was INTEGER in SQL Server,
-- then migrated to Oracle, where INTEGER became NUMBER,
-- and, with that, NUMBER(38,15), now mig to Vertica
, first_name VARCHAR(256) -- becomes VARCHAR(256)
, last_name  VARCHAR(256) -- becomes VARCHAR(256)
, hire_dt    TIMESTAMP    -- becomes TIMESTAMP(6)
) UNSEGMENTED ALL NODES
;

INSERT /*+ DIRECT */ INTO foo(id,first_name,last_name,hire_dt)
          SELECT 2,'Ford','Prefect',DATE '2017-02-05'
UNION ALL SELECT 10,'Svlad','Cjelli',DATE '2017-02-05'
UNION ALL SELECT 11,'Cynthia','Fitzmelton',DATE '2017-02-05'
UNION ALL SELECT 13,'Stavro','Mueller',DATE '2017-02-05'
UNION ALL SELECT 19,'Veet','Voojagig',DATE '2017-02-05'
UNION ALL SELECT 20,'Trin','Tragula',DATE '2017-02-05'
UNION ALL SELECT 23,'Zarniwoop','Zarniwoop',DATE '2017-02-05'
UNION ALL SELECT 24,'Rob','McKenna',DATE '2017-02-05'
UNION ALL SELECT 36,'The Lajestic Vantrashell','of Lob',DATE '2017-02-05'
UNION ALL SELECT 40,'Paul Neil Milne','Johnston',DATE '2017-02-05'
UNION ALL SELECT 41,'Lunkwill','Lunkwill',DATE '2017-02-05'
UNION ALL SELECT 1,'Arthur','Dent',DATE '2017-02-05'
UNION ALL SELECT 3,'Zaphod','Beeblebrox',DATE '2017-02-05'
UNION ALL SELECT 4,'Tricia','McMillan',DATE '2017-02-05'
UNION ALL SELECT 6,'Prostetnic Vogon','Jeltz',DATE '2017-02-05'
UNION ALL SELECT 7,'Lionel','Prosser',DATE '2017-02-05'
UNION ALL SELECT 12,'Karl','Mueller',DATE '2017-02-05'
UNION ALL SELECT 14,'Hotblack','Desiato',DATE '2017-02-05'
UNION ALL SELECT 16,'Gogrilla','Mincefriend',DATE '2017-02-05'
UNION ALL SELECT 21,'Slartibartfast','Slartibartfast',DATE '2017-02-05'
UNION ALL SELECT 22,'Roosta','Roosta',DATE '2017-02-05'
UNION ALL SELECT 26,'Eccentrica','Gallumbitis',DATE '2017-02-05'
UNION ALL SELECT 28,'Pizpot','Gargravarr',DATE '2017-02-05'
UNION ALL SELECT 29,'Vroomfondel','Vroomfondel',DATE '2017-02-05'
UNION ALL SELECT 30,'Majikthise','Majikthise',DATE '2017-02-05'
UNION ALL SELECT 31,'Gengis Temüjin','Khan',DATE '2017-02-05'
UNION ALL SELECT 35,'Know-Nothing-Bozo','the Non-Wonder Dog',DATE '2017-02-05'
UNION ALL SELECT 38,'Lazlaar','Lyricon',DATE '2017-02-05'
UNION ALL SELECT 39,'Lintilla','Lintilla',DATE '2017-02-05'
UNION ALL SELECT 42,'Fook','Fook',DATE '2017-02-05'
UNION ALL SELECT 5,'Gag','Halfrunt',DATE '2017-02-05'
UNION ALL SELECT 8,'Benji','Mouse',DATE '2017-02-05'
UNION ALL SELECT 9,'Frankie','Mouse',DATE '2017-02-05'
UNION ALL SELECT 15,'Grunthos','the Flatulent',DATE '2017-02-05'
UNION ALL SELECT 17,'Wowbagger','The Infinitely Prolonged',DATE '2016-10-05'
UNION ALL SELECT 18,'Wonko','The Sane',DATE '2017-02-05'
UNION ALL SELECT 25,'Reg','Nullify',DATE '2017-02-05'
UNION ALL SELECT 27,'Fenchurch','of Rickmansworth',DATE '2017-02-05'
UNION ALL SELECT 32,'Oolon','Colluphid',DATE '2017-02-05'
UNION ALL SELECT 33,'Humma','Kavula',DATE '2017-02-05'
UNION ALL SELECT 34,'Judiciary','Pag',DATE '2017-02-05'
UNION ALL SELECT 37,'Max','Quordlepleen',DATE '2017-02-05'
;

DROP TABLE IF EXISTS public.foo_str cascade;
CREATE TABLE public.foo_str AS
SELECT
  id::VARCHAR(32)
, first_name
, last_name
, hire_dt::VARCHAR(32)
FROM foo;

DROP TABLE IF EXISTS public.t1;
CREATE TABLE IF NOT EXISTS public.t1 (
  ky  INT
, id VARCHAR ( 12 )
, idt CHAR   ( 32 )
)
;

INSERT INTO public.t1 
SELECT 1,'123' , '2018-11-09 00:21:15' UNION ALL
SELECT 2,'-456', '2018-11-21 09:23:78' UNION ALL
SELECT 3,'+789.21' , '2023-03-07 04:45:12'
;



DROP TABLE IF EXISTS ttest;
CREATE TABLE ttest (
  c_bool      Boolean
, c_int       Integer
, c_float     Float
, c_Char      Char
, c_Varchar   Varchar
, c_uuidchar  Varchar(36)
, c_Varbinary Varbinary
, c_Long_Varc Long Varchar
, c_Long_Varb Long Varbinary
, c_Binary    Binary(4)
, c_Numeric   Numeric
, c_Int_y     Interval Year
, c_Int_ym    Interval Year to Month
, c_Int_m     Interval Month
, c_Int_d     Interval Day
, c_Int_dh    Interval Day to Hour
, c_Int_dm    Interval Day to Minute
, c_Int_ds    Interval Day to Second
, c_Int_h     Interval Hour
, c_Int_hm    Interval Hour to Minute
, c_Int_hs    Interval Hour to Second
, c_Int_mi    Interval Minute
, c_Int_mis   Interval Minute to Second
, c_Int_s     Interval Second
, c_Date      Date
, c_Time      Time
, c_TimeTz    TimeTz
, c_Timestamp Timestamp
, c_Timesttz  TimestampTz
, c_Uuid      Uuid
, c_geometry  geometry
, c_geography geography
);
INSERT /*+DIRECT*/ INTO ttest 
SELECT
  true       -- Boolean
, 42       -- Integer
, pi()       -- Float
, 'Y'       -- Char
, 'Arthur'       -- Varchar
, UUID_GENERATE()::VARCHAR(36) -- uuid as char
, X'abcd'       -- Varbinary
, 'this should be very,very long'       -- Long Varchar
, X'abcd'        -- Long Varbinary
, X'abcd'        -- Binary(4)
, 3.14159        -- Numeric
, '2'            -- Interval Year
, '2-6'          -- Interval Year to Month
, '24'           -- Interval Month
, '24'           -- Interval Day
, '24 12'        -- Interval Day to Hour
, '24 12:30'     -- Interval Day to Minute
, '24 12:30:30'  -- Interval Day to Second
, '48'           -- Interval Hour
, '12:30'        -- Interval Hour to Minute
, '12:30:30'     -- Interval Hour to Second
, '59'           -- Interval Minute
, '59:59'        -- Interval Minute to Second
, '59'           -- Interval Second
, '2018-05-02'      -- Date
, '12:03:03'      -- Time
, '12:03:03+01'     -- TimeTz
, '2018-05-02 12:30:31'       -- Timestamp
, '2018-05-02 12:30:31+01'       -- TimestampTz
, UUID_GENERATE() -- Uuid
, ST_GeomFromText('point(84 42)') -- geometry
, ST_GeographyFromText('POINT(84 42)')      -- geography
;
commit;
