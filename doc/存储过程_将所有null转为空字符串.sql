USE [App-Hsq]
GO

/****** Object:  StoredProcedure [dbo].[sp_ConvertNullToSpace]    Script Date: 2017-12-6 01:29:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Create  proc [dbo].[sp_ConvertNullToSpace]
@TableName varchar(30)
as 

set nocount on

--declare @TableName varchar(30)
--set @TableName='MstUser'

declare @i int
select @i=count(*) from syscolumns where id=object_id(@TableName)


declare @name varchar(30)
declare @sql varchar(8000)
while @i>0
begin
select @name=name from syscolumns  where id=object_id(@TableName) and colid=@i
--  select @name

set @sql='
update '+@TableName+' 
set '+@name+'=isnull(' + @name + ','''')'

exec (@sql)
set @sql=''
set @i=@i-1
end 

GO


