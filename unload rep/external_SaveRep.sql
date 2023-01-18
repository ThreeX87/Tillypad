IF OBJECT_ID(N'external_SaveRep', 'P') IS NOT NULL 
	DROP PROCEDURE dbo.external_SaveRep
GO

create procedure external_SaveRep @chck_dev_id uniqueidentifier,
				@tr_dev nvarchar(10),
				@date date
as
begin

if OBJECT_ID('tempdb..#Check') is not null drop table #Check
create table #Check(	--Временная таблица для транзакций
	tr_num int,
	tr_date date,
	tr_time time,
	tr_type int,
	tr_dev nvarchar(10),
	tr_chck int,
	tr_kassir int,
	tr_1 nvarchar(30),
	tr_2 nvarchar(30),
	tr_3 nvarchar(30),
	tr_4 nvarchar(30),
	tr_5 nvarchar(30))

----------Исходные данные, получаемые в задаче
--declare @chck_dev_id uniqueidentifier
--declare @date date
--declare @tr_dev nvarchar(10)
declare @tr_kassir int
declare @tr_num int
declare @chck_id uniqueidentifier
declare @chck_name nvarchar(10)
declare @idnt nvarchar(20)

--set @chck_dev_id='48556B48-0EA2-A243-BEB8-B87CD5970D67'
set @tr_num=0
--set @tr_dev='803'
set @tr_kassir=1
--set @date='2022-05-21'


declare curChecks cursor local for

select chck_id, chck_name from tp_Checks
--join tp_CheckItems on chit_chck_id=chck_id
where chck_date>@date and chck_date<dateadd(day,1,@date)
and chck_dev_id=@chck_dev_id
order by chck_name


open curChecks 
fetch next from curChecks into @chck_id, @chck_name

while @@FETCH_STATUS=0
begin
--Добавляем 11 транзакцию
insert into #Check
select @tr_num+row_number() over(order by chck_name),	--порядковый номер транзакции	--row_number() over(order by chck_name),
	convert(date,chck_date),	--дата чека
	convert(time,chck_date),	--время чека
	'11',						--тип транзакции
	@tr_dev,					--номер кассы
	convert(int,chck_name),		--номер чека
	'1',						--код кассира
	mitm_Article,				--код товара
	'1',						--секция
	round(chit_Price/chit_volume,2),		--цена
	chit_Count*chit_volume,		--количество
	chit_price*chit_count		--сумма позиции
from tp_Checks
join tp_CheckItems on chit_chck_id=chck_id
join tp_MenuItems on mitm_id=chit_mitm_ID
where chck_id=@chck_id

select @tr_num=count(tr_num) from #Check
--Добавляем 37 и 71 транзакции при наличии ДК
select top(1) @idnt=idnt_Code
	from tp_checks
	join tp_PreChecks on prch_id=chck_prch_ID
	join tp_PreCheckItems on pcit_prch_id=prch_id
	join tp_orderitems on orit_pcit_id=pcit_id
	join tp_orders on ordr_id=orit_ordr_ID
	join tp_guests on gest_id=ordr_gest_id
	join tp_clients on gest_clnt_id=clnt_id
	join tp_ClientIdentifiers on clid_clnt_id=clnt_id
	join tp_identifiers on idnt_id=clid_idnt_ID
where chck_id=@chck_id
select @tr_num=count(tr_num) from #Check
if(@idnt is not null)
begin
	insert into #Check
	select @tr_num+row_number() over(order by chck_name),
		convert(date,chck_date),	--дата чека
		convert(time,chck_date),	--время чека
		'37',						--тип транзакции
		@tr_dev,					--номер кассы
		convert(int,@chck_name),	--номер чека
		'1',						--код кассира
		'',
		'',
		'',
		'0',
		'0'
	from tp_Checks
	where chck_id=@chck_id

	select @tr_num=count(tr_num) from #Check

	insert into #Check
	select @tr_num+row_number() over(order by chck_name),
		convert(date,chck_date),	--дата чека
		convert(time,chck_date),	--время чека
		'71',						--тип транзакции
		@tr_dev,					--номер кассы
		convert(int,@chck_name),	--номер чека
		'1',						--код кассира
		@idnt,
		'3',
		'',
		'',
		'0'
	from tp_Checks
	where chck_id=@chck_id

	set @idnt=null
end
select @tr_num=count(tr_num) from #Check
--Добавляем 40 транзакцию
insert into #Check
select @tr_num+row_number() over(order by chck_name),
	convert(date,chck_date),	--дата чека
	convert(time,chck_date),	--время чека
	'40',						--тип транзакции
	@tr_dev,					--номер кассы
	convert(int,@chck_name),	--номер чека
	'1',						--код кассира
	'',
	'0',
	'0',
	pptitp_PayIndex+1,			--вид оплаты
	chpy_sum					--сумма оплаты
from tp_Checks
join tp_CheckPayments on chpy_chck_id=chck_id
join tp_PayTypes on pytp_id=chpy_pytp_ID
join (select *
	from tp_PayProperties   
	join tp_PayPropertyItems on pptit_ppty_ID=ppty_id
	join tp_PayPropertyItemPaymentTypes on pptitp_pptit_ID=pptit_ID
	join tp_PayTypes on pptitp_pytp_ID=pytp_id
	join tp_DeviceValues on dvvl_value=ppty_id
	where dvvl_dev_id=@chck_dev_id) B on B.pytp_id=chpy_pytp_ID
where chck_date>@date and chck_date<dateadd(day,1,@date)
and chck_id=@chck_ID
select @tr_num=count(tr_num) from #Check
--Добавляем 55 транзакцию
insert into #Check
select @tr_num+row_number() over(order by chck_date),
	convert(date,chck_date),	--дата чека
	convert(time,chck_date),	--время чека
	'55',						--тип транзакции
	@tr_dev,					--номер кассы
	convert(int,@chck_name),	--номер чека
	'1',						--код кассира
	'',
	'0',
	'',
	'',			
	sum(chpy_sum)					--сумма чека
from tp_Checks
join tp_CheckPayments on chpy_chck_id=chck_id
where chck_id=@chck_ID
group by chck_date
select @tr_num=count(tr_num) from #Check

FETCH NEXT FROM curChecks  INTO @chck_ID, @chck_name
end

declare @data nvarchar(max)

exec external_insert '',0
exec external_insert '#',1
exec external_insert @tr_dev,1
exec external_insert '0',1
declare cur cursor local for
select tr_num
from #Check
order by tr_num

open cur
fetch next from cur into @tr_num

while @@FETCH_STATUS=0
begin

select @data=convert(nvarchar(5),tr_num)+';'
		+substring(convert(nvarchar(10),tr_date),9,2)+'.'
		+substring(convert(nvarchar(10),tr_date),6,2)+'.'
		+substring(convert(nvarchar(10),tr_date),1,4)+';'
		+convert(nvarchar(8),tr_time)+';'
		+convert(nvarchar(8),tr_type)+';'
		+tr_dev+';'
		+convert(nvarchar(8),tr_chck)+';'
		+convert(nvarchar(8),tr_kassir)+';'
		+tr_1+';'
		+tr_2+';'
		+tr_3+';'
		+tr_4+';'
		+tr_5
	from #Check where tr_num=convert(int,@tr_num)
	
--select * from #Check
--select * from external_checks order by num

exec external_insert @data,1

FETCH NEXT FROM cur  INTO @tr_num
end

end