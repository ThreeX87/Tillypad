USE Greenbars
GO
/****** Object:  StoredProcedure [dbo].[external_SaveToFile]    Script Date: 26.05.2022 10:15:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].external_gesLoad (
	 @File		SysName
	,@Encoding	SysName	= 'utf-8'
) WITH EXECUTE AS OWNER AS BEGIN
	DECLARE	 @OLEStream	Int
			,@Code		Int
			,@Method	SysName
			,@Source	SysName
			,@Descript	NVarChar(4000)
			,@Data		NVarChar(4000)
			,@Data1		NVarChar(4000)
	EXEC @Code = sys.sp_OACreate 'ADODB.Stream' ,@OLEStream OUT
	IF (@Code != 0)
		SELECT	 @Method	= 'Scripting.Stream'
				,@Source	= 'sp_OACreate'
				,@Descript	= 'Ошибка создания OLE объекта'
	ELSE BEGIN
		SET @Method = 'Open';			EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method					IF (@Code != 0) GOTO Error;
		SET @Method = 'CharSet';		EXEC @Code = sys.sp_OASetProperty	@OLEStream ,@Method, @Encoding		IF (@Code != 0) GOTO Error;
		SET @Method = 'LoadFromFile';	EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method, null, @File	IF (@Code != 0) GOTO Error;
		SET @Method = 'ReadText';		EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method, @Data output	IF (@Code != 0) GOTO Error;
		SET @Method = 'Close';			EXEC @Code = sys.sp_OAMethod		@OLEStream, @Method					IF (@Code != 0) GOTO Error;
		SET @Method = NULL;
		 
		if(@data is not null)
			exec external_DelFile
			exec external_import @data

		GOTO Destroy;
Error:						EXEC @Code = sys.sp_OAGetErrorInfo	@OLEStream ,@Source OUT ,@Descript OUT
Destroy:					EXEC @Code = sys.sp_OADestroy		@OLEStream
	END
	-- Вывод ошибок
	IF (@Method IS NOT NULL) BEGIN
		RAISERROR('Ошибка при выполнении метода "%s" в "%s": %s',18,1,@Method,@Source,@Descript)
		RETURN	@@Error
	END
END

