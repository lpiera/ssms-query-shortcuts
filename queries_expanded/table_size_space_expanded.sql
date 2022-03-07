/* table size space */ declare @a table (id int, rc bigint, rs bigint, us bigint, dt bigint) 
insert @a (id, rc, rs, us, dt) 
select s.object_id, sum(case when s.index_id < 2 then s.row_count else 0 end), 
sum(s.reserved_page_count), sum(s.used_page_count), 
sum(case when s.index_id < 2 then s.in_row_data_page_count + s.lob_used_page_count + s.row_overflow_used_page_count 
         else s.lob_used_page_count + s.row_overflow_used_page_count end) 
from sys.dm_db_partition_stats s 
join sys.tables t on t.object_id = s.object_id
group by s.object_id 

update a 
set rs += d.reserved_page_count, us += d.used_page_count 
from @a a 
join (select t.parent_id, sum(s.reserved_page_count) reserved_page_count, sum(s.used_page_count) used_page_count 
        from sys.internal_tables t join sys.dm_db_partition_stats s on s.object_id = t.object_id and t.internal_type in (202,204,211,212,213,214,215,216) 
       group by t.parent_id) d on d.parent_id = a.id 

select case when rn = 1 then db_name() else '' end db,
    [schema], [name], [rows], reserved, [data], [indexes], unused,
    case when rn = 1 then lower((select collation_name from sys.databases where database_id = db_id())) else '' end [database collation],
    case when rn = 1 then lower(@@servername) else '' end [server],
    case when rn = 1 then @@version + ' ' + (select convert(sysname, serverproperty('collation'))) else '' end edition
  from (select top 100 percent row_number() over(order by rs desc) rn,
               object_schema_name(id) [schema], 
               object_name(id) [name], 
               format(rc,'#,0') [rows], 
               format(rs*8,'#,0') reserved, 
               format(dt*8,'#,0') [data], 
               format((us-dt)*8,'#,0') [indexes], 
               format((rs-us)*8,'#,0') unused
          from @a) d
