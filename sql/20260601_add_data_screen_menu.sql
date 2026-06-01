-- Replace the built-in RuoYi external data-screen link with the local Art full-screen page.
-- Run after sql/20260601_extend_menu_meta.sql.

update sys_menu
set menu_name = '数据大屏',
    parent_id = 0,
    order_num = 5,
    path = 'screen',
    component = null,
    route_name = 'Screen',
    is_frame = 1,
    menu_type = 'M',
    visible = '0',
    status = '0',
    perms = '',
    icon = 'ri:dashboard-3-line',
    external_link = '',
    is_full_page = '0',
    new_tab = '0',
    remark = '数据大屏目录'
where menu_id = 4;

insert into sys_menu
  (menu_id, menu_name, parent_id, order_num, path, component, query, route_name,
   is_frame, is_cache, menu_type, visible, status, perms, icon,
   external_link, show_badge, show_text_badge, is_hide_tab, fixed_tab, active_path,
   is_full_page, new_tab, create_by, create_time, update_by, update_time, remark)
select
  118, '大屏展示', 4, 1, 'display', 'screen/display/index', '', 'ScreenDisplay',
  1, 0, 'C', '0', '0', '', 'ri:dashboard-3-line',
  '', '0', '', '0', '0', '',
  '1', '0', 'admin', sysdate(), '', null, '溜井数字化监控大屏'
where not exists (select 1 from sys_menu where menu_id = 118);

update sys_menu
set menu_name = '大屏展示',
    parent_id = 4,
    order_num = 1,
    path = 'display',
    component = 'screen/display/index',
    route_name = 'ScreenDisplay',
    is_frame = 1,
    is_cache = 0,
    menu_type = 'C',
    visible = '0',
    status = '0',
    perms = '',
    icon = 'ri:dashboard-3-line',
    external_link = '',
    is_full_page = '1',
    new_tab = '0',
    remark = '溜井数字化监控大屏'
where menu_id = 118;

insert into sys_role_menu (role_id, menu_id)
select role.role_id, menu.menu_id
from sys_role role
join sys_menu menu on menu.menu_id in (4, 118)
where not exists (
  select 1
  from sys_role_menu role_menu
  where role_menu.role_id = role.role_id
    and role_menu.menu_id = menu.menu_id
);
