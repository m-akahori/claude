# 5. フロントエンド（Vue.js）コーディングルール

## 5.1 Vue 3 Composition API

### 5.1.1 基本構文
```vue
<script setup lang="ts">
// Composition APIを使用した基本構成
import { ref, reactive, computed, watch, onMounted } from 'vue'
import type { User } from '@/types'

// Props定義
interface Props {
  user: User
  isEditable?: boolean
}
const props = withDefaults(defineProps<Props>(), {
  isEditable: false
})

// Emits定義
interface Emits {
  update: [user: User]
  delete: [id: number]
}
const emit = defineEmits<Emits>()

// Reactive state
const isLoading = ref(false)
const formData = reactive({
  name: props.user.name,
  email: props.user.email
})

// Computed properties
const displayName = computed(() => {
  return formData.name || 'Unknown User'
})

const isFormValid = computed(() => {
  return formData.name.length > 0 && formData.email.includes('@')
})

// Watchers
watch(
  () => props.user,
  (newUser) => {
    formData.name = newUser.name
    formData.email = newUser.email
  },
  { deep: true }
)

// Methods
const handleSubmit = async () => {
  if (!isFormValid.value) return
  
  isLoading.value = true
  try {
    const updatedUser = await updateUser({
      ...props.user,
      ...formData
    })
    emit('update', updatedUser)
  } catch (error) {
    console.error('Update failed:', error)
  } finally {
    isLoading.value = false
  }
}

const handleDelete = () => {
  emit('delete', props.user.id)
}

// Lifecycle hooks
onMounted(() => {
  console.log('Component mounted')
})
</script>

<template>
  <div class="user-form">
    <h2>{{ displayName }}</h2>
    
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <label for="name">名前</label>
        <input
          id="name"
          v-model="formData.name"
          type="text"
          :disabled="!props.isEditable"
          required
        >
      </div>
      
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input
          id="email"
          v-model="formData.email"
          type="email"
          :disabled="!props.isEditable"
          required
        >
      </div>
      
      <div class="form-actions" v-if="props.isEditable">
        <button 
          type="submit" 
          :disabled="!isFormValid || isLoading"
          class="btn btn-primary"
        >
          {{ isLoading ? '保存中...' : '保存' }}
        </button>
        
        <button 
          type="button" 
          @click="handleDelete"
          class="btn btn-danger"
        >
          削除
        </button>
      </div>
    </form>
  </div>
</template>
```

### 5.1.2 Composablesの作成
```typescript
// composables/useApi.ts
import { ref, type Ref } from 'vue'

export interface ApiState<T> {
  data: Ref<T | null>
  loading: Ref<boolean>
  error: Ref<string | null>
}

export function useApi<T>() {
  const data = ref<T | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const execute = async (apiCall: () => Promise<T>): Promise<void> => {
    loading.value = true
    error.value = null
    
    try {
      data.value = await apiCall()
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Unknown error'
    } finally {
      loading.value = false
    }
  }

  const reset = (): void => {
    data.value = null
    error.value = null
    loading.value = false
  }

  return {
    data: readonly(data),
    loading: readonly(loading),
    error: readonly(error),
    execute,
    reset
  }
}

// 使用例
const { data: users, loading, error, execute } = useApi<User[]>()

onMounted(async () => {
  await execute(() => fetchUsers())
})
```

## 5.2 コンポーネント設計

