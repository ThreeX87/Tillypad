USE Greenbars
GO
/****** Object:  StoredProcedure [dbo].[external_Rep]    Script Date: 10.06.2022 10:06:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[external_ExportMoveDocuments] (
	 @mdoc_id	uniqueidentifier
	,@Encoding	SysName	= 'utf-8'
) WITH EXECUTE AS OWNER AS BEGIN
	DECLARE	 @OLEStream	Int
			,@Code		Int
			,@Method	SysName
			,@Source	SysName
			,@Descript	NVarChar(4000)
			,@mdit_id	uniqueidentifier
			,@volume	nvarchar(max)
			,@file		SysName
	EXEC @Code = sys.sp_OACreate 'ADODB.Stream' ,@OLEStream OUT
	IF (@Code != 0)
		SELECT	 @Method	= 'Scripting.Stream'
				,@Source	= 'sp_OACreate'
				,@Descript	= 'Ошибка создания OLE объекта'
	ELSE BEGIN
		SET @Method = 'Open';		EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method					IF (@Code != 0) GOTO Error;
		SET @Method = 'CharSet';	EXEC @Code = sys.sp_OASetProperty	@OLEStream ,@Method, @Encoding		IF (@Code != 0) GOTO Error;

		Declare @Data		NVarChar(max)
		select @file='\\ss01\export\'+mdoc_name+'.txt' from tp_MoveDocuments where mdoc_id=@mdoc_id

		declare curSave cursor local for
		select mdit_id from tp_movedocumentitems
			where mdit_mdoc_id=@mdoc_id

		open curSave
		fetch next from curSave into @mdit_id

		while @@FETCH_STATUS=0
		begin
			select @volume=substring(mdit_comment,charindex(';',mdit_comment)+1,len(mdit_comment)-charindex(';',mdit_comment)) 
				from tp_MoveDocumentItems where mdit_id=@mdit_id
			select @data=pitm_article+';'+@volume+';1'+char(13)+char(10)
				from tp_MoveDocumentItems
				join tp_ProductItems on pitm_id=mdit_pitm_id
				where mdit_id=@mdit_id
			SET @Method = 'WriteText';	EXEC @Code = sys.sp_OAMethod		@OLEStream ,@Method ,NULL ,@Data	IF (@Code != 0) GOTO Error;
			FETCH NEXT FROM curSave  INTO @mdit_id
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

--select * from tp_MoveDocumentItems