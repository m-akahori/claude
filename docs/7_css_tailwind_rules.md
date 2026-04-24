# 6. CSS/Tailwind CSS コーディングルール

## 6.1 Tailwind CSS v3使用

### 6.1.1 基本方針
- **ユーティリティファースト**: カスタムCSSより Tailwind のユーティリティクラスを優先
- **レスポンシブデザイン**: モバイルファーストアプローチ
- **コンポーネント指向**: 繰り返し使用するパターンはコンポーネント化
- **パフォーマンス重視**: 未使用のスタイルを自動除去（PurgeCSS）

### 6.1.2 設定ファイル
```javascript
// tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*.blade.php',
    './storage/framework/views/*.php',
    './resources/views/**/*.blade.php',
    './resources/js/**/*.vue',
    './resources/js/**/*.ts',
  ],
  
  darkMode: 'class', // ダークモード対応
  
  theme: {
    extend: {
      colors: {
        // カスタムカラーパレット
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        secondary: {
          50: '#f8fafc',
          500: '#64748b',
          900: '#0f172a',
        },
        success: '#10b981',
        warning: '#f59e0b',
        error: '#ef4444',
      },
      
      fontFamily: {
        sans: ['Figtree', ...defaultTheme.fontFamily.sans],
        ja: ['Noto Sans JP', 'sans-serif'],
      },
      
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
      
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

## 6.2 ユーティリティクラス活用

### 6.2.1 レイアウト
```html
<!-- Flexbox レイアウト -->
<div class="flex items-center justify-between p-4">
  <h1 class="text-2xl font-bold text-gray-900">タイトル</h1>
  <button class="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600">
    ボタン
  </button>
</div>

<!-- Grid レイアウト -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <div class="bg-white p-6 rounded-lg shadow-sm border">
    カード1
  </div>
  <div class="bg-white p-6 rounded-lg shadow-sm border">
    カード2
  </div>
  <div class="bg-white p-6 rounded-lg shadow-sm border">
    カード3
  </div>
</div>

<!-- Responsive デザイン -->
<div class="w-full sm:w-1/2 lg:w-1/3 xl:w-1/4">
  <img 
    src="image.jpg" 
    alt="画像" 
    class="w-full h-48 object-cover rounded-lg"
  >
</div>
```

### 6.2.2 スペーシング戦略
```html
<!-- Good: gap ユーティリティで統一 -->
<div class="flex gap-4">
  <div>アイテム1</div>
  <div>アイテム2</div>
  <div>アイテム3</div>
</div>

<div class="grid grid-cols-3 gap-6">
  <div>グリッド1</div>
  <div>グリッド2</div>
  <div>グリッド3</div>
</div>

<!-- Bad: margin で個別調整 -->
<div class="flex">
  <div class="mr-4">アイテム1</div>
  <div class="mr-4">アイテム2</div>
  <div>アイテム3</div>
</div>

<!-- スペーシングスケール（推奨値） -->
<!-- gap-1 (4px) - 非常に狭い -->
<!-- gap-2 (8px) - 狭い -->
<!-- gap-4 (16px) - 標準 -->
<!-- gap-6 (24px) - 広い -->
<!-- gap-8 (32px) - 非常に広い -->
```

### 6.2.3 カラーシステム
```html
<!-- プライマリカラー -->
<button class="bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700">
  プライマリボタン
</button>

<!-- セマンティックカラー -->
<div class="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded">
  ✓ 成功メッセージ
</div>

<div class="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded">
  ✗ エラーメッセージ
</div>

<div class="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded">
  ⚠ 警告メッセージ
</div>

<!-- グレースケール -->
<p class="text-gray-900">メインテキスト</p>
<p class="text-gray-600">サブテキスト</p>
<p class="text-gray-400">キャプション</p>
```

## 6.3 カスタムコンポーネント

### 6.3.1 @layer ディレクティブ
```css
/* resources/css/app.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  /* ベースレイヤー: HTML要素のリセット・デフォルトスタイル */
  html {
    @apply antialiased;
  }
  
  body {
    @apply bg-gray-50 text-gray-900 font-sans;
  }
  
  h1, h2, h3, h4, h5, h6 {
    @apply font-bold leading-tight;
  }
  
  a {
    @apply text-primary-600 hover:text-primary-700 transition-colors;
  }
}

