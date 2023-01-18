alter procedure external_move as
begin
--tpsrv_logon
--считываем данные из файла
exec external_gesLoad '\\ss01\export\expzakm.txt'

delete external_gesImport
where gi2 in (select mdoc_name from tp_MoveDocuments)

declare @gi1 int
declare @gi2 nvarchar(max)
declare @gi4 nvarchar(max)
declare @gi6 decimal(6,3)
declare @move_id uniqueidentifier
declare @pitm_id uniqueidentifier
declare @pitm_meit_ID uniqueidentifier
declare cur cursor local for
select convert(int,gi1),gi2,gi4,convert(decimal(6,3),gi6)*convert(decimal(6,3),gi7)
from external_gesImport
order by gi1

open cur
fetch next from cur into @gi1, @gi2, @gi4, @gi6

while @@FETCH_STATUS=0
begin
	select @move_id=mdoc_id from tp_MoveDocuments where mdoc_name=@gi2
	select @pitm_id = pitm_id, @pitm_meit_ID = pitm_meit_ID from tp_ProductItems where pitm_Article=@gi4
	if(@move_id is null)
	begin
		set @move_id=newid()
		insert into tp_movedocuments
		select	@move_id,
		'2D092662-556D-CE4D-B3E2-5596861331AA',
		'936A2BE1-761F-524B-95A6-5A7D8C4ABA87',
		'440F5B91-C48D-7041-813E-B29919B3506A',
		0,
		0,
		getdate(),
		convert(int,@gi2),
		@gi2
	end
	if(@move_id is not null and @pitm_id is not null)
		insert into tp_MoveDocumentItems (	mdit_id,	mdit_mdoc_id,	mdit_pitm_id,	mdit_meit_ID,	mdit_cmmd_ID,	mdit_volume,	mdit_order,	mdit_Comment)
		select								newid(),	@move_id,		@pitm_id,		@pitm_meit_ID,	1,				@gi6,			@gi1,		convert(nvarchar(10),@gi6)+';0'
	set @move_id = null
	--select @gi1,@gi2,pitm_name,@gi6 from tp_ProductItems where pitm_Article=@gi4
	fetch next from cur into @gi1, @gi2, @gi4, @gi6
end

	delete external_gesImport
end