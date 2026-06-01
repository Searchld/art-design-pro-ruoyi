-- Extend RuoYi menus with Art Design Pro route metadata and migrate icons to local Remix Icon names.
-- This script is idempotent on MySQL 5.7+.

delimiter //
drop procedure if exists add_sys_menu_column//
create procedure add_sys_menu_column(in requested_column varchar(64), in column_definition varchar(500))
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = database() and table_name = 'sys_menu' and column_name = requested_column
  ) then
    set @ddl = concat('alter table sys_menu add column ', requested_column, ' ', column_definition);
    prepare statement from @ddl;
    execute statement;
    deallocate prepare statement;
  end if;
end//
delimiter ;

call add_sys_menu_column('external_link', "varchar(500) default '' comment '外部链接'");
call add_sys_menu_column('show_badge', "char(1) default '0' comment '显示圆点徽章（0否 1是）'");
call add_sys_menu_column('show_text_badge', "varchar(50) default '' comment '文本徽章'");
call add_sys_menu_column('is_hide_tab', "char(1) default '0' comment '隐藏标签页（0否 1是）'");
call add_sys_menu_column('fixed_tab', "char(1) default '0' comment '固定标签页（0否 1是）'");
call add_sys_menu_column('active_path', "varchar(200) default '' comment '激活菜单路径'");
call add_sys_menu_column('is_full_page', "char(1) default '0' comment '全屏页面（0否 1是）'");
call add_sys_menu_column('new_tab', "char(1) default '0' comment '新标签打开（0否 1是）'");
drop procedure add_sys_menu_column;

update sys_menu
set external_link = path
where (external_link is null or external_link = '')
  and path regexp '^https?://';

update sys_menu
set icon = case icon
  when 'dashboard' then 'ri:pie-chart-line'
  when 'system' then 'ri:settings-3-line'
  when 'monitor' then 'ri:computer-line'
  when 'tool' then 'ri:tools-line'
  when 'guide' then 'ri:guide-line'
  when 'console' then 'ri:home-smile-2-line'
  when 'analysis' then 'ri:bar-chart-box-line'
  when 'ecommerce' then 'ri:shopping-bag-3-line'
  when 'user' then 'ri:user-line'
  when 'peoples' then 'ri:team-line'
  when 'tree-table' then 'ri:menu-line'
  when 'tree' then 'ri:node-tree'
  when 'post' then 'ri:briefcase-line'
  when 'dict' then 'ri:book-2-line'
  when 'edit' then 'ri:edit-line'
  when 'message' then 'ri:notification-3-line'
  when 'log' then 'ri:file-list-3-line'
  when 'online' then 'ri:global-line'
  when 'job' then 'ri:timer-line'
  when 'druid' then 'ri:database-2-line'
  when 'server' then 'ri:server-line'
  when 'redis' then 'ri:database-2-line'
  when 'redis-list' then 'ri:list-check-3'
  when 'build' then 'ri:tools-line'
  when 'code' then 'ri:code-s-slash-line'
  when 'swagger' then 'ri:file-code-line'
  when 'form' then 'ri:file-list-3-line'
  when 'logininfor' then 'ri:login-box-line'
  else 'ri:menu-line'
end
where icon is null or icon = '' or icon = '#' or icon not like 'ri:%';

update sys_menu
set is_full_page = '1'
where menu_id = 118;
