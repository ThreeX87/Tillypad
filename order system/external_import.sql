
alter procedure external_import @data nvarchar(4000) as
begin
declare	@i int = 0,
		@q int = 0,
		@data_temp nvarchar(4000),
		@data_temp1 nvarchar(4000),
		@data_temp2 nvarchar(4000),
		@data_temp3 nvarchar(4000)
delete external_gesImport
set @data=replace(@data,',','.')
set @data=replace(@data,' ','')
set @data=replace(@data,char(13),'')
while(charindex(char(10),@data,0)>0)
begin
	insert into external_gesImport (gi1)
	values (@i)
	set @data_temp = substring(@data,0,charindex(char(10),@data,0))
	set @data_temp = replace(@data_temp,char(10),'')
	--select @data_temp
	set @data=substring(@data,charindex(char(10),@data,0)+1,len(@data)-len(@data_temp))

	set @data_temp1 = substring(@data_temp,0,charindex(';',@data_temp,0))
	update external_gesImport
	set gi2=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

	set @data_temp1 = substring(@data_temp,0,charindex(';',@data_temp,0))
	update external_gesImport
	set gi3=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

	set @data_temp1 = substring(@data_temp,0,charindex(';',@data_temp,0))
	update external_gesImport
	set gi4=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

	set @data_temp1 = substring(@data_temp,0,charindex(';',@data_temp,0))
	update external_gesImport
	set gi5=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

	set @data_temp1 = substring(@data_temp,0,charindex(';',@data_temp,0))
	update external_gesImport
	set gi6=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

	set @data_temp1 = substring(@data_temp,0,len(@data_temp)+1)
	update external_gesImport
	set gi7=@data_temp1 where gi1=@i
	set @data_temp=substring(@data_temp,charindex(';',@data_temp,0)+1,len(@data_temp)-len(@data_temp1))

--	select @data_temp1
	set @i=@i+1
end
	/*set @i = charindex(char(13)+char(10),@data,@i)+1
	select @data_temp1 = substring(@data_temp,@q,charindex(';',@data_temp,@q))
	*/

/*
	set @q=charindex(';',@data_temp,@q)+1
	select @data_temp2 = substring(@data_temp,@q,charindex(';',@data_temp,@q)-@q)
	set @q=charindex(';',@data_temp,@q)+1
	select @data_temp3 = substring(@data_temp,@q,len(@data_temp)-@q+1)
	set @q=0
	insert into external_gesImport
	select @data_temp1,@data_temp2,@data_temp3
end
	select @data_temp = substring(@data,@i,len(@data)-@i+1)
	select @data_temp1 = substring(@data_temp,@q,charindex(';',@data_temp,@q))
	set @q=charindex(';',@data_temp,@q)+1
	select @data_temp2 = substring(@data_temp,@q,charindex(';',@data_temp,@q)-@q)
	set @q=charindex(';',@data_temp,@q)+1
	select @data_temp3 = substring(@data_temp,@q,len(@data_temp)-@q+1)
	insert into external_gesImport
	select @data_temp1,@data_temp2,@data_temp3
*/
end
