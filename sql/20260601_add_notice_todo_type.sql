-- 通知公告新增待办分类（幂等增量脚本）
insert into sys_dict_data (
  dict_sort, dict_label, dict_value, dict_type, css_class, list_class,
  is_default, status, create_by, create_time, update_by, update_time, remark
)
select 3, '待办', '3', 'sys_notice_type', '', 'info',
       'N', '0', 'admin', sysdate(), '', null, '待办'
where not exists (
  select 1 from sys_dict_data
  where dict_type = 'sys_notice_type' and dict_value = '3'
);