### 5.2.1 単一責任の原則
```vue
<!-- Good: 単一責任を持つコンポーネント -->
<!-- components/UserCard.vue -->
<script setup lang="ts">
interface Props {
  user: User
  showActions?: boolean
}
const props = withDefaults(defineProps<Props>(), {
  showActions: true
})

interface Emits {
  edit: [user: User]
  delete: [userId: number]
}
const emit = defineEmits<Emits>()
</script>

<template>
  <div class="user-card">
    <!-- ユーザー情報表示のみに集中 -->
    <div class="user-info">
      <img :src="user.avatar" :alt="user.name" class="avatar">
      <div class="details">
        <h3>{{ user.name }}</h3>
        <p>{{ user.email }}</p>
      </div>
    </div>
    
    <div v-if="showActions" class="actions">
      <button @click="emit('edit', user)" class="btn btn-sm">編集</button>
      <button @click="emit('delete', user.id)" class="btn btn-sm btn-danger">削除</button>
    </div>
  </div>
</template>

<!-- Bad: 複数の責任を持つコンポーネント -->
<!-- ユーザー表示 + フォーム + リスト管理を一つのコンポーネントで処理するのは避ける -->
```

### 5.2.2 Props・Emits定義
```typescript
// types/index.ts - 型定義の中央集権
export interface User {
  id: number
  name: string
  email: string
  avatar?: string
  role: 'admin' | 'user' | 'guest'
  createdAt: string
}

export interface PaginationMeta {
  currentPage: number
  lastPage: number
  perPage: number
  total: number
}

export interface ApiResponse<T> {
  data: T
  meta?: PaginationMeta
  message?: string
}

// components/UserList.vue
<script setup lang="ts">
import type { User, PaginationMeta } from '@/types'

// Propsの型定義
interface Props {
  users: User[]
  meta?: PaginationMeta
  loading?: boolean
  selectable?: boolean
  selectedUsers?: number[]
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  selectable: false,
  selectedUsers: () => []
})

// Emitsの型定義
interface Emits {
  'user:select': [userId: number]
  'user:deselect': [userId: number]
  'users:bulk-delete': [userIds: number[]]
  'pagination:change': [page: number]
}

const emit = defineEmits<Emits>()

// Computed
const selectedUserIds = computed(() => new Set(props.selectedUsers))

const allSelected = computed(() => {
  return props.users.length > 0 && 
         props.users.every(user => selectedUserIds.value.has(user.id))
})

// Methods
const toggleUserSelection = (user: User) => {
  if (selectedUserIds.value.has(user.id)) {
    emit('user:deselect', user.id)
  } else {
    emit('user:select', user.id)
  }
}

const toggleAllSelection = () => {
  if (allSelected.value) {
    props.users.forEach(user => emit('user:deselect', user.id))
  } else {
    props.users.forEach(user => emit('user:select', user.id))
  }
}
</script>
```

## 5.3 状態管理

### 5.3.1 Pinia Store
```typescript
// stores/auth.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('auth_token'))
  const isLoading = ref(false)

  // Getters
  const isAuthenticated = computed(() => !!user.value && !!token.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const userName = computed(() => user.value?.name || 'Guest')

  // Actions
  const login = async (credentials: LoginCredentials): Promise<void> => {
    isLoading.value = true
    try {
      const response = await authApi.login(credentials)
      
      user.value = response.user
      token.value = response.token
      
      localStorage.setItem('auth_token', response.token)
      
      // ローターへのリダイレクトはコンポーネント側で処理
    } catch (error) {
      throw new Error('ログインに失敗しました')
    } finally {
      isLoading.value = false
    }
  }

  const logout = async (): Promise<void> => {
    try {
      if (token.value) {
        await authApi.logout()
      }
    } finally {
      user.value = null
      token.value = null
      localStorage.removeItem('auth_token')
    }
  }

  const fetchUser = async (): Promise<void> => {
    if (!token.value) return
    
    try {
      user.value = await authApi.getUser()
    } catch (error) {
      // トークンが無効な場合はログアウト
      await logout()
      throw error
    }
  }

  const updateUser = async (userData: Partial<User>): Promise<void> => {
    if (!user.value) throw new Error('User not authenticated')
    
    const updatedUser = await authApi.updateUser(user.value.id, userData)
    user.value = { ...user.value, ...updatedUser }
  }

  return {
    // State
    user: readonly(user),
    token: readonly(token),
    isLoading: readonly(isLoading),
    
    // Getters
    isAuthenticated,
    isAdmin,
    userName,
    
    // Actions
    login,
    logout,
    fetchUser,
    updateUser
  }
})

// stores/posts.ts
export const usePostsStore = defineStore('posts', () => {
  const posts = ref<Post[]>([])
  const currentPost = ref<Post | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const publishedPosts = computed(() => 
    posts.value.filter(post => post.status === 'published')
  )

  const getPostBySlug = computed(() => 
    (slug: string) => posts.value.find(post => post.slug === slug)
  )

  const fetchPosts = async (params?: PostSearchParams): Promise<void> => {
    isLoading.value = true
    error.value = null
    
    try {
      posts.value = await postsApi.getPosts(params)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch posts'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const createPost = async (postData: CreatePostData): Promise<Post> => {
    const newPost = await postsApi.createPost(postData)
    posts.value.unshift(newPost)
    return newPost
  }

  return {
    posts: readonly(posts),
    currentPost: readonly(currentPost),
    isLoading: readonly(isLoading),
    error: readonly(error),
    publishedPosts,
    getPostBySlug,
    fetchPosts,
    createPost
  }
})
```

