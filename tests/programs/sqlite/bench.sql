create table test (id integer primary key, x real, y real , z real);

INSERT INTO TEST (x,y,z)
  SELECT RANDOM(), RANDOM(), RANDOM()
   FROM (SELECT * FROM (
         (SELECT 0 UNION ALL SELECT 1) t2, 
         (SELECT 0 UNION ALL SELECT 1) t4,
         (SELECT 0 UNION ALL SELECT 1) t8,
         (SELECT 0 UNION ALL SELECT 1) t16,
         (SELECT 0 UNION ALL SELECT 1) t32,
         (SELECT 0 UNION ALL SELECT 1) t64,
         (SELECT 0 UNION ALL SELECT 1) t128,
         (SELECT 0 UNION ALL SELECT 1) t256,
         (SELECT 0 UNION ALL SELECT 1) t512,
         (SELECT 0 UNION ALL SELECT 1) t1024,
         (SELECT 0 UNION ALL SELECT 1) t2048,
         (SELECT 0 UNION ALL SELECT 1) t2048a,
         (SELECT 0 UNION ALL SELECT 1) t2048b,
         (SELECT 0 UNION ALL SELECT 1) t2048c,
         (SELECT 0 UNION ALL SELECT 1) t2048d,
         (SELECT 0 UNION ALL SELECT 1) t2048e,
         (SELECT 0 UNION ALL SELECT 1) t2048f,
         (SELECT 0 UNION ALL SELECT 1) t2048g,
         (SELECT 0 UNION ALL SELECT 1) t2048h,
         (SELECT 0 UNION ALL SELECT 1) t2048i,
         (SELECT 0 UNION ALL SELECT 1) t2048j,
         (SELECT 0 UNION ALL SELECT 1) t2048k
         )
    ) LIMIT 246000000;

select sum(id) from test;
select sum(x) from test;
select sum(y) from test;
select sum(z) from test;
select sum(id) from test;
select sum(x) from test;
select sum(y) from test;
select sum(z) from test;
select sum(id) from test;
select sum(x) from test;
select sum(y) from test;
select sum(z) from test;
select sum(id) from test;
select sum(x) from test;
select sum(y) from test;
select sum(z) from test;
select sum(id) from test;
select sum(x) from test;
select sum(y) from test;
select sum(z) from test;

