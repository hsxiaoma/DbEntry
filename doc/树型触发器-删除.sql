USE [App-Hsq]
GO

/****** Object:  Trigger [dbo].[Sys_Menu_CascadingDelete]    Script Date: 2017-12-6 01:28:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/****** 对象:  Trigger [dbo].[Sys_Menu_CascadingDelete]    脚本日期: 05/31/2011 12:26:19 ******/

CREATE TRIGGER [dbo].[Sys_Menu_CascadingDelete] ON [dbo].[Sys_Menu]
FOR DELETE
AS
SET NOCOUNT ON

DECLARE @opId int
DECLARE @parentId int
DECLARE @ParentSubCount int

select @opId=d.Id,@parentId=d.ParentId from deleted d

IF @@ROWCOUNT=0 
	begin
		-- 检查上级是否存在其他子节点
		-- 判断不为根级
		if (@parentId is not null) or (@parentId<>0)
			begin
				select @ParentSubCount=count(Id) from [Sys_Menu] where ParentId=@parentId
				if (@ParentSubCount=0)
					begin
						update Sys_Menu set isHaveSubItem=0 where Id=@parentId --如果不存在其他子节点则更新原上级的isHaveSubItem=0
					end
			end
		RETURN --如果没有满足删除条件的记录,直接退出
	end 


-- 查找所有被删除节点的子节点
--SET NOCOUNT ON 

	DECLARE @t TABLE(Id int,Level int)
	DECLARE @Level int

	SET @Level=1

	INSERT @t SELECT a.Id,@Level FROM Sys_Menu a,deleted d WHERE a.ParentId=d.Id
	WHILE @@ROWCOUNT>0
	BEGIN
		SET @Level=@Level+1
		INSERT @t 
		   SELECT a.Id,@Level FROM Sys_Menu a,@t b WHERE a.ParentId=b.Id AND b.Level=@Level-1
	END
	-- 删除所有子节点
	-- DELETE a FROM Sys_Menu a,@t b WHERE a.Id=b.Id
	-- 检查上级是否存在其他子节点
	-- 判断不为根级
	if (@parentId is not null) or (@parentId<>0)
		begin
			select @ParentSubCount=count(Id) from [Sys_Menu] where ParentId=@parentId
			if (@ParentSubCount=0)
				begin
					update Sys_Menu set isHaveSubItem=0 where Id=@parentId --如果不存在其他子节点则更新原上级的isHaveSubItem=0
				end
		end

SET NOCOUNT OFF


GO


