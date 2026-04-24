# 12. 開発ツール・品質管理

## 12.1 Laravel Pint（コード整形）

### 12.1.1 基本設定

```json
// pint.json
{
    "preset": "laravel",
    "rules": {
        "simplified_null_return": true,
        "not_operator_with_successor_space": true,
        "ordered_imports": {
            "sort_algorithm": "alpha",
            "imports_order": [
                "const",
                "class",
                "function"
            ]
        },
        "phpdoc_align": {
            "align": "vertical"
        },
        "array_syntax": {
            "syntax": "short"
        },
        "binary_operator_spaces": {
            "default": "single_space"
        },
        "blank_line_after_opening_tag": true,
        "braces": {
            "allow_single_line_closure": true,
            "position_after_functions_and_oop_constructs": "next",
            "position_after_control_structures": "same"
        },
        "cast_spaces": true,
        "class_attributes_separation": {
            "elements": {
                "method": "one"
            }
        },
        "concat_space": {
            "spacing": "one"
        },
        "declare_equal_normalize": true,
        "function_typehint_space": true,
        "hash_to_slash_comment": true,
        "include": true,
        "increment_style": true,
        "lowercase_cast": true,
        "magic_constant_casing": true,
        "method_argument_space": true,
        "native_function_casing": true,
        "no_alias_functions": true,
        "no_extra_blank_lines": {
            "tokens": [
                "extra",
                "throw",
                "use",
                "use_trait"
            ]
        },
        "no_blank_lines_after_class_opening": true,
        "no_blank_lines_after_phpdoc": true,
        "no_closing_tag": true,
        "no_empty_phpdoc": true,
        "no_empty_statement": true,
        "no_leading_import_slash": true,
        "no_leading_namespace_whitespace": true,
        "no_mixed_echo_print": {
            "use": "echo"
        },
        "no_multiline_whitespace_around_double_arrow": true,
        "no_short_bool_cast": true,
        "no_singleline_whitespace_before_semicolons": true,
        "no_spaces_around_offset": {
            "positions": ["inside", "outside"]
        },
        "no_trailing_comma_in_list_call": true,
        "no_trailing_comma_in_singleline_array": true,
        "no_unneeded_control_parentheses": true,
        "no_unused_imports": true,
        "no_whitespace_before_comma_in_array": true,
        "no_whitespace_in_blank_line": true,
        "normalize_index_brace": true,
        "object_operator_without_whitespace": true,
        "php_unit_fqcn_annotation": true,
        "phpdoc_indent": true,
        "phpdoc_inline_tag": true,
        "phpdoc_no_access": true,
        "phpdoc_no_alias_tag": true,
        "phpdoc_no_empty_return": true,
        "phpdoc_no_package": true,
        "phpdoc_no_useless_inheritdoc": true,
        "phpdoc_return_self_reference": true,
        "phpdoc_scalar": true,
        "phpdoc_separation": true,
        "phpdoc_single_line_var_spacing": true,
        "phpdoc_summary": true,
        "phpdoc_to_comment": true,
        "phpdoc_trim": true,
        "phpdoc_types": true,
        "phpdoc_var_without_name": true,
        "return_type_declaration": true,
        "self_accessor": true,
        "short_scalar_cast": true,
        "single_blank_line_before_namespace": true,
        "single_class_element_per_statement": {
            "elements": ["property"]
        },
        "single_line_comment_style": {
            "comment_types": ["hash"]
        },
        "single_quote": true,
        "space_after_semicolon": {
            "remove_in_empty_for_expressions": true
        },
        "standardize_not_equals": true,
        "ternary_operator_spaces": true,
        "trailing_comma_in_multiline_array": true,
        "trim_array_spaces": true,
        "unary_operator_spaces": true,
        "whitespace_after_comma_in_array": true
    },
    "exclude": [
        "node_modules",
        "storage",
        "vendor"
    ]
}
```

### 12.1.2 実行方法

