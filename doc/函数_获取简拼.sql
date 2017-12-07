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
    INSERT @py SELECT 'A',N'߹',N'��'
    UNION  ALL SELECT 'B',N'��',N'��'
    UNION  ALL SELECT 'C',N'��',N'��'
    UNION  ALL SELECT 'D',N'��',N'��'
    UNION  ALL SELECT 'E',N'��',N'��'
    UNION  ALL SELECT 'F',N'��',N'�'
    UNION  ALL SELECT 'G',N'�',N'��'
    UNION  ALL SELECT 'H',N'��',N'�'
    UNION  ALL SELECT 'J',N'آ',N'��'
    UNION  ALL SELECT 'K',N'��',N'��'
    UNION  ALL SELECT 'L',N'��',N'��'
    UNION  ALL SELECT 'M',N'��',N'��'
    UNION  ALL SELECT 'N',N'��',N'Ŵ'
    UNION  ALL SELECT 'O',N'��',N'Ž'
    UNION  ALL SELECT 'P',N'ſ',N'��'
    UNION  ALL SELECT 'Q',N'��',N'Ⱥ'
    UNION  ALL SELECT 'R',N'��',N'��'
    UNION  ALL SELECT 'S',N'��',N'��'
    UNION  ALL SELECT 'T',N'��',N'��'
    UNION  ALL SELECT 'W',N'��',N'��'
    UNION  ALL SELECT 'X',N'Ϧ',N'ަ'
    UNION  ALL SELECT 'Y',N'Ѿ',N'��'
    UNION  ALL SELECT 'Z',N'��',N'��'
    DECLARE @i int
    SET @i=PATINDEX('%[߹-��]%' COLLATE Chinese_PRC_CS_AS_KS_WS,@str)
    WHILE @i>0
    SELECT @str=REPLACE(@str,SUBSTRING(@str,@i,1),ch),
    @i=PATINDEX('%[߹-��]%' COLLATE Chinese_PRC_CS_AS_KS_WS,@str)
    FROM @py WHERE SUBSTRING(@str,@i,1) BETWEEN hz1 AND hz2

    RETURN(@str)

END

GO


