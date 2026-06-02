-- 用户界面偏好。界面风格按用户持久化，不再写入全局 sys_config。
create table if not exists sys_user_ui_setting (
  user_id bigint(20) not null comment '用户ID',
  config_key varchar(100) not null comment '界面偏好键名',
  config_value varchar(500) default '' comment '界面偏好值',
  update_by varchar(64) default '' comment '更新者',
  update_time datetime comment '更新时间',
  primary key (user_id, config_key)
) engine=innodb comment='用户界面偏好表';

-- 将升级前的全局界面风格作为现有用户初始值，后续每个用户独立维护。
insert ignore into sys_user_ui_setting(user_id, config_key, config_value, update_by, update_time)
select u.user_id, c.config_key, c.config_value, 'migration', sysdate()
from sys_user u
join sys_config c on c.config_key in (
  'ui.theme.mode',
  'ui.menu.layout',
  'ui.menu.style',
  'ui.theme.color',
  'ui.box.style',
  'ui.container.width',
  'ui.watermark.enabled',
  'ui.tabs.enabled',
  'ui.breadcrumb.enabled',
  'ui.menu.accordion'
);

delete from sys_config
where config_key in (
  'ui.theme.mode',
  'ui.menu.layout',
  'ui.menu.style',
  'ui.theme.color',
  'ui.box.style',
  'ui.container.width',
  'ui.watermark.enabled',
  'ui.tabs.enabled',
  'ui.breadcrumb.enabled',
  'ui.menu.accordion'
);