```bash
# 全ファイルをフォーマット
vendor/bin/pint

# 特定のファイルをフォーマット
vendor/bin/pint app/Models/User.php

# 特定のディレクトリをフォーマット
vendor/bin/pint app/Services

# ドライランモード（変更せずにチェックのみ）
vendor/bin/pint --test

# 変更されたファイルのみフォーマット
vendor/bin/pint --dirty

# 詳細出力
vendor/bin/pint -v

# 設定ファイルを指定
vendor/bin/pint --config=pint.json

# CI/CDで使用する場合
vendor/bin/pint --test --bail
```

### 12.1.3 Git Hooks との統合

```bash
#!/bin/sh
# .git/hooks/pre-commit

# ステージされたPHPファイルを取得
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.php$')

if [ -n "$STAGED_FILES" ]; then
    echo "Running Laravel Pint on staged files..."
    
    # Pintを実行
    vendor/bin/pint --test $STAGED_FILES
    
    if [ $? -ne 0 ]; then
        echo "❌ Laravel Pint found formatting issues."
        echo "Please run 'vendor/bin/pint' to fix them and commit again."
        exit 1
    fi
    
    echo "✅ Code formatting check passed."
fi

exit 0
```

## 12.2 PHPUnit（テスト）

### 12.2.1 設定ファイル

```xml
<!-- phpunit.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="./vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         processIsolation="false"
         stopOnFailure="false"
         cacheDirectory=".phpunit.cache"
         backupGlobals="false"
         backupStaticAttributes="false">
    <testsuites>
        <testsuite name="Unit">
            <directory suffix="Test.php">./tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory suffix="Test.php">./tests/Feature</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory suffix="Test.php">./tests/Integration</directory>
        </testsuite>
    </testsuites>
    
    <coverage>
        <include>
            <directory suffix=".php">./app</directory>
        </include>
        <exclude>
            <directory suffix=".php">./app/Console/Kernel.php</directory>
            <directory suffix=".php">./app/Exceptions/Handler.php</directory>
            <directory suffix=".php">./app/Http/Middleware</directory>
        </exclude>
        <report>
            <html outputDirectory="coverage-report" lowUpperBound="50" highLowerBound="85"/>
            <text outputFile="coverage.txt" showUncoveredFiles="false"/>
            <clover outputFile="coverage.xml"/>
        </report>
    </coverage>
    
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="CACHE_DRIVER" value="array"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
    </php>
    
    <groups>
        <exclude>
            <group>slow</group>
            <group>external</group>
        </exclude>
    </groups>
</phpunit>
```

### 12.2.2 テスト実行コマンド

```bash
# 全テスト実行
php artisan test

# 特定のテストスイート実行
php artisan test --testsuite=Unit
php artisan test --testsuite=Feature

# 特定のテストファイル実行
php artisan test tests/Feature/UserTest.php

# 特定のテストメソッド実行
php artisan test --filter=test_user_can_login

# カバレッジ付きで実行
php artisan test --coverage
php artisan test --coverage-html coverage-report
php artisan test --coverage-clover coverage.xml

# 並列実行
php artisan test --parallel

# 失敗時に停止
php artisan test --stop-on-failure

# 詳細出力
php artisan test --verbose

# プロファイリング
php artisan test --profile
```

### 12.2.3 カスタムテストコマンド

```php
// app/Console/Commands/TestCoverageCommand.php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Symfony\Component\Process\Process;

class TestCoverageCommand extends Command
{
    protected $signature = 'test:coverage {--min=80} {--fail-on-warning}';
    protected $description = 'Run tests with coverage and fail if below threshold';
    
    public function handle(): int
    {
        $minCoverage = (int) $this->option('min');
        $failOnWarning = $this->option('fail-on-warning');
        
        $this->info("Running tests with minimum coverage of {$minCoverage}%...");
        
        // テスト実行
        $process = new Process([
            'php', 'artisan', 'test', '--coverage-text', '--coverage-clover=coverage.xml'
        ]);
        
        $process->run(function ($type, $buffer) {
            $this->output->write($buffer);
        });
        
        if (!$process->isSuccessful()) {
            $this->error('Tests failed');
            return 1;
        }
        
        // カバレッジチェック
        if (file_exists('coverage.xml')) {
            $coverage = $this->parseCoverage('coverage.xml');
            
            $this->info("Coverage: {$coverage}%");
            
            if ($coverage < $minCoverage) {
                $this->error("Coverage {$coverage}% is below minimum {$minCoverage}%");
                return 1;
            }
            
            if ($failOnWarning && $coverage < 90) {
                $this->warn("Coverage {$coverage}% is below warning threshold of 90%");
                return 1;
            }
            
            $this->info('Coverage check passed!');
        }
        
        return 0;
    }
    
    private function parseCoverage(string $file): float
    {
        $xml = simplexml_load_file($file);
        $metrics = $xml->project->metrics;
        $statements = (int) $metrics['statements'];
        $coveredstatements = (int) $metrics['coveredstatements'];
        
        return $statements > 0 ? round(($coveredstatements / $statements) * 100, 2) : 0.0;
    }
}
```

