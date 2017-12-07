USE [App-Hsq]
GO

/****** Object:  Trigger [dbo].[SysMenu_CascadingInsert]    Script Date: 2017-12-6 01:28:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Batch submitted through debugger: SQLQuery1.sql|0|0|C:\Users\Dzl\AppData\Local\Temp\~vs743C.sql

create trigger [dbo].[SysMenu_CascadingInsert] on [dbo].[Sys_Menu] for insert as
begin
   	DECLARE @opId int
	DECLARE @parentId int
	DECLARE @NewSortPath nvarchar(1000)
	DECLARE @NewPathIds nvarchar(1000)
	DECLARE @NewPathString nvarchar(1000)
	DECLARE @NewDeep int
	DECLARE @newSortNo int
	DECLARE @newName nvarchar(50)
	DECLARE @NameJp varchar(50)
	DECLARE @NameQp varchar(255)

	DECLARE @ParentSortPath nvarchar(1000)
	DECLARE @ParentPathIds nvarchar(1000)
	DECLARE @ParentPathString nvarchar(1000)

	select @opId=i.Id,@parentId=i.ParentId,@newName=i.Name from dbo.Sys_Menu a,Inserted i where a.Id=i.Id

		-- 根据目标ParentId构造新的SortNo
		select @newSortNo=(max(SortNo)+2) from Sys_Menu where ParentId=@parentId and Id<>@opId
		if (@newSortNo is Null)
			begin
				set @newSortNo=2
			end

	-- 处理根级
	if (@parentId is null) or (@parentId=0)
		begin
			set @NewSortPath = '/-'+right('000'+Ltrim(Rtrim(str(@newSortNo))),3)
			set @NewPathIds = @opId
			set @NewPathString = @newName
			set @NewDeep =0
		end
	else -- 非根级
		begin
			select @ParentSortPath = SortPath,@ParentPathIds=PathIds,@ParentPathString=PathString from Sys_Menu where Id=@parentId
			-- 无论新父节点下有无子节点,统一更新一下
            SET NOCOUNT ON
			update Sys_Menu set isHaveSubItem=1 where Id=@parentId
            SET NOCOUNT OFF
			select @NewSortPath=(@ParentSortPath+'-'+right('000'+Ltrim(Rtrim(str(@newSortNo))),3)),@NewPathIds=(@ParentPathIds+','+Ltrim(Rtrim(Str(a.Id)))),@NewDeep=(len(@NewPathIds)-len(replace(@NewPathIds,',',''))),@NewPathString=(@ParentPathString+' > '+a.Name) from dbo.Sys_Menu a,Inserted i where a.Id=i.Id
		end
	set @NameJp = dbo.GetJp(@newName)
	set @NameQp = dbo.GetQp(@newName)
    SET NOCOUNT ON
	update Sys_Menu set SortNo=@newSortNo,SortPath=@NewSortPath,PathIds=@NewPathIds,Deep=@NewDeep,PathString=@NewPathString,NameJp=@NameJp,NameQp=@NameQp from Sys_Menu a,Inserted i where a.Id=i.Id
    SET NOCOUNT OFF
end


GO


