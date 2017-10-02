SET NOCOUNT ON

DECLARE @TableName NVARCHAR(200)
DECLARE @ObjectId int
DECLARE @SchemaId int
DECLARE @ColumnName NVARCHAR(200)

DECLARE @CollationName NVARCHAR(200) = 'SQL_Latin1_General_CP850_CI_AS'
DECLARE @SQLText NVARCHAR(MAX)
DECLARE @CharacterMaxLen NVARCHAR(10)
DECLARE @IsNullable NVARCHAR(10)
DECLARE @DataType NVARCHAR(20)

DECLARE @SqlTables table
(
    SQLText NVARCHAR(MAX)
)

DECLARE MyTableCursor Cursor
FOR
SELECT object_id, schema_id
	from sys.tables
	where type = 'U'

OPEN MyTableCursor

FETCH NEXT FROM MyTableCursor INTO @ObjectId, @SchemaId
WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE MyColumnCursor Cursor
        FOR 
        SELECT COLUMN_NAME,DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
            IS_NULLABLE from information_schema.columns
            WHERE TABLE_NAME = OBJECT_NAME(@ObjectId) AND TABLE_SCHEMA = SCHEMA_NAME(@SchemaId) AND  (Data_Type LIKE '%char%' 
            OR Data_Type LIKE '%text%') AND COLLATION_NAME <> @CollationName
            ORDER BY ordinal_position 
        Open MyColumnCursor

        FETCH NEXT FROM MyColumnCursor INTO @ColumnName, @DataType, 
              @CharacterMaxLen, @IsNullable
        WHILE @@FETCH_STATUS = 0
            BEGIN
            SET @SQLText = 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(@SchemaId)) + '.' + QUOTENAME(OBJECT_NAME(@ObjectId)) + ' ALTER COLUMN ' + QUOTENAME(@ColumnName) + ' ' +
			  IIF(@DataType LIKE '%TEXT', @DataType, 
              @DataType + '(' + 
			  CASE WHEN @CharacterMaxLen = -1 THEN 'MAX'
			  WHEN @CharacterMaxLen > 8000 THEN 'MAX'
			  ELSE @CharacterMaxLen END + 
              ')') + ' COLLATE ' + @CollationName + ' ' + 
              CASE WHEN @IsNullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END
            INSERT INTO @SqlTables (SQLText) VALUES (@SQLText)

        FETCH NEXT FROM MyColumnCursor INTO @ColumnName, @DataType, 
              @CharacterMaxLen, @IsNullable
        END
        CLOSE MyColumnCursor
        DEALLOCATE MyColumnCursor

FETCH NEXT FROM MyTableCursor INTO @ObjectId, @SchemaId
END
CLOSE MyTableCursor
DEALLOCATE MyTableCursor

SELECT * FROM @SqlTables