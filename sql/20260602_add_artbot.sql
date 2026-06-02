-- Art Bot model configuration and persistent chat history. Idempotent migration.
create table if not exists sys_artbot_model (
  model_id          bigint(20)      not null auto_increment comment '模型ID',
  model_name        varchar(100)    not null                comment '模型名称',
  base_url          varchar(500)    not null                comment 'OpenAI兼容接口地址',
  api_key           varchar(500)    not null                comment 'API Key',
  model_code        varchar(200)    not null                comment '模型标识',
  status            char(1)         default '0'             comment '状态（0正常 1停用）',
  is_default        char(1)         default '0'             comment '默认模型（0否 1是）',
  temperature       decimal(3,2)    default 0.70            comment '温度参数',
  max_tokens        int             default 2048            comment '最大输出Token',
  system_prompt     text                                  comment '系统提示词',
  create_by         varchar(64)      default '',
  create_time       datetime,
  update_by         varchar(64)      default '',
  update_time       datetime,
  remark            varchar(500)     default null,
  primary key (model_id)
) engine=innodb auto_increment=1 comment='Art Bot模型配置';

create table if not exists sys_artbot_conversation (
  conversation_id   bigint(20)      not null auto_increment comment '会话ID',
  user_id           bigint(20)      not null                comment '用户ID',
  model_id          bigint(20)      not null                comment '模型ID',
  title             varchar(100)    not null                comment '会话标题',
  create_time       datetime,
  update_time       datetime,
  primary key (conversation_id),
  key idx_artbot_conversation_user (user_id, update_time),
  key idx_artbot_conversation_model (model_id)
) engine=innodb auto_increment=1 comment='Art Bot会话';

create table if not exists sys_artbot_message (
  message_id        bigint(20)      not null auto_increment comment '消息ID',
  conversation_id   bigint(20)      not null                comment '会话ID',
  role              varchar(20)     not null                comment '角色',
  content           longtext        not null                comment '消息内容',
  create_time       datetime,
  primary key (message_id),
  key idx_artbot_message_conversation (conversation_id, message_id)
) engine=innodb auto_increment=1 comment='Art Bot消息';

insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 119, 'AI模型管理', 1, 9, 'artbot', 'system/artbot/index', '', 'ArtBotModel', 1, 0, 'C', '0', '0', 'system:artbot:list', 'ri:robot-2-line', 'admin', sysdate(), 'Art Bot模型管理'
where not exists (select 1 from sys_menu where menu_id = 119);

insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1061, '模型查询', 119, 1, '#', '', '', '', 1, 0, 'F', '0', '0', 'system:artbot:query', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1061);
insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1062, '模型新增', 119, 2, '#', '', '', '', 1, 0, 'F', '0', '0', 'system:artbot:add', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1062);
insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1063, '模型修改', 119, 3, '#', '', '', '', 1, 0, 'F', '0', '0', 'system:artbot:edit', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1063);
insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1064, '模型删除', 119, 4, '#', '', '', '', 1, 0, 'F', '0', '0', 'system:artbot:remove', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1064);
insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1065, '连接测试', 119, 5, '#', '', '', '', 1, 0, 'F', '0', '0', 'system:artbot:test', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1065);
insert into sys_menu (menu_id, menu_name, parent_id, order_num, path, component, query, route_name, is_frame, is_cache, menu_type, visible, status, perms, icon, create_by, create_time, remark)
select 1066, '使用AI助手', 119, 6, '#', '', '', '', 1, 0, 'F', '0', '0', 'artbot:chat:use', '#', 'admin', sysdate(), ''
where not exists (select 1 from sys_menu where menu_id = 1066);

insert into sys_role_menu (role_id, menu_id)
select role_id, 1066 from sys_role
where not exists (
  select 1 from sys_role_menu where sys_role_menu.role_id = sys_role.role_id and sys_role_menu.menu_id = 1066
);
