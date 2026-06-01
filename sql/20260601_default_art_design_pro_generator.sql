-- 新导入的代码生成业务表默认使用 Art Design Pro 模板。
-- 不更新已有 gen_table 记录，保留历史记录原有模板选择。
alter table gen_table
  modify column tpl_web_type varchar(30) default 'art-design-pro'
  comment '前端模板类型（Art Design Pro、element-ui、element-plus模版）';