### 5.3.2 ローカル状態 vs グローバル状態
```vue
<script setup lang="ts">
// ローカル状態: コンポーネント固有の一時的な状態
const isModalOpen = ref(false) // UI状態
const formData = reactive({     // フォームの一時的な状態
  name: '',
  email: ''
})
const isSubmitting = ref(false) // 処理状態

// グローバル状態: 複数コンポーネントで共有する状態
const authStore = useAuthStore() // ユーザー情報
const postsStore = usePostsStore() // 投稿データ

// コンポーネント間でデータを共有する必要がない場合はローカル状態を使用
const searchQuery = ref('') // 検索クエリはそのコンポーネント内で完結

// provide/injectで局所的な状態共有
const selectedItems = ref<number[]>([])
provide('selectedItems', {
  items: readonly(selectedItems),
  select: (id: number) => {
    if (!selectedItems.value.includes(id)) {
      selectedItems.value.push(id)
    }
  },
  deselect: (id: number) => {
    const index = selectedItems.value.indexOf(id)
    if (index > -1) {
      selectedItems.value.splice(index, 1)
    }
  }
})
</script>
```

## 5.4 ライフサイクル管理

### 5.4.1 ライフサイクルフックの使い分け
```vue
<script setup lang="ts">
import { 
  onMounted, 
  onUnmounted, 
  onBeforeMount,
  onBeforeUnmount,
  onUpdated,
  onActivated,
  onDeactivated
} from 'vue'

// コンポーネントの初期化
onBeforeMount(() => {
  console.log('コンポーネントがマウントされる前')
})

onMounted(async () => {
  console.log('コンポーネントがマウントされた後')
  
  // APIコール
  await fetchInitialData()
  
  // イベントリスナーの設定
  window.addEventListener('resize', handleResize)
  
  // タイマーの設定
  const timer = setInterval(updateTimer, 1000)
  
  // cleanup関数を返す
  onBeforeUnmount(() => {
    clearInterval(timer)
  })
})

// コンポーネントのクリーンアップ
onBeforeUnmount(() => {
  console.log('コンポーネントがアンマウントされる前')
  
  // イベントリスナーの除去
  window.removeEventListener('resize', handleResize)
  
  // WebSocketのクローズ
  if (websocket.value) {
    websocket.value.close()
  }
})

onUnmounted(() => {
  console.log('コンポーネントがアンマウントされた後')
})

// keep-aliveコンポーネント用
onActivated(() => {
  console.log('コンポーネントがアクティブになった')
  // キャッシュされたコンポーネントが再表示された時
})

onDeactivated(() => {
  console.log('コンポーネントが非アクティブになった')
  // keep-aliveでキャッシュされる時
})

// 更新時の処理
onUpdated(() => {
  console.log('コンポーネントが更新された')
  // DOMの更新後の処理（使用は最小限に）
})
</script>
```

