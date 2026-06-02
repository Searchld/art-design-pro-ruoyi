<template>
  <div class="art-full-height">
    <ArtSearchBar
      v-show="showSearchBar"
      v-model="filters"
      :items="searchItems"
      :show-expand="false"
      @search="load"
      @reset="reset"
    />
    <ElCard class="art-table-card">
      <ArtTableHeader
        v-model:columns="columnChecks"
        v-model:show-search-bar="showSearchBar"
        :loading="loading"
        @refresh="load"
      >
        <template #left>
          <ElSpace wrap>
            <ElButton v-if="hasAuth('system:menu:add')" type="primary" @click="openDialog()"
              >新增菜单</ElButton
            >
            <ElButton @click="toggleExpand">{{ expanded ? '收起' : '展开' }}</ElButton>
            <ElButton v-if="hasAuth('system:menu:edit')" @click="saveSort">保存排序</ElButton>
          </ElSpace>
        </template>
      </ArtTableHeader>
      <ArtTable
        ref="tableRef"
        row-key="menuId"
        :loading="loading"
        :data="treeData"
        :columns="columns"
        :pagination="undefined"
      />
    </ElCard>

    <ElDrawer v-model="visible" :title="drawerTitle" size="920px" class="menu-edit-drawer">
      <ArtForm
        ref="formRef"
        v-model="form"
        :items="drawerFormItems"
        :rules="rules"
        :show-submit="false"
        :show-reset="false"
        label-width="96px"
      >
        <template #displayType>
          <div>
            <ElRadioGroup v-model="form.displayType">
              <ElRadioButton v-for="item in typeOptions" :key="item.value" :value="item.value">{{
                item.label
              }}</ElRadioButton>
            </ElRadioGroup>
            <div class="mt-2 text-sm text-g-500"
              >新建时可直接选择类型。按钮权限仍需挂在具体菜单下。</div
            >
          </div>
        </template>
        <template #icon>
          <div class="flex w-full items-center gap-2">
            <ArtSvgIcon :icon="form.icon" class="text-xl" />
            <ElInput v-model="form.icon" placeholder="如：ri:user-line" />
            <ElButton type="primary" link @click="iconPickerVisible = true">选择图标</ElButton>
          </div>
        </template>
      </ArtForm>
      <template #footer>
        <ElButton @click="visible = false">取消</ElButton>
        <ElButton v-if="mode !== 'view'" type="primary" @click="submit">确定</ElButton>
      </template>
    </ElDrawer>

    <ElDrawer v-model="iconPickerVisible" title="选择图标" size="980px" append-to-body>
      <div class="icon-picker-toolbar">
        <ElInput
          v-model="iconKeyword"
          clearable
          placeholder="搜索图标名称，如 user、menu、setting"
        />
        <span>Remix Icon</span>
        <span>共 {{ filteredIcons.length }} 个</span>
      </div>
      <div class="icon-picker-grid">
        <button
          v-for="icon in filteredIcons"
          :key="icon"
          type="button"
          class="icon-picker-item"
          :class="{ 'is-active': form.icon === icon }"
          @click="selectIcon(icon)"
        >
          <ArtSvgIcon :icon="icon" class="text-2xl" />
          <span>{{ icon }}</span>
        </button>
      </div>
    </ElDrawer>
  </div>
</template>