@layer components {
  /* コンポーネントレイヤー: 再利用可能なコンポーネント */
  .btn {
    @apply px-4 py-2 rounded-md font-medium text-sm transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2;
  }
  
  .btn-primary {
    @apply bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700 focus:ring-primary-500;
  }
  
  .btn-secondary {
    @apply bg-gray-500 text-white hover:bg-gray-600 active:bg-gray-700 focus:ring-gray-500;
  }
  
  .btn-outline {
    @apply border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-primary-500;
  }
  
  .btn-danger {
    @apply bg-red-500 text-white hover:bg-red-600 active:bg-red-700 focus:ring-red-500;
  }
  
  .btn-sm {
    @apply px-3 py-1.5 text-xs;
  }
  
  .btn-lg {
    @apply px-6 py-3 text-base;
  }
  
  .card {
    @apply bg-white rounded-lg border border-gray-200 shadow-sm;
  }
  
  .card-header {
    @apply px-6 py-4 border-b border-gray-200;
  }
  
  .card-body {
    @apply px-6 py-4;
  }
  
  .card-footer {
    @apply px-6 py-4 border-t border-gray-200 bg-gray-50;
  }
  
  .form-input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-primary-500 focus:border-primary-500;
  }
  
  .form-label {
    @apply block text-sm font-medium text-gray-700 mb-2;
  }
  
  .form-error {
    @apply mt-1 text-sm text-red-600;
  }
}

@layer utilities {
  /* ユーティリティレイヤー: 単発のスタイル調整 */
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
  
  .text-shadow {
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }
}
```

### 6.3.2 Vue コンポーネントでの使用
```vue
<template>
  <!-- カスタムコンポーネントクラスの使用 -->
  <div class="card">
    <div class="card-header">
      <h2 class="text-lg font-semibold">ユーザー情報</h2>
    </div>
    
    <div class="card-body">
      <form @submit.prevent="handleSubmit" class="space-y-4">
        <div>
          <label for="name" class="form-label">名前</label>
          <input 
            id="name"
            v-model="form.name"
            type="text" 
            class="form-input"
            :class="{ 'border-red-500': errors.name }"
          >
          <p v-if="errors.name" class="form-error">{{ errors.name }}</p>
        </div>
        
        <div>
          <label for="email" class="form-label">メールアドレス</label>
          <input 
            id="email"
            v-model="form.email"
            type="email" 
            class="form-input"
            :class="{ 'border-red-500': errors.email }"
          >
          <p v-if="errors.email" class="form-error">{{ errors.email }}</p>
        </div>
      </form>
    </div>
    
    <div class="card-footer">
      <div class="flex justify-end gap-3">
        <button type="button" class="btn btn-outline">
          キャンセル
        </button>
        <button 
          type="submit" 
          class="btn btn-primary"
          :disabled="isSubmitting"
        >
          {{ isSubmitting ? '保存中...' : '保存' }}
        </button>
      </div>
    </div>
  </div>
</template>
```

## 6.4 Flowbite UI コンポーネント使用

### 6.4.1 Flowbite 導入
```javascript
// package.json
{
  "devDependencies": {
    "flowbite": "^1.8.1"
  }
}

// tailwind.config.js
module.exports = {
  content: [
    // ...
    "./node_modules/flowbite/**/*.js"
  ],
  plugins: [
    require('flowbite/plugin')
  ]
}

// resources/js/app.js
import { initFlowbite } from 'flowbite'

