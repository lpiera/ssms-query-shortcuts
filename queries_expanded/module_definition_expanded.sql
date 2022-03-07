/* module definition */ sp_executesql N'
declare @oid int = (
    select top 1 so.object_id 
      from sys.objects so 
      join sys.sql_modules sm on sm.object_id = so.object_id and so.name = @in) 
select definition 
  from sys.sql_modules where object_id = @oid',N'@in sysname',@in=