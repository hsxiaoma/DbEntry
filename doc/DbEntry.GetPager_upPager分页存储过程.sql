

/****** Object:  StoredProcedure [dbo].[upPager]    Script Date: 2017-12-6 00:48:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[upPager]
(
 @Tables varchar(255),-- 表名,可以多表
 @Sort nvarchar(200),
 @Fields nvarchar(500) = '*',
 @Filter nvarchar(4000) = '',
 @PageIndex int = 1,
 @PageSize int = 10,
 @MaxCount int =1000000, --默认可返回的最大条数为10万条
 @PK varchar(100), --此参数是为了件容易2000下面的存储过程设置
 @TotalResults int =0 out,
 @Group varchar(200) = null --此参数是为了兼容2000设置，可不用赋值
)
AS
  SET NOCOUNT ON
  DECLARE
     @STMT nvarchar(max)         -- 最后生成的Sql语句
    ,@recct int                  -- total # of records (for GridView paging interface)
 
  IF LTRIM(RTRIM(@Filter)) = '' SET @Filter = '1 = 1' --如果没有过滤条件，则设置成 1=1
  IF @PageSize IS NULL BEGIN   --没有设置页面大小，则返回全部数据
    SET @STMT =  'SELECT   ' + @Fields +
                 'FROM     ' + @Tables +
                 'WHERE    ' + @Filter +
                 'ORDER BY ' + @Sort
    EXEC (@STMT)                 -- return requested records
  END ELSE BEGIN
    --获取数据量
    SET @STMT =  'SELECT   @recct = COUNT(*)
                  FROM     ' + @Tables + '
                  WHERE    ' + @Filter
    EXEC sp_executeSQL @STMT, @params = N'@recct INT OUTPUT', @recct = @recct OUTPUT
    SET @TotalResults = @recct        -- 返回最大记录数
 
    --如果没有设置最大记录数，则默认最大为1000，如果显示信息已经靠近最大记录数，则最大记录数增加200
    if @MaxCount=0
    begin
        Set @MaxCount=1000
        if @TotalResults>@MaxCount
            Set @MaxCount = @PageIndex * @PageSize + 1000
    end
    else
    if @TotalResults > @MaxCount   --最大不能超过设定的最大条数
        Set @TotalResults = @MaxCount
 
    DECLARE
      @lbound int,
      @ubound int
 
    SET @PageIndex = ABS(@PageIndex)
    SET @PageSize = ABS(@PageSize)
    IF @PageIndex < 1 SET @PageIndex = 1   --索引号小于1 则设置为1
    IF @PageSize < 1 SET @pageSize = 1     --每页数量小于1 则设置为1
    SET @lbound = ((@PageIndex - 1) * @pageSize)  --起始记录编号
    SET @ubound = @lbound + @PageSize + 1         --结束记录编号
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
 
     
    EXEC (@STMT)                 -- 最后返回请求的数据
  END
 
 

GO


