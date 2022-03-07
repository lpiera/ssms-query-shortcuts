/* view info */ exec sp_executesql N'
select name = case when charindex(''-'',c.name) > 0 or lower(c.name) in (''status'') or charindex('' '',c.name) > 0 then QUOTENAME(c.name) else c.name end,
       datatype = typ.name, c.max_length, c.[precision], c.scale, c.is_nullable, c.is_identity, c.is_computed, c.column_id 
  from (select object_id, schema_id, name 
          from sys.tables 
         union all 
        select object_id, schema_id, name from sys.views) t 
  join sys.columns c on t.object_id = c.object_id 
  join sys.types typ on c.user_type_id = typ.user_type_id 
 where t.name = replace(replace(@view,''['',''''),'']'','''') 
 order by t.schema_id, c.column_id ;',N'@view varchar(100)',@view=