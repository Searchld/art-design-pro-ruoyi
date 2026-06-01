import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import {
  fetchTopNotices,
  markAllNoticesRead,
  markNoticeRead,
  type NoticeType,
  type TopNotice
} from '@/api/system/notice'

const NOTICE_TYPES: NoticeType[] = ['1', '2', '3']
const POLL_INTERVAL = 60_000

export const useNoticeStore = defineStore('noticeStore', () => {
  const lists = ref<Record<NoticeType, TopNotice[]>>({ '1': [], '2': [], '3': [] })
  const unreadCounts = ref<Record<NoticeType, number>>({ '1': 0, '2': 0, '3': 0 })
  const loading = ref(false)
  let pollTimer: ReturnType<typeof setInterval> | undefined

  const totalUnread = computed(() =>
    NOTICE_TYPES.reduce((total, type) => total + unreadCounts.value[type], 0)
  )

  const refresh = async (silent = false) => {
    if (loading.value) return
    loading.value = true
    try {
      const results = await Promise.all(NOTICE_TYPES.map((type) => fetchTopNotices(type, silent)))
      NOTICE_TYPES.forEach((type, index) => {
        lists.value[type] = results[index].rows
        unreadCounts.value[type] = results[index].unreadCount
      })
    } catch (error) {
      if (!silent) throw error
    } finally {
      loading.value = false
    }
  }

  const read = async (noticeId: number) => {
    await markNoticeRead(noticeId)
    await refresh(true)
  }

  const readAll = async () => {
    await markAllNoticesRead()
    await refresh(true)
  }

  const startPolling = () => {
    stopPolling()
    void refresh(true)
    pollTimer = setInterval(() => void refresh(true), POLL_INTERVAL)
  }

  const stopPolling = () => {
    if (pollTimer) {
      clearInterval(pollTimer)
      pollTimer = undefined
    }
  }

  return {
    lists,
    unreadCounts,
    totalUnread,
    loading,
    refresh,
    read,
    readAll,
    startPolling,
    stopPolling
  }
})
