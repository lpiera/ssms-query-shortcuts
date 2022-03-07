/* table info */ set nocount on set transaction isolation level read uncommitted
exec sp_executesql N'
if object_id(''tempdb..#ix'',''u'') is not null drop table #ix
create table #ix (iid int, core nvarchar(max), incl nvarchar(max))
declare @oid int = (select top 1 object_id from sys.tables where name = @in), @sql nvarchar(max)
if exists (select 1 from sys.tables where name = @in having count(1) > 1) select ''Multiple schemas exist for this object.'' warning
set @in = object_name(@oid)
set @sql = ''declare @s nvarchar(max), @si nvarchar(max) ''
select @sql += ''
select @s = '''''''', @si = ''''''''
select @s = @s + case c.is_included_column when 0 then col_name(c.object_id,c.column_id)+ '''', '''' else '''''''' end,
 @si = @si + case c.is_included_column when 1 then col_name(c.object_id,c.column_id)+ '''', '''' else '''''''' end
 from sys.index_columns c where c.object_id = '' + str(@oid) + '' and c.index_id = '' + str(si.index_id) + '' order by c.key_ordinal
insert #ix (iid,core,incl) select '' + str(si.index_id) + '',@s,@si ''
from sys.indexes si where si.object_id = @oid
exec (@sql)

declare @e varchar(1) = '''' 
select case si.is_primary_key when 1 then char(176) else @e end pk,
 case type when 1 then char(176) else @e end cl,
 case is_unique when 1 then char(176) else @e end uq,
 isnull(si.name,''HEAP'') name,
 case when len(x.core)>0 then left(x.core,len(x.core)-1) else @e end core,
 case when len(x.incl)>0 then left(x.incl,len(x.incl)-1) else @e end incl,
 format((case when si.index_id < 2 then ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count
 else ps.lob_used_page_count + ps.row_overflow_used_page_count end) * 8,''#,0'') data, 
 format((ps.used_page_count - case when si.index_id < 2 then ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count
 else ps.lob_used_page_count + ps.row_overflow_used_page_count end) * 8,''#,0'') [index],
 format(ps.in_row_used_page_count*8,''#,0'') [in row], ps.lob_used_page_count*8 lob, ps.row_overflow_used_page_count*8 ovfl,
 format(ps.used_page_count*8,''#,0'') used, format(ps.used_page_count,''#,0'') pages, case when ps.used_page_count > 0 then ps.row_count / ps.used_page_count else 0 end [r/p],
 format(isnull(us.user_seeks,0),''#,0'') seeks, format(isnull(us.user_scans,0),''#,0'') scans, format(isnull(us.user_lookups,0),''#,0'') lookups,
 filegroup_name(case when si.data_space_id<256 then si.data_space_id else 0 end) [group],
 stuff((select '', '' + left(m.physical_name,1) from sys.master_files m where m.data_space_id = si.data_space_id and m.database_id = db_id() for xml path(''''), type).value(''.[1]'', ''nvarchar(max)''), 1, 2, @e) drive,
 isnull(si.filter_definition,@e) [filter]
 from #ix x 
 join (select distinct object_id, index_id, name, data_space_id, is_primary_key, type, is_unique, filter_definition from sys.indexes) si on si.index_id = x.iid and si.object_id = @oid
 left join sys.dm_db_partition_stats ps on ps.object_id = si.object_id and ps.index_id = si.index_id and ps.partition_number = 1
 left join sys.dm_db_index_usage_stats us on us.object_id = @oid and us.index_id = si.index_id and us.database_id = db_id()

declare @ixcol table (colId tinyint, type tinyint, isPk bit, keyOrdinal tinyint)
insert @ixcol (colId, type, isPk, keyOrdinal)
select ic.column_id,i.type,i.is_primary_key,ic.key_ordinal
from sys.indexes i
join sys.index_columns ic
 on ic.object_id = i.object_id and i.object_id = @oid and ic.index_id = i.index_id

select
 case c.is_identity when 1 then ltrim(str(ident_current(object_schema_name(@oid) + ''.'' + object_name(@oid)))) else @e end [identity],
 isnull((select ltrim(str(keyOrdinal)) from @ixcol where colId = column_id and type = 1),@e) cl,
 coalesce((select ltrim(str(keyOrdinal)) from @ixcol where colId = column_id and isPk = 1 and type = 2),(select top 1 char(176) from @ixcol where colId = column_id and isPk = 0 and type = 2),@e) nc,
 replace(replace(c.is_nullable,0,@e),1,char(176)) nl,
 c.name,
 type_name(c.user_type_id) type,
 case 
 when c.user_type_id in (106,108) then ltrim(str(c.max_length)) + '' ('' + ltrim(str(c.precision)) + '','' + ltrim(str(c.scale)) + '')''
 when c.max_length = -1 then ''max''
 else ltrim(str(c.max_length))
 end size,
 case c.is_sparse when 1 then char(176) else @e end [sparse],
 lower(isnull(nullif(c.collation_name,(select collation_name from sys.databases where name = db_name()) collate database_default),@e)) [collation],
 isnull(substring(df.definition,2,len(df.definition)-2),@e) as [default],
 isnull(substring(ck.definition,2,len(ck.definition)-2),@e) as [constraint],
 isnull((select top 1 object_name(referenced_object_id) roi from sys.foreign_key_columns where parent_object_id = @oid and parent_column_id = c.column_id),@e) [references],
 isnull(stuff((select distinct '', '' + object_name(referenced_object_id) roi from sys.foreign_key_columns where referenced_object_id = @oid and constraint_column_id = c.column_id for xml path(''''), type).value(''.[1]'', ''nvarchar(max)''), 1, 2, ''''),@e) referenced,
 isnull((select replace(replace(definition,'']'',@e),''['',@e) from sys.computed_columns cc where cc.object_id = @oid and cc.column_id = c.column_id),@e) [computed],
 isnull((select xp.value from sys.extended_properties xp where xp.major_id = @oid and xp.minor_id = c.column_id and xp.class = 1 and xp.name = ''short description''),@e) [xp desc],
 isnull((select xp.value from sys.extended_properties xp where xp.major_id = @oid and xp.minor_id = c.column_id and xp.class = 1 and xp.name = ''calculation''),@e) [xp calc],
 isnull((select xp.value from sys.extended_properties xp where xp.major_id = @oid and xp.minor_id = c.column_id and xp.class = 1 and xp.name = ''source column''),@e) [xp srccol],
 isnull((select xp.value from sys.extended_properties xp where xp.major_id = @oid and xp.minor_id = c.column_id and xp.class = 1 and xp.name = ''source system(s)''),@e) [xp srcsys]
 from sys.columns c
 left join sys.default_constraints df on df.parent_object_id = c.object_id and df.parent_column_id = c.column_id
 left join sys.check_constraints ck on ck.parent_object_id = c.object_id and ck.parent_column_id = c.column_id
where c.object_id = @oid order by column_id

select top (sign(isnull(@oid,0))) object_schema_name(@oid) [schema], @in name, format(sum(reserved_page_count)*8,''#,0'') reserved, format(sum(used_page_count)*8,''#,0'') used,
format(sum(case when index_id < 2 then in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count
 else lob_used_page_count + row_overflow_used_page_count end)*8,''#,0'') data, 
format(sum(used_page_count - case when index_id < 2 then in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count
 else lob_used_page_count + row_overflow_used_page_count end)*8,''#,0'') [index],
format(sum(case when index_id < 2 then row_count else 0 end),''#,0'') [rows], @oid [object id],
stuff((select '', '' + name from sys.columns where object_id = @oid for xml path('''')),1,2,@e) list
from sys.dm_db_partition_stats where object_id = @oid',
N'@in sysname',@in=