## 12.3 Laravel Boost（開発支援）

### 12.3.1 基本機能

```php
// Laravel Boostを使った開発効率化

// 1. データベーススキーマ確認
// php artisan boost:schema
// - テーブル構造の表示
// - リレーション情報の確認
// - インデックス情報の表示

// 2. Artisanコマンド一覧と実行
// php artisan boost:commands
// - 利用可能なコマンド一覧
// - コマンドの詳細情報
// - インタラクティブ実行

// 3. エラーログ監視
// php artisan boost:logs
// - リアルタイムログ監視
// - エラーレベル別フィルタリング
// - ログ解析とレポート

// 4. Tinker拡張
// php artisan boost:tinker
// - モデルの簡単操作
// - クエリビルダーのテスト
// - API呼び出しテスト

// 5. ドキュメント検索
// php artisan boost:docs
// - Laravel公式ドキュメント検索
// - パッケージ固有のドキュメント
// - バージョン別情報取得
```

### 12.3.2 カスタム開発コマンド

```php
// app/Console/Commands/DevSetupCommand.php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\File;

class DevSetupCommand extends Command
{
    protected $signature = 'dev:setup {--fresh} {--demo-data}';
    protected $description = 'Setup development environment';
    
    public function handle(): void
    {
        $this->info('🚀 Setting up development environment...');
        
        // 1. 環境チェック
        $this->checkEnvironment();
        
        // 2. データベースセットアップ
        $this->setupDatabase();
        
        // 3. キャッシュクリア
        $this->clearCaches();
        
        // 4. 初期データ作成
        if ($this->option('demo-data')) {
            $this->createDemoData();
        }
        
        // 5. フロントエンドビルド
        $this->buildAssets();
        
        $this->info('✅ Development environment setup completed!');
        $this->displayAccessInfo();
    }
    
    private function checkEnvironment(): void
    {
        $this->info('🔍 Checking environment...');
        
        if (!File::exists('.env')) {
            File::copy('.env.example', '.env');
            $this->info('Created .env file from .env.example');
        }
        
        if (!config('app.key')) {
            Artisan::call('key:generate');
            $this->info('Generated application key');
        }
    }
    
    private function setupDatabase(): void
    {
        $this->info('🗄️  Setting up database...');
        
        if ($this->option('fresh')) {
            Artisan::call('migrate:fresh');
            $this->info('Fresh database migration completed');
        } else {
            Artisan::call('migrate');
            $this->info('Database migration completed');
        }
    }
    
    private function clearCaches(): void
    {
        $this->info('🧹 Clearing caches...');
        
        Artisan::call('cache:clear');
        Artisan::call('config:clear');
        Artisan::call('route:clear');
        Artisan::call('view:clear');
        
        $this->info('All caches cleared');
    }
    
    private function createDemoData(): void
    {
        $this->info('📊 Creating demo data...');
        
        Artisan::call('db:seed', [
            '--class' => 'DemoDataSeeder'
        ]);
        
        $this->info('Demo data created');
    }
    
    private function buildAssets(): void
    {
        $this->info('🏗️  Building frontend assets...');
        
        if (File::exists('package.json')) {
            $this->info('Installing npm dependencies...');
            shell_exec('npm install');
            
            $this->info('Building assets...');
            shell_exec('npm run build');
        }
    }
    
    private function displayAccessInfo(): void
    {
        $this->newLine();
        $this->info('🌐 Application Information:');
        $this->line('URL: ' . config('app.url'));
        $this->line('Environment: ' . config('app.env'));
        
        if ($this->option('demo-data')) {
            $this->newLine();
            $this->info('👤 Demo Users:');
            $this->line('Admin: admin@example.com / password');
            $this->line('User: user@example.com / password');
        }
    }
}
```

