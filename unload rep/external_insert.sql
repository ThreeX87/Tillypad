IF OBJECT_ID(N'external_insert', 'P') IS NOT NULL 
	DROP PROCEDURE dbo.external_insert
GO
create procedure external_insert @data nvarchar(max), @stat int
as begin
	declare @num int
	select @num=count(num)+1 from external_checks
	if (@stat=1)
		insert into external_checks
		values (@data,@num)
	if (@stat=0)
		delete external_checks
end