// DOM読み込み後にFlowbiteを初期化
document.addEventListener('DOMContentLoaded', () => {
  initFlowbite()
})
```

### 6.4.2 Flowbite コンポーネント例
```vue
<template>
  <!-- Modal -->
  <div 
    id="default-modal" 
    tabindex="-1" 
    aria-hidden="true" 
    class="hidden overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 justify-center items-center w-full md:inset-0 h-[calc(100%-1rem)] max-h-full"
  >
    <div class="relative p-4 w-full max-w-2xl max-h-full">
      <div class="relative bg-white rounded-lg shadow dark:bg-gray-700">
        <!-- Modal header -->
        <div class="flex items-center justify-between p-4 md:p-5 border-b rounded-t dark:border-gray-600">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white">
            モーダルタイトル
          </h3>
          <button 
            type="button" 
            class="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm w-8 h-8 ms-auto inline-flex justify-center items-center dark:hover:bg-gray-600 dark:hover:text-white" 
            data-modal-hide="default-modal"
          >
            <svg class="w-3 h-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
              <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
            </svg>
            <span class="sr-only">モーダルを閉じる</span>
          </button>
        </div>
        
        <!-- Modal body -->
        <div class="p-4 md:p-5 space-y-4">
          <p class="text-base leading-relaxed text-gray-500 dark:text-gray-400">
            モーダルの内容をここに記載します。
          </p>
        </div>
        
        <!-- Modal footer -->
        <div class="flex items-center p-4 md:p-5 border-t border-gray-200 rounded-b dark:border-gray-600">
          <button 
            data-modal-hide="default-modal" 
            type="button" 
            class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
          >
            確定
          </button>
          <button 
            data-modal-hide="default-modal" 
            type="button" 
            class="ms-3 text-gray-500 bg-white hover:bg-gray-100 focus:ring-4 focus:outline-none focus:ring-blue-300 rounded-lg border border-gray-200 text-sm font-medium px-5 py-2.5 hover:text-gray-900 focus:z-10 dark:bg-gray-700 dark:text-gray-300 dark:border-gray-500 dark:hover:text-white dark:hover:bg-gray-600 dark:focus:ring-gray-600"
          >
            キャンセル
          </button>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Dropdown -->
  <div class="relative inline-block text-left">
    <button 
      id="dropdownDefaultButton" 
      data-dropdown-toggle="dropdown" 
      class="text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center inline-flex items-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800" 
      type="button"
    >
      ドロップダウン
      <svg class="w-2.5 h-2.5 ms-3" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
        <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 4 4 4-4"/>
      </svg>
    </button>
    
    <div id="dropdown" class="z-10 hidden bg-white divide-y divide-gray-100 rounded-lg shadow w-44 dark:bg-gray-700">
      <ul class="py-2 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownDefaultButton">
        <li>
          <a href="#" class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">ダッシュボード</a>
        </li>
        <li>
          <a href="#" class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">設定</a>
        </li>
        <li>
          <a href="#" class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">ヘルプ</a>
        </li>
        <li>
          <a href="#" class="block px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-white">ログアウト</a>
        </li>
      </ul>
    </div>
  </div>
</template>
```

## 6.5 レスポンシブデザイン

### 6.5.1 ブレークポイント戦略
```html
<!-- モバイルファーストアプローチ -->
<div class="
  w-full          /* モバイル: 全幅 */
  sm:w-1/2        /* 640px以上: 半分 */
  md:w-1/3        /* 768px以上: 1/3 */
  lg:w-1/4        /* 1024px以上: 1/4 */
  xl:w-1/5        /* 1280px以上: 1/5 */
  2xl:w-1/6       /* 1536px以上: 1/6 */
">
  レスポンシブコンテンツ
</div>

<!-- グリッドレイアウト -->
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
  <div class="bg-white p-4 rounded-lg shadow">アイテム1</div>
  <div class="bg-white p-4 rounded-lg shadow">アイテム2</div>
  <div class="bg-white p-4 rounded-lg shadow">アイテム3</div>
  <div class="bg-white p-4 rounded-lg shadow">アイテム4</div>
</div>

<!-- フォントサイズ -->
<h1 class="text-2xl sm:text-3xl lg:text-4xl xl:text-5xl font-bold">
  レスポンシブタイトル
</h1>

<!-- スペーシング -->
<div class="p-4 sm:p-6 lg:p-8 xl:p-12">
  <div class="space-y-4 sm:space-y-6 lg:space-y-8">
    <p>段落1</p>
    <p>段落2</p>
  </div>
</div>

