/* column search */ sp_executesql N'
select object_schema_name(object_id) [schema], object_name(object_id) module, name [column] 
  from sys.columns 
 where charindex(@in, name) > 0 order by 1,2',N'@in sysname',@in=