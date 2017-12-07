

/****** Object:  StoredProcedure [dbo].[upPager]    Script Date: 2017-12-6 00:48:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[upPager]
(
 @Tables varchar(255),-- ����,���Զ��
 @Sort nvarchar(200),
 @Fields nvarchar(500) = '*',
 @Filter nvarchar(4000) = '',
 @PageIndex int = 1,
 @PageSize int = 10,
 @MaxCount int =1000000, --Ĭ�Ͽɷ��ص��������Ϊ10����
 @PK varchar(100), --�˲�����Ϊ�˼�����2000����Ĵ洢��������
 @TotalResults int =0 out,
 @Group varchar(200) = null --�˲�����Ϊ�˼���2000���ã��ɲ��ø�ֵ
)
AS
  SET NOCOUNT ON
  DECLARE
     @STMT nvarchar(max)         -- ������ɵ�Sql���
    ,@recct int                  -- total # of records (for GridView paging interface)
 
  IF LTRIM(RTRIM(@Filter)) = '' SET @Filter = '1 = 1' --���û�й��������������ó� 1=1
  IF @PageSize IS NULL BEGIN   --û������ҳ���С���򷵻�ȫ������
    SET @STMT =  'SELECT   ' + @Fields +
                 'FROM     ' + @Tables +
                 'WHERE    ' + @Filter +
                 'ORDER BY ' + @Sort
    EXEC (@STMT)                 -- return requested records
  END ELSE BEGIN
    --��ȡ������
    SET @STMT =  'SELECT   @recct = COUNT(*)
                  FROM     ' + @Tables + '
                  WHERE    ' + @Filter
    EXEC sp_executeSQL @STMT, @params = N'@recct INT OUTPUT', @recct = @recct OUTPUT
    SET @TotalResults = @recct        -- ��������¼��
 
    --���û����������¼������Ĭ�����Ϊ1000�������ʾ��Ϣ�Ѿ���������¼����������¼������200
    if @MaxCount=0
    begin
        Set @MaxCount=1000
        if @TotalResults>@MaxCount
            Set @MaxCount = @PageIndex * @PageSize + 1000
    end
    else
    if @TotalResults > @MaxCount   --����ܳ����趨���������
        Set @TotalResults = @MaxCount
 
    DECLARE
      @lbound int,
      @ubound int
 
    SET @PageIndex = ABS(@PageIndex)
    SET @PageSize = ABS(@PageSize)
    IF @PageIndex < 1 SET @PageIndex = 1   --������С��1 ������Ϊ1
    IF @PageSize < 1 SET @pageSize = 1     --ÿҳ����С��1 ������Ϊ1
    SET @lbound = ((@PageIndex - 1) * @pageSize)  --��ʼ��¼���
    SET @ubound = @lbound + @PageSize + 1         --������¼���
    /*
    IF @lbound >= @recct BEGIN
      SET @ubound = @recct + 1
      SET @lbound = @ubound - (@pageSize + 1) -- return the last page of records if 
                                              -- no records would be on the
                                              -- specified page
  -- SELECT top ' + Cast(@MaxCount as varchar(10)) + '  ROW_NUMBER() OVER(ORDER BY ' + @Sort + ') AS row, ' + @Fields + '
    END*/
    SET @STMT =  'SELECT  *
                  FROM    (
                          
                            SELECT top ' + Cast(@MaxCount as varchar(10)) + '  ROW_NUMBER() OVER(ORDER BY ' + @Sort + ') AS row, ' + @Fields + '
                            FROM    ' + @Tables + '
                            WHERE   ' + @Filter + '
                             
                          ) AS tbl
                  WHERE
                          row > ' + CONVERT(varchar(9), @lbound) + ' AND
                          row < ' + CONVERT(varchar(9), @ubound)
                   + ' order by row'
 
     
    EXEC (@STMT)                 -- ��󷵻����������
  END
 
 

GO


