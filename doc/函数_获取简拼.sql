USE [App-Hsq]
GO

/****** Object:  UserDefinedFunction [dbo].[GetJp]    Script Date: 2017-12-6 01:30:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create function [dbo].[GetJp] (@Str nvarchar(4000))
RETURNS  nvarchar(4000)
AS
BEGIN
    DECLARE @py TABLE(
    ch char(1),
    hz1 nchar(1) COLLATE Chinese_PRC_CS_AS_KS_WS,
    hz2 nchar(1) COLLATE Chinese_PRC_CS_AS_KS_WS)
    INSERT @py SELECT 'A',N'ß¹',N'öË'
    UNION  ALL SELECT 'B',N'°Ë',N'²¾'
    UNION  ALL SELECT 'C',N'àê',N'´í'
    UNION  ALL SELECT 'D',N'ßÕ',N'¶å'
    UNION  ALL SELECT 'E',N'åí',N'·¡'
    UNION  ALL SELECT 'F',N'·¢',N'ð¥'
    UNION  ALL SELECT 'G',N'ê¸',N'¹ý'
    UNION  ALL SELECT 'H',N'îþ',N'ó¶'
    UNION  ALL SELECT 'J',N'Ø¢',N'¿¢'
    UNION  ALL SELECT 'K',N'ßÇ',N'Àª'
    UNION  ALL SELECT 'L',N'À¬',N'öÃ'
    UNION  ALL SELECT 'M',N'Âè',N'ÄÂ'
    UNION  ALL SELECT 'N',N'ÄÃ',N'Å´'
    UNION  ALL SELECT 'O',N'àÞ',N'Å½'
    UNION  ALL SELECT 'P',N'Å¿',N'ÆØ'
    UNION  ALL SELECT 'Q',N'Æß',N'Èº'
    UNION  ALL SELECT 'R',N'òÅ',N'óè'
    UNION  ALL SELECT 'S',N'Øí',N'Ëø'
    UNION  ALL SELECT 'T',N'Ëû',N'óê'
    UNION  ALL SELECT 'W',N'ÍÛ',N'öÈ'
    UNION  ALL SELECT 'X',N'Ï¦',N'Þ¦'
    UNION  ALL SELECT 'Y',N'Ñ¾',N'ÔÌ'
    UNION  ALL SELECT 'Z',N'ÔÑ',N'×ö'
    DECLARE @i int
    SET @i=PATINDEX('%[ß¹-×ö]%' COLLATE Chinese_PRC_CS_AS_KS_WS,@str)
    WHILE @i>0
    SELECT @str=REPLACE(@str,SUBSTRING(@str,@i,1),ch),
    @i=PATINDEX('%[ß¹-×ö]%' COLLATE Chinese_PRC_CS_AS_KS_WS,@str)
    FROM @py WHERE SUBSTRING(@str,@i,1) BETWEEN hz1 AND hz2

    RETURN(@str)

END

GO


