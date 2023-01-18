
/*
select dev_name, pgrp_name, rprt_name 
from tp_devices
join tp_ProductGroups on pgrp_Description=dev_id
join tp_reports on rprt_Description=convert(nvarchar(max),pgrp_id)
where dev_del_ID is null and pgrp_del_ID is null and rprt_del_ID is null

select dev_ID, pgrp_ID, rprt_ID 
from tp_devices
join tp_ProductGroups on pgrp_Description=dev_id
join tp_reports on rprt_Description=convert(nvarchar(max),pgrp_id)
where dev_del_ID is null and pgrp_del_ID is null and rprt_del_ID is null
*/

alter procedure external_DelFile  as
begin
declare @cmd nvarchar(max)

set @cmd='xp_cmdshell ''del "\\ss01\export\expzakm.txt"'''

exec (@cmd)
end