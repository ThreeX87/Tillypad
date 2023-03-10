USE MMGrinvich
GO
/****** Object:  StoredProcedure [dbo].[EXTERNAL_SPR]    Script Date: 07.12.2022 17:05:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[EXTERNAL_SPR] 
		@file nvarchar(max),
		@group uniqueidentifier,
		@service uniqueidentifier,
		@menuvolumetypes uniqueidentifier
	as
begin
	/* Временные таблицы импорта
		create table EXTERNAL_TillGes_first
			(list1 varchar(max))

		create table EXTERNAL_TillGes
			(list1 varchar(max), list2 varchar(max), list3 varchar(max), list4 varchar(max), list5 varchar(max), list6 varchar(max),
			list7 varchar(max), list8 varchar(max), list9 varchar(max), list10 varchar(max), list11 varchar(max), list12 varchar(max),
			list13 varchar(max), list14 varchar(max), list15 varchar(max), list16 varchar(max), list17 varchar(max), list18 varchar(max))
	*/
	Declare @cmd nvarchar(max)
	DECLARE @FileName varchar(255) = @file + '.spr'
	DECLARE @FileNameCsv varchar(255) = @file + '.copy'
	DECLARE @File_Exists int
	--------------------------------------------
	--Проверяем наличие файла spr
	--------------------------------------------
	EXEC Master.dbo.xp_fileexist @FileName, @File_Exists OUT
	IF @File_Exists = 1
	begin
	--------------------------------------------
	--Импортируем все из файла
	--------------------------------------------
		delete from EXTERNAL_TillGes_first
		SET @cmd = 'BULK INSERT EXTERNAL_TillGes_first FROM ''' + @file + '.spr'' WITH (CODEPAGE =''ACP'');'
		exec (@cmd)
	--------------------------------------------
	--Удаление не нужных строк из исходных данных
	--------------------------------------------
		delete from EXTERNAL_TillGes_first
		where list1 like '#%' or list1 like '$$$%' or list1 like '%goods_attr%'
	--------------------------------------------
	--Сохранение измененных данных во временный файл
	--------------------------------------------
		EXEC external_csv @FileNameCsv
	--------------------------------------------
	--Импорт из временного файла с разбиением по столбикам
	--------------------------------------------
		SET @cmd = 'BULK INSERT EXTERNAL_TillGes FROM ''' + @FileNameCsv + ''' WITH (FIELDTERMINATOR = '';'', ROWTERMINATOR=''\n'', CODEPAGE =''ACP'');'
		EXEC  (@cmd)
	--------------------------------------------
	--Удаление дубликатов
	--------------------------------------------
		DELETE T
			FROM
			(
			SELECT *
			, DupRank = ROW_NUMBER() OVER (
						  PARTITION BY list1
						  ORDER BY (SELECT NULL)
						)
			FROM external_tillges
			) AS T
			WHERE DupRank > 1 
	--------------------------------------------
	--Удаление флага, временного и исходного файлов
	--------------------------------------------
		select @cmd = 'del ' + @file + '.copy'
		select @cmd = 'master..xp_cmdshell ''' + @cmd + ''''
		exec(@cmd)
		select @cmd = 'del ' + @file + '.flz'
		select @cmd = 'master..xp_cmdshell ''' + @cmd + ''''
		exec(@cmd)
		select @cmd = 'del ' + @file + '.spr'
		select @cmd = 'master..xp_cmdshell ''' + @cmd + ''''
		exec(@cmd)
	--------------------------------------------
	--Обновление групп элементов прейскуранта
	--------------------------------------------
	;with
		Rec (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description
				from tp_MenuGroups M
				inner join Rec R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		update M
		set M.mgrp_name = list3, M.mgrp_del_ID = null, M.mgrp_mgrp_ID_Parent = @group
		from tp_MenuGroups M
		join EXTERNAL_TillGes on M.mgrp_QuickCode = list1
		join Rec R on R.mgrp_id = M.mgrp_ID
		where list18 is null
	--------------------------------------------
	--Добавление новых групп элементов прейскуранта
	--------------------------------------------
	;with
		Rec1 (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description, mgrp_QuickCode)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				inner join Rec1 R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		insert into tp_menugroups (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_QuickCode, mgrp_NotForSale, mgrp_IsDisabled)
		select newid(), @group, list3, list1, 0, 0
		from EXTERNAL_TillGes
		left join Rec1 R on R.mgrp_QuickCode = list1
		where list18 is null and mgrp_id is null
	--------------------------------------------
	--Обновление элементов прейскуранта
	--------------------------------------------
	;with
		Rec2 (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description, mgrp_QuickCode)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				inner join Rec2 R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		update tp_menuitems 
		set mitm_price = list5, mitm_name = list3, mitm_del_ID = null, mitm_mgrp_ID = @group
		from tp_MenuItems
		join EXTERNAL_TillGes on mitm_QuickCode = list1
		join Rec2 on mitm_mgrp_ID = mgrp_ID
		where list18 is not null
	--------------------------------------------
	--Добавление новых элементов прейскуранта
	--------------------------------------------
	;with
		Rec3 (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description, mgrp_QuickCode)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				inner join Rec3 R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		insert into tp_menuitems (mitm_ID, mitm_mgrp_ID, mitm_micl_ID, mitm_msrv_ID, mitm_mvtp_ID,
		mitm_name, mitm_ShortName, mitm_Article, mitm_Price, mitm_Volume, mitm_VAT,
		mitm_QuickCode, mitm_IsInheritIdentifiers, mitm_IsInheritTariffs, mitm_IsShortcut, mitm_IsDisabled, mitm_mifsct_ID)
		select newid(), @group, 1, @service, @menuvolumetypes,
		list3, list3, list1, list5, 1, 0,
		list1, 1, 1, 0, 0, 1
		from EXTERNAL_TillGes
		where list18 is not null
		and list1 not in (
			select mitm_quickcode from tp_MenuItems
			join Rec3 on mitm_mgrp_ID = mgrp_ID
			where mitm_del_id is null)
	--------------------------------------------
	--Сортировка по группам
	--------------------------------------------
	;with
		Rec4 (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description, mgrp_QuickCode)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				inner join Rec4 R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		update tp_menuitems
			set mitm_mgrp_ID = M.mgrp_id
				from tp_menuitems 
				join EXTERNAL_TillGes on mitm_QuickCode = list1
				join tp_menugroups M on M.mgrp_QuickCode = list16 and M.mgrp_id in (select Q.mgrp_id from Rec4 Q)
			where list18 is not null
			and mitm_mgrp_id in (select R.mgrp_id from Rec4 R)

	;with
		Rec5 (mgrp_id, mgrp_mgrp_ID_Parent, mgrp_name, mgrp_Description, mgrp_QuickCode)
		as (
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				where mgrp_id = @group
			union all
			select M.mgrp_id, M.mgrp_mgrp_ID_Parent, M.mgrp_name, M.mgrp_Description, M.mgrp_QuickCode
				from tp_MenuGroups M
				inner join Rec5 R on R.mgrp_id = M.mgrp_mgrp_ID_Parent
			)
		update A
			set A.mgrp_mgrp_ID_Parent = B.mgrp_id
				from tp_menugroups A
				join EXTERNAL_TillGes C on A.mgrp_QuickCode = C.list1
				join Rec5 B on C.list16 = B.mgrp_QuickCode
			where c.list18 is null
			and A.mgrp_id in (select R.mgrp_id from Rec5 R)
	--------------------------------------------
	--Чистим временную таблицу
	--------------------------------------------
		delete from EXTERNAL_TillGes_first
		delete from EXTERNAL_TillGes
	end
end