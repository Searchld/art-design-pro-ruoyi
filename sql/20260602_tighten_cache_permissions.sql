-- 缓存敏感操作权限收紧。新增权限仅超级管理员默认拥有，不自动授予现有普通角色。
insert into sys_menu (
  menu_id, menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark
)
select 1067, '缓存详情', 114, 1, '#', '', '', '', 1, 0, 'F', '0', '0',
       'monitor:cache:query', '#', 'admin', sysdate(), '查看缓存内容'
where not exists (select 1 from sys_menu where menu_id = 1067);

insert into sys_menu (
  menu_id, menu_name, parent_id, order_num, path, component, query, route_name,
  is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark
)
select 1068, '缓存清理', 114, 2, '#', '', '', '', 1, 0, 'F', '0', '0',
       'monitor:cache:remove', '#', 'admin', sysdate(), '清理缓存键、缓存分类或全部缓存'
where not exists (select 1 from sys_menu where menu_id = 1068);
