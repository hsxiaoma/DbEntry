USE [App-Hsq]
GO

/****** Object:  Trigger [dbo].[SysMenu_CascadingUpdate]    Script Date: 2017-12-6 01:29:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Batch submitted through debugger: SQLQuery1.sql|51|0|C:\Users\Dzl\AppData\Local\Temp\~vs743C.sql


create trigger [dbo].[SysMenu_CascadingUpdate] on [dbo].[Sys_Menu] for update as
begin
  IF @@ROWCOUNT=0 RETURN --如果没有满足条件的记录,直接退出

-- 查找所有的子节点
-- SET NOCOUNT ON 
	-- 创建一个临时表,记录所有子节点的Id
	DECLARE @t TABLE(Id int,Level int)
	DECLARE @Level int
	SET @Level=1
    SET NOCOUNT ON
	INSERT @t SELECT a.Id,@Level FROM Sys_Menu  a,deleted d WHERE a.ParentId=d.Id
	WHILE @@ROWCOUNT>0
    SET NOCOUNT OFF
	BEGIN
		SET @Level=@Level+1
        SET NOCOUNT ON
		INSERT @t 
        SELECT a.Id,@Level FROM Sys_Menu  a,@t b WHERE a.ParentId=b.Id AND b.Level=@Level-1
        SET NOCOUNT OFF
	END
	--DECLARE @TableName nvarchar(255)='Sys_Menu '  -- 移动目标对象的PathString
	
-- 判断是否修改了IsEnable字段
-- 如果是针对IsEnable修改了，则执行下面的操作
if (update(IsEnable))
   begin
        SET NOCOUNT ON
		update a set IsEnable=i.IsEnable
		from dbo.Sys_Menu  a,Deleted d,Inserted i,@t t
		where a.Id=t.Id
		SET NOCOUNT OFF
   end


if (update(ParentId) or update(SortNo) or update([Name])) -- 如果调整父级
-- 需要更改的字段
-- 1.原来的父级是否存在其他子节点，如果不存在，则需要更改其IsHaveSubItem为False
-- 2.SortNo需要重新计算并更新
-- 3.SortPath根据新计算的SortNo进行构造为新的SortPath并更新
-- 4.PathIds需要根据现有的层级关系进行重新构造并更新
-- 5.PathString需要根据现有的层级关系进行重新构造并更新
begin
	
	DECLARE @oldParentId int
	DECLARE @newParentId int
    DECLARE @oldSortNo int
	DECLARE @editSortNo int
	DECLARE @opId int
	DECLARE @oldSortPath nvarchar(1000) 
	DECLARE @oldPathIds nvarchar(1000) 
	DECLARE @oldPathString nvarchar(1000) 
	DECLARE @oldName nvarchar(50)
	DECLARE @newName nvarchar(50)
    DECLARE @NewPathString nvarchar(1000)
	DECLARE @NewSortPath nvarchar(1000)
	DECLARE @ParentPathString nvarchar(1000)
	DECLARE @ParentSortPath nvarchar(1000)
	DECLARE @NameJp varchar(50)
	DECLARE @NameQp varchar(255)
	
	
	select @opId=a.Id,@oldParentId=d.ParentId,@newParentId=i.ParentId,@oldSortNo=d.SortNo,@editSortNo=i.SortNo,@oldSortPath=d.SortPath,@oldPathIds=d.PathIds,@oldPathString=d.PathString,@oldName=d.Name,@newName=i.Name from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
	--print '@oldParentId=' + Str(@oldParentId)
	--print '@newParentId=' + Str(@newParentId)
	--print '@oldSortNo=' + Str(@oldSortNo)
	--print '@editSortNo=' + Str(@editSortNo)

	if (@oldName!=@newName)
	begin
		-- 需要处理根级目录
		if (@newParentId is Null) or (@newParentId=0)
			begin		
				set @NewPathString = Ltrim(Rtrim(@newName))
			end
		else
			begin
				select @ParentPathString=PathString from Sys_Menu  where Id=@newParentId 
				select @NewPathString=(@ParentPathString+' > '+a.Name) from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
			end

		set @NameJp = dbo.GetJp(@newName)
		set @NameQp = dbo.GetQp(@newName)
	    SET NOCOUNT ON
		update Sys_Menu  set PathString=@NewPathString,NameJp=@NameJp,NameQp=@NameQp from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
        SET NOCOUNT OFF
        SET NOCOUNT ON
		update Sys_Menu  set PathString=(@NewPathString + ' > ' + Substring(a.PathString,len(@oldPathString)+4,Len(a.PathString)-len(@oldPathString))) from dbo.Sys_Menu  a,Deleted d,Inserted i ,@t t
		where a.Id=t.Id
        SET NOCOUNT OFF
	end

	-- 针对修改SortNo
	if(@oldSortNo!= @editSortNo)
	begin
		select @ParentSortPath=(Substring(a.SortPath,0,len(a.SortPath)-3)+'-'+right('000'+Ltrim(Rtrim(str(i.SortNo))),3)) from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id		
		-- 更新树相关字段
		-- 更新自己
        SET NOCOUNT ON
		update Sys_Menu  set SortPath=@ParentSortPath from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
	    SET NOCOUNT OFF
        -- 更新子节点
        SET NOCOUNT ON
		update Sys_Menu  set SortPath=(@ParentSortPath + Substring(a.SortPath,len(@oldSortPath)+1,Len(a.SortPath)-len(@oldSortPath))) from dbo.Sys_Menu  a,Deleted d,Inserted i ,@t t
		where a.Id=t.Id
        SET NOCOUNT OFF
	end

	-- 针对修改ParentId 此处注意特殊值的处理
	-- 如果根级为null时,则@oldParentId!=@newParentId条件不成立，因为Null不能使用比较
	-- 必须再加上一个条件 (@newParentId is null)
	if (@oldParentId!=@newParentId) or (@newParentId is null)
	begin
		DECLARE @oldParentSubCount int  -- 移动源节点的上级下所有子节点的数量
		DECLARE @newParentSubCount int
		DECLARE @newSortNo int		
		DECLARE @ParentPathIds nvarchar(1000) 		
		DECLARE @NewPathIds nvarchar(1000)  	
		DECLARE @NewDeep int

		
		-- 处理源根级
		if (@oldParentId is not null) or (@oldParentId<>0)
			begin
				-- 查询移动源目标的父级是否存在其他子节点，如果不存在，则需要更改其IsHaveSubItem为False
				select @oldParentSubCount=count(Id) from Sys_Menu  where ParentId=@oldParentId
				--print '@oldParentSubCount=' + Str(@oldParentSubCount)

				if (@oldParentSubCount=0)
					begin
                        SET NOCOUNT ON
						update Sys_Menu  set isHaveSubItem=0 where Id=@oldParentId --如果不存在其他子节点则更新原上级的isHaveSubItem=0
					    SET NOCOUNT OFF
                    end
			end
		
		-- 处理根级
		if (@newParentId is Null) or (@newParentId=0)
			begin
				select @newParentSubCount=count(Id) from Sys_Menu  where ParentId=null or ParentId=0
				--print '@newParentSubCount=' + Str(@newParentSubCount)
				-- 根据目标ParentId构造新的SortNo
				select @newSortNo=(max(SortNo)+2) from Sys_Menu  where ParentId=null or ParentId=0 and Id<>@opId
				if (@newSortNo is Null)
					begin
						set @newSortNo=2
					end

				set @ParentSortPath=''
				set @ParentPathIds = ''
				set @ParentPathString = ''

				set @NewSortPath='/-'+right('000'+Ltrim(Rtrim(str(@newSortNo))),3)
				set @NewPathIds = @opId
				set @NewPathString = @newName
				set @NewDeep =0
			end
		else
			begin
				select @newParentSubCount=count(Id) from Sys_Menu  where ParentId=@newParentId
				--print '@newParentSubCount=' + Str(@newParentSubCount)
				-- 根据目标ParentId构造新的SortNo
				select @newSortNo=(max(SortNo)+2) from Sys_Menu  where ParentId=@newParentId and Id<>@opId
				if (@newSortNo is Null)
					begin
						set @newSortNo=2
					end

				-- 查询移动源目标的父级是否存在其他子节点，如果不存在，则需要更改其IsHaveSubItem为False
				select @oldParentSubCount=count(Id) from Sys_Menu  where ParentId=@oldParentId
				--print '@oldParentSubCount=' + Str(@oldParentSubCount)


				if (@oldParentSubCount=0)
					begin
						update Sys_Menu  set isHaveSubItem=0 where Id=@oldParentId --如果不存在其他子节点则更新原上级的isHaveSubItem=0
					end

				select @ParentSortPath = SortPath,@ParentPathIds=PathIds,@ParentPathString=PathString from Sys_Menu  where Id=@newParentId
				-- 无论新父节点下有无子节点,统一更新一下
                SET NOCOUNT ON
				update Sys_Menu  set isHaveSubItem=1 where Id=@newParentId
                SET NOCOUNT OFF
				select @NewSortPath=(@ParentSortPath+'-'+right('000'+Ltrim(Rtrim(str(@newSortNo))),3)),@NewPathIds=(@ParentPathIds+','+Ltrim(Rtrim(Str(a.Id)))),@NewDeep=(len(@NewPathIds)-len(replace(@NewPathIds,',',''))),@NewPathString=(@ParentPathString+' > '+a.Name) from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
			end
		
		-- 更新树相关字段
		-- 更新自己
        SET NOCOUNT ON
		update Sys_Menu  set SortNo=@newSortNo,SortPath=@NewSortPath,PathIds=@NewPathIds,Deep=@NewDeep,PathString=@NewPathString from dbo.Sys_Menu  a,Deleted d,Inserted i where a.Id=d.Id
	    SET NOCOUNT OFF
    	-- 更新子节点
        SET NOCOUNT ON
		update Sys_Menu  set SortPath=(@NewSortPath + Substring(a.SortPath,len(@oldSortPath)+1,Len(a.SortPath)-len(@oldSortPath))),PathIds=(@NewPathIds + Substring(a.PathIds,len(@oldPathIds)+1,Len(a.PathIds)-len(@oldPathIds))),PathString=(@NewPathString + Substring(a.PathString,len(@oldPathString)+1,Len(a.PathString)-len(@oldPathString))),Deep=(len((@NewPathIds + Substring(a.PathIds,len(@oldPathIds)+1,Len(a.PathIds)-len(@oldPathIds))))-len(replace((@NewPathIds +
 Substring(a.PathIds,len(@oldPathIds)+1,Len(a.PathIds)-len(@oldPathIds))),',',''))) from dbo.Sys_Menu  a,Deleted d,Inserted i  ,@t t where a.Id=t.Id
        SET NOCOUNT OFF
	end
end
end


GO