## 12.4 ブラウザログ確認

### 12.4.1 ブラウザログ監視コマンド

```php
// app/Console/Commands/BrowserLogsCommand.php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

class BrowserLogsCommand extends Command
{
    protected $signature = 'logs:browser {--follow} {--level=} {--filter=}';
    protected $description = 'Monitor browser logs and errors';
    
    private array $logPaths = [
        'laravel' => 'storage/logs/laravel.log',
        'nginx_access' => 'storage/logs/nginx-access.log',
        'nginx_error' => 'storage/logs/nginx-error.log',
        'php_error' => 'storage/logs/php-error.log',
    ];
    
    public function handle(): void
    {
        $this->info('📊 Starting browser log monitoring...');
        
        if ($this->option('follow')) {
            $this->followLogs();
        } else {
            $this->displayRecentLogs();
        }
    }
    
    private function followLogs(): void
    {
        $this->info('👁️  Following logs... (Press Ctrl+C to stop)');
        
        // リアルタイムログ監視
        $processes = [];
        
        foreach ($this->logPaths as $type => $path) {
            if (File::exists($path)) {
                $processes[] = $this->startLogTail($type, $path);
            }
        }
        
        // プロセス監視
        while (true) {
            sleep(1);
            
            foreach ($processes as $process) {
                if ($process && !$process->isRunning()) {
                    break 2;
                }
            }
        }
    }
    
    private function displayRecentLogs(): void
    {
        $level = $this->option('level');
        $filter = $this->option('filter');
        
        foreach ($this->logPaths as $type => $path) {
            if (!File::exists($path)) {
                continue;
            }
            
            $this->info("\n📋 Recent {$type} logs:");
            $this->line(str_repeat('-', 50));
            
            $lines = $this->getRecentLogLines($path, 20);
            
            foreach ($lines as $line) {
                if ($this->shouldShowLine($line, $level, $filter)) {
                    $this->formatLogLine($line, $type);
                }
            }
        }
    }
    
    private function getRecentLogLines(string $path, int $count = 20): array
    {
        $content = File::get($path);
        $lines = explode("\n", $content);
        
        return array_slice(array_filter($lines), -$count);
    }
    
    private function shouldShowLine(string $line, ?string $level, ?string $filter): bool
    {
        if ($level && !Str::contains(strtolower($line), strtolower($level))) {
            return false;
        }
        
        if ($filter && !Str::contains(strtolower($line), strtolower($filter))) {
            return false;
        }
        
        return true;
    }
    
    private function formatLogLine(string $line, string $type): void
    {
        // エラーレベルに応じた色分け
        if (Str::contains(strtolower($line), ['error', 'critical', 'emergency'])) {
            $this->error("[{$type}] {$line}");
        } elseif (Str::contains(strtolower($line), ['warning', 'warn'])) {
            $this->warn("[{$type}] {$line}");
        } elseif (Str::contains(strtolower($line), ['info', 'notice'])) {
            $this->info("[{$type}] {$line}");
        } else {
            $this->line("[{$type}] {$line}");
        }
    }
    
    private function startLogTail(string $type, string $path)
    {
        // tail -f コマンドでリアルタイム監視
        return popen("tail -f {$path} | while read line; do echo '[{$type}] '\$line; done", 'r');
    }
}
```

### 12.4.2 フロントエンドエラー収集

