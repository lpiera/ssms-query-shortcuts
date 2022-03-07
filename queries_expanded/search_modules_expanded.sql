/* search modules */ sp_executesql N'
select object_name(object_id) 
  from sys.sql_modules 
 where definition like ''%''+@in+''%''',N'@in sysname',@in=