<script setup lang="ts">
  import { h, nextTick } from 'vue'
  import { ElMessageBox, ElTag } from 'element-plus'
  import riIcons from '@iconify-json/ri/icons.json'
  import ArtButtonTable from '@/components/core/forms/art-button-table/index.vue'
  import ArtSvgIcon from '@/components/core/base/art-svg-icon/index.vue'
  import {
    addMenu,
    fetchMenu,
    fetchMenuList,
    fetchMenuTree,
    removeMenu,
    updateMenu,
    updateMenuSort
  } from '@/api/system/menu'
  import { useAuth } from '@/hooks/core/useAuth'
  import { useTableColumns } from '@/hooks/core/useTableColumns'
  import { buildTree, flattenTree } from '@/utils/system/tree'
  import { normalizeLocalIcon } from '@/utils/ui/iconify-loader'
  import type { Entity } from '@/api/system/types'

  defineOptions({ name: 'SystemMenu' })
  const { hasAuth } = useAuth()
  const loading = ref(false),
    showSearchBar = ref(true),
    visible = ref(false),
    expanded = ref(false)
  const mode = ref<'add' | 'edit' | 'view'>('add')
  const iconPickerVisible = ref(false),
    iconKeyword = ref('')
  const rows = ref<Entity[]>([]),
    options = ref<Entity[]>([])
  const filters = reactive({ menuName: '', status: '' }),
    form = reactive<Entity>({})
  const tableRef = ref<any>(),
    formRef = ref<any>()
  const treeData = computed(() => buildTree(rows.value, 'menuId', 'parentId'))
  const isLinkType = computed(() => ['iframe', 'external'].includes(String(form.displayType)))
  const typeOptions = [
    { label: '目录', value: 'M' },
    { label: '菜单', value: 'C' },
    { label: '按钮', value: 'F' },
    { label: '内嵌', value: 'iframe' },
    { label: '外链', value: 'external' }
  ]
  const allIcons = Object.keys(riIcons.icons).map((name) => `ri:${name}`)
  const filteredIcons = computed(() => {
    const keyword = iconKeyword.value.trim().toLowerCase()
    return keyword ? allIcons.filter((icon) => icon.includes(keyword)) : allIcons
  })
  const searchItems = [
    { key: 'menuName', label: '菜单名称' },
    {
      key: 'status',
      label: '状态',
      type: 'select',
      props: {
        options: [
          { label: '正常', value: '0' },
          { label: '停用', value: '1' }
        ]
      }
    }
  ]
  const rules = {
    parentId: [{ required: true, message: '请选择上级菜单' }],
    menuName: [{ required: true, message: '请输入名称' }],
    orderNum: [{ required: true, message: '请输入排序' }],
    path: [{ required: true, message: '请输入路由地址' }],
    externalLink: [{ required: true, message: '请输入外部链接' }],
    perms: [{ required: true, message: '请输入权限标识' }]
  }
  const formItems = computed(() => [
    { key: 'displayType', label: '类型', span: 24 },
    {
      key: 'parentId',
      label: '上级菜单',
      type: 'treeselect',
      span: 12,
      props: {
        data: [{ id: 0, label: '主类目', children: options.value }],
        nodeKey: 'id',
        checkStrictly: true
      }
    },
    { key: 'menuName', label: form.displayType === 'F' ? '权限名称' : '菜单名称', span: 12 },
    {
      key: 'path',
      label: '路由地址',
      span: 12,
      hidden: ['F', 'external'].includes(form.displayType),
      props: {
        placeholder: form.displayType === 'iframe' ? '如：/outside/iframe/docs' : '请输入路由地址'
      }
    },
    {
      key: 'component',
      label: '组件路径',
      span: 12,
      hidden: form.displayType !== 'C',
      props: { placeholder: '如：system/user/index' }
    },
    {
      key: 'externalLink',
      label: '外部链接',
      span: 12,
      hidden: !isLinkType.value,
      props: { placeholder: '如：https://www.example.com' }
    },
    {
      key: 'perms',
      label: '权限标识',
      span: 12,
      hidden: form.displayType === 'M' || isLinkType.value
    },
    { key: 'icon', label: '图标', span: 12, hidden: form.displayType === 'F' },
    {
      key: 'orderNum',
      label: form.displayType === 'F' ? '权限排序' : '菜单排序',
      type: 'number',
      span: 12,
      props: { min: 0 }
    },
    {
      key: 'showTextBadge',
      label: '文本徽章',
      span: 12,
      hidden: form.displayType === 'F',
      props: { clearable: true, placeholder: '如：New、Hot' }
    },
    { key: 'activePath', label: '激活路径', span: 12, hidden: form.displayType !== 'C' },
    { key: 'enabled', label: '是否启用', type: 'switch', span: 6 },
    { key: 'hidden', label: '隐藏菜单', type: 'switch', span: 6, hidden: form.displayType === 'F' },
    { key: 'cache', label: '页面缓存', type: 'switch', span: 6, hidden: form.displayType !== 'C' },
    {
      key: 'showBadge',
      label: '显示徽章',
      type: 'switch',
      span: 6,
      hidden: form.displayType === 'F'
    },
    {
      key: 'fixedTab',
      label: '固定标签',
      type: 'switch',
      span: 6,
      hidden: form.displayType !== 'C'
    },
    {
      key: 'isHideTab',
      label: '标签隐藏',
      type: 'switch',
      span: 6,
      hidden: form.displayType === 'F'
    },
    {
      key: 'isFullPage',
      label: '全屏页面',
      type: 'switch',
      span: 6,
      hidden: form.displayType !== 'C'
    },
    {
      key: 'newTab',
      label: '新标签打开',
      type: 'switch',
      span: 6,
      hidden: form.displayType === 'F'
    }
  ])
  const drawerFormItems = computed(() =>
    formItems.value.map((item) => ({
      ...item,
      props: { ...item.props, disabled: mode.value === 'view' }
    }))
  )
  const drawerTitle = computed(
    () =>
      `${mode.value === 'view' ? '查看' : mode.value === 'edit' ? '编辑' : '新建'}${typeOptions.find((item) => item.value === form.displayType)?.label || '菜单'}`
  )
  const { columns, columnChecks } = useTableColumns(() => [
    { prop: 'menuName', label: '菜单名称', minWidth: 180 },
    {
      prop: 'icon',
      label: '图标',
      width: 80,
      formatter: (row: Entity) => h(ArtSvgIcon, { icon: row.icon, class: 'text-xl' })
    },
    {
      prop: 'orderNum',
      label: '排序',
      width: 90,
      formatter: (row: Entity) =>
        h('input', {
          class: 'w-14 rounded border border-g-300 px-2 py-1',
          type: 'number',
          value: row.orderNum,
          onInput: (e: Event) => (row.orderNum = Number((e.target as HTMLInputElement).value))
        })
    },
    { prop: 'perms', label: '权限标识', minWidth: 180 },
    { prop: 'component', label: '组件路径', minWidth: 170 },
    {
      prop: 'status',
      label: '状态',
      width: 90,
      formatter: (row: Entity) =>
        h(ElTag, { type: row.status === '0' ? 'success' : 'danger' }, () =>
          row.status === '0' ? '正常' : '停用'
        )
    },
    {
      prop: 'operation',
      label: '操作',
      minWidth: 220,
      fixed: 'right',
      align: 'right',
      formatter: (row: Entity) =>
        h('div', [
          hasAuth('system:menu:query')
            ? h(ArtButtonTable, { type: 'view', onClick: () => openDialog(row, 0, 'view') })
            : null,
          hasAuth('system:menu:add')
            ? h(ArtButtonTable, { type: 'add', onClick: () => openDialog(undefined, row.menuId) })
            : null,
          hasAuth('system:menu:edit')
            ? h(ArtButtonTable, { type: 'edit', onClick: () => openDialog(row) })
            : null,
          hasAuth('system:menu:remove')
            ? h(ArtButtonTable, { type: 'delete', onClick: () => removeRow(row) })
            : null
        ])
    }
  ])
  async function load() {
    loading.value = true
    try {
      rows.value = await fetchMenuList(filters)
    } finally {
      loading.value = false
    }
  }
  function reset() {
    Object.assign(filters, { menuName: '', status: '' })
    load()
  }
  async function openDialog(
    row?: Entity,
    parentId = 0,
    nextMode: 'add' | 'edit' | 'view' = row ? 'edit' : 'add'
  ) {
    Object.keys(form).forEach((key) => delete form[key])
    Object.assign(form, {
      parentId,
      displayType: 'M',
      orderNum: 0,
      enabled: true,
      hidden: false,
      cache: false,
      showBadge: false,
      isHideTab: false,
      fixedTab: false,
      isFullPage: false,
      newTab: false
    })
    options.value = await fetchMenuTree()
    if (row) {
      Object.assign(form, await fetchMenu(row.menuId))
      form.displayType = resolveDisplayType(form)
      Object.assign(form, {
        icon: normalizeLocalIcon(form.icon),
        enabled: form.status !== '1',
        hidden: form.visible === '1',
        cache: form.isCache === '0',
        showBadge: form.showBadge === '1',
        isHideTab: form.isHideTab === '1',
        fixedTab: form.fixedTab === '1',
        isFullPage: form.isFullPage === '1',
        newTab: form.newTab === '1'
      })
    }
    mode.value = nextMode
    visible.value = true
  }
  function resolveDisplayType(data: Entity) {
    if (data.externalLink || /^https?:\/\//.test(String(data.path || '')))
      return data.isFrame === '0' ? 'iframe' : 'external'
    return data.menuType || 'M'
  }
  function toMenuPayload(data: Entity) {
    const payload: Entity = {
      ...data,
      status: data.enabled ? '0' : '1',
      visible: data.hidden ? '1' : '0',
      isCache: data.cache ? '0' : '1',
      showBadge: data.showBadge ? '1' : '0',
      isHideTab: data.isHideTab ? '1' : '0',
      fixedTab: data.fixedTab ? '1' : '0',
      isFullPage: data.isFullPage ? '1' : '0',
      newTab: data.newTab ? '1' : '0',
      icon: data.displayType === 'F' ? '#' : normalizeLocalIcon(data.icon),
      showTextBadge: data.showTextBadge || ''
    }
    if (isLinkType.value) {
      payload.menuType = Number(data.parentId) === 0 ? 'M' : 'C'
      payload.isFrame = data.displayType === 'iframe' ? '0' : '1'
      payload.component = ''
      payload.perms = ''
      if (data.displayType === 'external') payload.path = data.externalLink
    } else {
      payload.menuType = data.displayType
      payload.isFrame = '1'
      payload.externalLink = ''
      if (data.displayType === 'F') {
        payload.path = ''
        payload.component = ''
      }
    }
    ;['displayType', 'enabled', 'hidden', 'cache'].forEach((key) => delete payload[key])
    return payload
  }
  async function submit() {
    await formRef.value?.validate()
    await (form.menuId ? updateMenu(toMenuPayload(form)) : addMenu(toMenuPayload(form)))
    visible.value = false
    load()
  }
  async function removeRow(row: Entity) {
    await ElMessageBox.confirm(`确定删除菜单“${row.menuName}”吗？`, '提示', { type: 'warning' })
    await removeMenu(row.menuId)
    load()
  }
  async function saveSort() {
    const list = flattenTree(treeData.value)
    await updateMenuSort(
      list.map((row) => row.menuId),
      list.map((row) => row.orderNum)
    )
    load()
  }
  function toggleExpand() {
    expanded.value = !expanded.value
    nextTick(() =>
      flattenTree(treeData.value).forEach((row) =>
        tableRef.value?.elTableRef?.toggleRowExpansion(row, expanded.value)
      )
    )
  }
  function selectIcon(icon: string) {
    form.icon = icon
    iconPickerVisible.value = false
  }
  load()
</script>

<style scoped>
  .icon-picker-toolbar {
    display: flex;
    gap: 16px;
    align-items: center;
    margin-bottom: 16px;
  }

  .icon-picker-grid {
    display: grid;
    grid-template-columns: repeat(6, minmax(0, 1fr));
    gap: 12px;
    max-height: calc(100vh - 150px);
    overflow: auto;
  }

  .icon-picker-item {
    display: flex;
    flex-direction: column;
    gap: 8px;
    align-items: center;
    justify-content: center;
    min-height: 86px;
    font-size: 12px;
    color: var(--el-text-color-regular);
    border: 1px solid var(--el-border-color);
    border-radius: 8px;
  }

  .icon-picker-item:hover,
  .icon-picker-item.is-active {
    color: var(--el-color-primary);
    border-color: var(--el-color-primary);
  }
</style>