### 5.4.2 メモリリーク対策
```vue
<script setup lang="ts">
// イベントリスナーの適切な解除
const handleScroll = () => {
  // スクロール処理
}

const handleResize = () => {
  // リサイズ処理
}

onMounted(() => {
  document.addEventListener('scroll', handleScroll)
  window.addEventListener('resize', handleResize)
})

onBeforeUnmount(() => {
  // 必ずイベントリスナーを解除
  document.removeEventListener('scroll', handleScroll)
  window.removeEventListener('resize', handleResize)
})

// タイマーやインターバルの清理
const timer = ref<NodeJS.Timeout | null>(null)
const interval = ref<NodeJS.Timeout | null>(null)

const startTimer = () => {
  timer.value = setTimeout(() => {
    // タイマー処理
  }, 5000)
  
  interval.value = setInterval(() => {
    // 定期処理
  }, 1000)
}

onBeforeUnmount(() => {
  if (timer.value) {
    clearTimeout(timer.value)
  }
  if (interval.value) {
    clearInterval(interval.value)
  }
})

// Promiseやasync処理の適切なキャンセル
const abortController = ref<AbortController | null>(null)

const fetchData = async () => {
  // 前のリクエストをキャンセル
  if (abortController.value) {
    abortController.value.abort()
  }
  
  abortController.value = new AbortController()
  
  try {
    const response = await fetch('/api/data', {
      signal: abortController.value.signal
    })
    // レスポンス処理
  } catch (error) {
    if (error.name !== 'AbortError') {
      // エラー処理
    }
  }
}

onBeforeUnmount(() => {
  // 未完了のリクエストをキャンセル
  if (abortController.value) {
    abortController.value.abort()
  }
})
</script>
```

## 5.5 テスト

### 5.5.1 Vitest使用
```typescript
// tests/components/UserCard.test.ts
import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import UserCard from '@/components/UserCard.vue'
import type { User } from '@/types'

const mockUser: User = {
  id: 1,
  name: 'Test User',
  email: 'test@example.com',
  avatar: 'https://example.com/avatar.jpg',
  role: 'user',
  createdAt: '2023-01-01T00:00:00Z'
}

describe('UserCard', () => {
  it('renders user information correctly', () => {
    const wrapper = mount(UserCard, {
      props: {
        user: mockUser
      }
    })

    expect(wrapper.find('h3').text()).toBe(mockUser.name)
    expect(wrapper.find('p').text()).toBe(mockUser.email)
    expect(wrapper.find('img').attributes('src')).toBe(mockUser.avatar)
    expect(wrapper.find('img').attributes('alt')).toBe(mockUser.name)
  })

  it('emits edit event when edit button is clicked', async () => {
    const wrapper = mount(UserCard, {
      props: {
        user: mockUser,
        showActions: true
      }
    })

    const editButton = wrapper.find('button:first-child')
    await editButton.trigger('click')

    expect(wrapper.emitted('edit')).toBeTruthy()
    expect(wrapper.emitted('edit')?.[0]).toEqual([mockUser])
  })

  it('emits delete event when delete button is clicked', async () => {
    const wrapper = mount(UserCard, {
      props: {
        user: mockUser,
        showActions: true
      }
    })

    const deleteButton = wrapper.find('.btn-danger')
    await deleteButton.trigger('click')

    expect(wrapper.emitted('delete')).toBeTruthy()
    expect(wrapper.emitted('delete')?.[0]).toEqual([mockUser.id])
  })

  it('hides action buttons when showActions is false', () => {
    const wrapper = mount(UserCard, {
      props: {
        user: mockUser,
        showActions: false
      }
    })

    expect(wrapper.find('.actions').exists()).toBe(false)
  })
})
```

