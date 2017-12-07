USE [App-Hsq]
GO

/****** Object:  Trigger [dbo].[Sys_Menu_CascadingDelete]    Script Date: 2017-12-6 01:28:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/****** ����:  Trigger [dbo].[Sys_Menu_CascadingDelete]    �ű�����: 05/31/2011 12:26:19 ******/

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
		-- ����ϼ��Ƿ���������ӽڵ�
		-- �жϲ�Ϊ����
		if (@parentId is not null) or (@parentId<>0)
			begin
				select @ParentSubCount=count(Id) from [Sys_Menu] where ParentId=@parentId
				if (@ParentSubCount=0)
					begin
						update Sys_Menu set isHaveSubItem=0 where Id=@parentId --��������������ӽڵ������ԭ�ϼ���isHaveSubItem=0
					end
			end
		RETURN --���û������ɾ�������ļ�¼,ֱ���˳�
	end 


-- �������б�ɾ���ڵ���ӽڵ�
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
	-- ɾ�������ӽڵ�
	-- DELETE a FROM Sys_Menu a,@t b WHERE a.Id=b.Id
	-- ����ϼ��Ƿ���������ӽڵ�
	-- �жϲ�Ϊ����
	if (@parentId is not null) or (@parentId<>0)
		begin
			select @ParentSubCount=count(Id) from [Sys_Menu] where ParentId=@parentId
			if (@ParentSubCount=0)
				begin
					update Sys_Menu set isHaveSubItem=0 where Id=@parentId --��������������ӽڵ������ԭ�ϼ���isHaveSubItem=0
				end
		end

SET NOCOUNT OFF


GO


