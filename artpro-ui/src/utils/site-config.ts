import { reactive } from 'vue'
import AppConfig from '@/config'
import { fetchSiteConfig } from '@/api/system/config'

export const siteConfig = reactive<Record<string, string>>({
  'site.name': AppConfig.systemInfo.name,
  'site.description': '商业化中后台管理系统',
  'site.login.title': '欢迎回来',
  'site.login.description': '输入您的账号和密码登录',
  'site.login-left-title': '专注用户体验',
  'site.login-left-sub-title': '基于 Art Design Pro 与 RuoYi 构建',
  'site.watermark.content': '',
  'site.watermark.mode': 'username',
  'site.watermark.show-time': 'false'
})

export const getSiteConfig = (key: string, fallback = '') => siteConfig[key] || fallback

export async function loadSiteConfig() {
  Object.assign(siteConfig, await fetchSiteConfig())
  AppConfig.systemInfo.name = getSiteConfig('site.name', AppConfig.systemInfo.name)
}