### 5.5.2 コンポーネントテスト
```typescript
// tests/components/UserForm.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import UserForm from '@/components/UserForm.vue'

// グローバルコンポーネントのモック
const mockComponents = {
  'router-link': {
    template: '<a><slot /></a>'
  }
}

// APIモック
const mockUpdateUser = vi.fn()
vi.mock('@/api/users', () => ({
  updateUser: mockUpdateUser
}))

describe('UserForm', () => {
  const mockUser = {
    id: 1,
    name: 'Test User',
    email: 'test@example.com'
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('initializes form with user data', () => {
    const wrapper = mount(UserForm, {
      props: { user: mockUser, isEditable: true },
      global: {
        components: mockComponents
      }
    })

    const nameInput = wrapper.find('#name')
    const emailInput = wrapper.find('#email')

    expect((nameInput.element as HTMLInputElement).value).toBe(mockUser.name)
    expect((emailInput.element as HTMLInputElement).value).toBe(mockUser.email)
  })

  it('validates form before submission', async () => {
    const wrapper = mount(UserForm, {
      props: { user: mockUser, isEditable: true },
      global: {
        components: mockComponents
      }
    })

    // 名前を空にする
    const nameInput = wrapper.find('#name')
    await nameInput.setValue('')
    await nextTick()

    const submitButton = wrapper.find('button[type="submit"]')
    expect(submitButton.attributes('disabled')).toBeDefined()
  })

  it('submits form with valid data', async () => {
    mockUpdateUser.mockResolvedValue({ ...mockUser, name: 'Updated Name' })

    const wrapper = mount(UserForm, {
      props: { user: mockUser, isEditable: true },
      global: {
        components: mockComponents
      }
    })

    // フォームを変更
    const nameInput = wrapper.find('#name')
    await nameInput.setValue('Updated Name')

    // フォームを送信
    const form = wrapper.find('form')
    await form.trigger('submit')
    await nextTick()

    expect(mockUpdateUser).toHaveBeenCalledWith({
      ...mockUser,
      name: 'Updated Name'
    })
    expect(wrapper.emitted('update')).toBeTruthy()
  })

  it('handles API errors gracefully', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    mockUpdateUser.mockRejectedValue(new Error('API Error'))

    const wrapper = mount(UserForm, {
      props: { user: mockUser, isEditable: true },
      global: {
        components: mockComponents
      }
    })

    const form = wrapper.find('form')
    await form.trigger('submit')
    await nextTick()

    expect(consoleErrorSpy).toHaveBeenCalledWith('Update failed:', expect.any(Error))
    expect(wrapper.emitted('update')).toBeFalsy()
    
    consoleErrorSpy.mockRestore()
  })
})

// ストアのテスト
// tests/stores/auth.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'

// APIモック
const mockAuthApi = {
  login: vi.fn(),
  logout: vi.fn(),
  getUser: vi.fn()
}

vi.mock('@/api/auth', () => mockAuthApi)

describe('Auth Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('initializes with correct default state', () => {
    const store = useAuthStore()
    
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
    expect(store.isAdmin).toBe(false)
  })

  it('logs in user successfully', async () => {
    const mockResponse = {
      user: { id: 1, name: 'Test User', role: 'user' },
      token: 'mock-token'
    }
    mockAuthApi.login.mockResolvedValue(mockResponse)

    const store = useAuthStore()
    await store.login({ email: 'test@example.com', password: 'password' })

    expect(store.user).toEqual(mockResponse.user)
    expect(store.token).toBe(mockResponse.token)
    expect(store.isAuthenticated).toBe(true)
    expect(localStorage.getItem('auth_token')).toBe(mockResponse.token)
  })

  it('handles login failure', async () => {
    mockAuthApi.login.mockRejectedValue(new Error('Invalid credentials'))

    const store = useAuthStore()
    
    await expect(store.login({ 
      email: 'test@example.com', 
      password: 'wrong-password' 
    })).rejects.toThrow('ログインに失敗しました')

    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })
})
```