```typescript
// resources/js/utils/errorLogger.ts
export interface BrowserError {
    message: string
    source: string
    line: number
    column: number
    stack?: string
    url: string
    userAgent: string
    timestamp: string
    userId?: number
}

class ErrorLogger {
    private endpoint = '/api/browser-errors'
    private errors: BrowserError[] = []
    private batchSize = 10
    private flushInterval = 30000 // 30秒
    
    constructor() {
        this.setupGlobalErrorHandlers()
        this.startBatchFlush()
    }
    
    private setupGlobalErrorHandlers(): void {
        // JavaScript エラー
        window.addEventListener('error', (event) => {
            this.logError({
                message: event.message,
                source: event.filename || 'unknown',
                line: event.lineno || 0,
                column: event.colno || 0,
                stack: event.error?.stack,
                url: window.location.href,
                userAgent: navigator.userAgent,
                timestamp: new Date().toISOString()
            })
        })
        
        // Promise rejection エラー
        window.addEventListener('unhandledrejection', (event) => {
            this.logError({
                message: `Unhandled Promise Rejection: ${event.reason}`,
                source: 'Promise',
                line: 0,
                column: 0,
                stack: event.reason?.stack,
                url: window.location.href,
                userAgent: navigator.userAgent,
                timestamp: new Date().toISOString()
            })
        })
        
        // Vue エラー（開発時のみ）
        if (process.env.NODE_ENV === 'development') {
            const app = getCurrentInstance()?.appContext.app
            if (app) {
                app.config.errorHandler = (error, instance, info) => {
                    this.logError({
                        message: error.message,
                        source: 'Vue',
                        line: 0,
                        column: 0,
                        stack: error.stack,
                        url: window.location.href,
                        userAgent: navigator.userAgent,
                        timestamp: new Date().toISOString()
                    })
                }
            }
        }
    }
    
    private logError(error: BrowserError): void {
        // 開発環境ではコンソールにも出力
        if (process.env.NODE_ENV === 'development') {
            console.error('Browser Error:', error)
        }
        
        this.errors.push(error)
        
        // バッチサイズに達した場合は即座に送信
        if (this.errors.length >= this.batchSize) {
            this.flushErrors()
        }
    }
    
    private startBatchFlush(): void {
        setInterval(() => {
            if (this.errors.length > 0) {
                this.flushErrors()
            }
        }, this.flushInterval)
    }
    
    private async flushErrors(): Promise<void> {
        if (this.errors.length === 0) return
        
        const errorsToSend = [...this.errors]
        this.errors = []
        
        try {
            await fetch(this.endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
                },
                body: JSON.stringify({ errors: errorsToSend })
            })
        } catch (error) {
            // 送信失敗時は再度キューに戻す（最大3回まで）
            console.warn('Failed to send browser errors:', error)
            // エラー送信の無限ループを防ぐため、再キューは慎重に実装
        }
    }
    
    // 手動でエラーをログ
    public logCustomError(message: string, source: string = 'Custom'): void {
        this.logError({
            message,
            source,
            line: 0,
            column: 0,
            url: window.location.href,
            userAgent: navigator.userAgent,
            timestamp: new Date().toISOString()
        })
    }
}

// シングルトンとしてエクスポート
export const errorLogger = new ErrorLogger()
```

```php
// app/Http/Controllers/BrowserErrorController.php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class BrowserErrorController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'errors' => 'required|array',
            'errors.*.message' => 'required|string',
            'errors.*.source' => 'required|string',
            'errors.*.line' => 'required|integer',
            'errors.*.column' => 'required|integer',
            'errors.*.stack' => 'nullable|string',
            'errors.*.url' => 'required|url',
            'errors.*.userAgent' => 'required|string',
            'errors.*.timestamp' => 'required|date',
        ]);
        
        foreach ($validated['errors'] as $error) {
            Log::channel('browser_errors')->error('Browser Error', [
                'message' => $error['message'],
                'source' => $error['source'],
                'line' => $error['line'],
                'column' => $error['column'],
                'stack' => $error['stack'] ?? null,
                'url' => $error['url'],
                'user_agent' => $error['userAgent'],
                'timestamp' => $error['timestamp'],
                'user_id' => auth()->id(),
                'ip_address' => $request->ip(),
            ]);
        }
        
        return response()->json(['status' => 'success']);
    }
}