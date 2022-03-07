/* select table */ sp_executesql N'
declare @on sysname = (
    select top 1 schema_name(schema_id) + ''.'' + name 
    from sys.objects 
    where type in (''sn'',''u'',''v'') 
    and name = @in) 
if exists (select 1 from sys.tables where name = @in having count(1) > 1) 
select ''Showing results for '' + @on warning 
exec (''select top 40000 * from '' + @on + '''')',
N'@in sysname',@in=