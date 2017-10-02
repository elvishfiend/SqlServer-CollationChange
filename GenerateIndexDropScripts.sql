SET NOCOUNT ON

DECLARE @TableName nvarchar(255)
DECLARE @ObjectId int
DECLARE @SchemaId int

DECLARE MyTableCursor Cursor
FOR 
SELECT object_id, schema_id FROM sys.tables WHERE [type] = 'U' and name <> 'sysdiagrams' ORDER BY schema_id, name 
OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @ObjectId, @SchemaId
WHILE @@FETCH_STATUS = 0
    BEGIN
	SET @TableName = QUOTENAME(SCHEMA_NAME(@SchemaId)) + '.' + QUOTENAME(OBJECT_NAME(@ObjectId))
	--SELECT @TableName

    EXEC ScriptDropTableKeys @TableName

    FETCH NEXT FROM MyTableCursor INTO @ObjectId, @SchemaId
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor