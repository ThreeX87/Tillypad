
IF OBJECT_ID(N'external_Rep', 'P') IS NOT NULL 
	DROP PROCEDURE dbo.external_Rep
GO

CREATE PROCEDURE [dbo].[external_Rep] (
	 @File		SysName
	,@Encoding	SysName	= 'utf-8'
) WITH EXECUTE AS OWNER AS BEGIN
	DECLARE	 @OLEStream	Int
			,@Code		Int
			,@Method	SysName
			,@Source	SysName
			,@Descript	NVarChar(4000)
			,@FileName nvarchar(max) = SUBSTRING(@File, 0, len(@File) - 3) + '.flr'
			,@File_Exists int
	EXEC Master.dbo.xp_fileexist @FileName, @File_Exists OUT
	IF @File_Exists = 1
		begin
			declare @cmd nvarchar(max)
			select @cmd = 'del ' + @FileName
			select @cmd = 'master..xp_cmdshell ''' + @cmd + ''''
			exec(@cmd)
		end
	EXEC @Code = sys.sp_OACreate 'ADODB.Stream' ,@OLEStream OUT
	IF (@Code != 0)
		SELECT	 @Method	= 'Scripting.Stream'
				,@Source	= 'sp_OACreate'
				,@Descript	= 'Ошибка создания OLE объекта'
	ELSE BEGIN
		SET @Method = 'Open';		EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method					IF (@Code != 0) GOTO Error;
		SET @Method = 'CharSet';	EXEC @Code = sys.sp_OASetProperty	@OLEStream ,@Method, @Encoding		IF (@Code != 0) GOTO Error;

		Declare @Data		NVarChar(max)

		declare curSave cursor local for
		select chck_data from external_checks order by num

		open curSave
		fetch next from curSave into @data

		while @@FETCH_STATUS=0
		begin
			if(@data is not null)
				set @data=@data+CHAR(13)+CHAR(10)
				SET @Method = 'WriteText';	EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method ,NULL ,@Data	IF (@Code != 0) GOTO Error;
			FETCH NEXT FROM curSave  INTO @data
		end


		SET @Method = 'SaveToFile';	EXEC @Code = sys.sp_OAMethod		@OLEStream, @Method, NULL, @File, 2	IF (@Code != 0) GOTO Error;
		SET @Method = 'Close';		EXEC @Code = sys.sp_OAMethod		@OLEStream, @Method					IF (@Code != 0) GOTO Error;
		SET @Method = NULL; GOTO Destroy;
Error:						EXEC @Code = sys.sp_OAGetErrorInfo	@OLEStream ,@Source OUT ,@Descript OUT
Destroy:					EXEC @Code = sys.sp_OADestroy		@OLEStream
	END
	-- Вывод ошибок
	IF (@Method IS NOT NULL) BEGIN
		RAISERROR('Ошибка при выполнении метода "%s" в "%s": %s',18,1,@Method,@Source,@Descript)
		RETURN	@@Error
	END
END

GO