<!-- 表示・非表示 -->
<nav class="">
  <!-- モバイルメニューボタン -->
  <button class="lg:hidden p-2">
    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
    </svg>
  </button>
  
  <!-- デスクトップメニュー -->
  <div class="hidden lg:flex lg:items-center lg:space-x-6">
    <a href="#" class="text-gray-700 hover:text-gray-900">ホーム</a>
    <a href="#" class="text-gray-700 hover:text-gray-900">製品</a>
    <a href="#" class="text-gray-700 hover:text-gray-900">サービス</a>
    <a href="#" class="text-gray-700 hover:text-gray-900">お問い合わせ</a>
  </div>
</nav>
```

## 6.6 ダークモード対応

### 6.6.1 ダークモード実装
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'

const isDarkMode = ref(false)

const toggleDarkMode = () => {
  isDarkMode.value = !isDarkMode.value
  updateDarkMode()
}

const updateDarkMode = () => {
  if (isDarkMode.value) {
    document.documentElement.classList.add('dark')
    localStorage.setItem('darkMode', 'true')
  } else {
    document.documentElement.classList.remove('dark')
    localStorage.setItem('darkMode', 'false')
  }
}

onMounted(() => {
  // ローカルストレージから設定を読み込み
  const savedMode = localStorage.getItem('darkMode')
  if (savedMode !== null) {
    isDarkMode.value = savedMode === 'true'
  } else {
    // システム設定を確認
    isDarkMode.value = window.matchMedia('(prefers-color-scheme: dark)').matches
  }
  updateDarkMode()
})
</script>

<template>
  <div class="min-h-screen bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
    <!-- ダークモード切り替えボタン -->
    <button 
      @click="toggleDarkMode"
      class="fixed top-4 right-4 p-2 rounded-full bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
    >
      <!-- ライトモードアイコン -->
      <svg 
        v-if="isDarkMode" 
        class="w-5 h-5" 
        fill="currentColor" 
        viewBox="0 0 20 20"
      >
        <path 
          fill-rule="evenodd" 
          d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" 
          clip-rule="evenodd" 
        />
      </svg>
      
      <!-- ダークモードアイコン -->
      <svg 
        v-else 
        class="w-5 h-5" 
        fill="currentColor" 
        viewBox="0 0 20 20"
      >
        <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
      </svg>
    </button>
    
    <!-- メインコンテンツ -->
    <main class="container mx-auto px-4 py-8">
      <!-- カード -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          ダークモード対応カード
        </h2>
        <p class="text-gray-600 dark:text-gray-300 mb-6">
          このカードはライトモードとダークモードの両方に対応しています。
        </p>
        
        <!-- ボタン -->
        <div class="flex gap-3">
          <button class="btn btn-primary">
            プライマリボタン
          </button>
          <button class="bg-gray-500 dark:bg-gray-600 text-white hover:bg-gray-600 dark:hover:bg-gray-700 px-4 py-2 rounded-md transition-colors">
            セカンダリボタン
          </button>
        </div>
      </div>
      
      <!-- フォーム -->
      <form class="mt-8 bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">フォーム例</h3>
        
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              名前
            </label>
            <input 
              type="text" 
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              placeholder="名前を入力"
            >
          </div>
          
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              メールアドレス
            </label>
            <input 
              type="email" 
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
              placeholder="email@example.com"
            >
          </div>
        </div>
      </form>
    </main>
  </div>
</template>

<style>
/* カスタムコンポーネントでのダークモード対応 */
.btn-primary {
  @apply bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700;
  @apply dark:bg-primary-600 dark:hover:bg-primary-700 dark:active:bg-primary-800;
}
</style>
```

### 6.6.2 ダークモード用カラー戦略
```css
/* ダークモード用のカラー定義例 */
:root {
  --color-background: #ffffff;
  --color-foreground: #000000;
  --color-card: #ffffff;
  --color-card-foreground: #000000;
  --color-primary: #3b82f6;
  --color-muted: #f1f5f9;
  --color-muted-foreground: #64748b;
  --color-border: #e2e8f0;
}

.dark {
  --color-background: #0f172a;
  --color-foreground: #f8fafc;
  --color-card: #1e293b;
  --color-card-foreground: #f8fafc;
  --color-primary: #3b82f6;
  --color-muted: #1e293b;
  --color-muted-foreground: #94a3b8;
  --color-border: #334155;
}

/* 使用例 */
.custom-card {
  background-color: var(--color-card);
  color: var(--color-card-foreground);
  border-color: var(--color-border);
}
```