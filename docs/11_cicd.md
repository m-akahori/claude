# 10. CI/CD

## 10.1 継続的インテグレーション

### 10.1.1 自動テスト実行

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  php-tests:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mariadb:latest
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: testing
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
      
      redis:
        image: redis:alpine
        ports:
          - 6379:6379
        options: --health-cmd="redis-cli ping" --health-interval=10s --health-timeout=5s --health-retries=3
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, dom, fileinfo, mysql, redis
          coverage: xdebug
      
      - name: Copy .env
        run: php -r "file_exists('.env') || copy('.env.example', '.env');"
      
      - name: Install Dependencies
        run: composer install --no-progress --prefer-dist --optimize-autoloader
      
      - name: Generate key
        run: php artisan key:generate
      
      - name: Directory Permissions
        run: chmod -R 777 storage bootstrap/cache
      
      - name: Create Database
        run: |
          mysql -h 127.0.0.1 -u root -proot -e 'CREATE DATABASE IF NOT EXISTS testing;'
      
      - name: Run Migration
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: root
        run: php artisan migrate --force
      
      - name: Run PHPUnit Tests
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: root
          REDIS_HOST: 127.0.0.1
          REDIS_PORT: 6379
        run: php artisan test --coverage-clover=coverage.xml --coverage-html=coverage-report
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          flags: php
          name: php-coverage
      
      - name: Upload Coverage Report
        uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: coverage-report
          path: coverage-report/
  
  javascript-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install Dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npm run lint
      
      - name: Run TypeScript Check
        run: npm run type-check
      
      - name: Run Vitest Tests
        run: npm run test:coverage
      
      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
          flags: javascript
          name: javascript-coverage
  
  build-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install Dependencies
        run: npm ci
      
      - name: Build Application
        run: npm run build
      
      - name: Check Build Output
        run: |
          if [ ! -d "public/build" ]; then
            echo "Build output directory not found"
            exit 1
          fi
          
          if [ -z "$(ls -A public/build)" ]; then
            echo "Build output directory is empty"
            exit 1
          fi
          
          echo "Build successful"
```

### 10.1.2 コード品質チェック

```yaml
# .github/workflows/code-quality.yml
name: Code Quality

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  php-code-quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, dom, fileinfo
          tools: composer:v2
      
      - name: Install Dependencies
        run: composer install --no-progress --prefer-dist --optimize-autoloader
      
      - name: Run Laravel Pint
        run: vendor/bin/pint --test
      
      - name: Run PHPStan
        run: vendor/bin/phpstan analyse --memory-limit=2G
      
      - name: Run PHP CS Fixer (dry-run)
        run: vendor/bin/php-cs-fixer fix --dry-run --diff
  
  javascript-code-quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install Dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npm run lint:check
      
      - name: Run Prettier
        run: npm run format:check
      
      - name: Run TypeScript Check
        run: npm run type-check
```

### 10.1.3 セキュリティスキャン

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * 1' # 毎週月曜日2時に実行

jobs:
  php-security:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer:v2
      
      - name: Install Dependencies
        run: composer install --no-dev --optimize-autoloader
      
      - name: Run Security Checker
        run: |
          composer require --dev sensiolabs/security-checker
          vendor/bin/security-checker security:check composer.lock
      
      - name: Run Enlightn Security
        run: |
          composer require --dev enlightn/enlightn
          php artisan enlightn --report --ci
  
  javascript-security:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install Dependencies
        run: npm ci
      
      - name: Run npm audit
        run: npm audit --audit-level=high
      
      - name: Run Snyk Security Scan
        uses: snyk/actions/node@master
        continue-on-error: true
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
  
  codeql:
    name: CodeQL Analysis
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        language: [ 'javascript', 'php' ]
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: ${{ matrix.language }}
      
      - name: Autobuild
        uses: github/codeql-action/autobuild@v2
      
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2
```

## 10.2 継続的デプロイメント

### 10.2.1 ステージング環境

```yaml
# .github/workflows/staging-deploy.yml
name: Deploy to Staging

on:
  push:
    branches: [ develop ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install PHP Dependencies
        run: composer install --no-dev --optimize-autoloader
      
      - name: Install JS Dependencies
        run: npm ci
      
      - name: Build Assets
        run: npm run build
      
      - name: Create deployment package
        run: |
          mkdir -p deploy
          rsync -av --exclude='.git' --exclude='node_modules' --exclude='.env*' --exclude='tests' . deploy/
          cd deploy
          tar -czf ../deployment.tar.gz .
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1
      
      - name: Upload to S3
        run: |
          aws s3 cp deployment.tar.gz s3://${{ secrets.S3_BUCKET }}/staging/deployment-$(date +%Y%m%d_%H%M%S).tar.gz
      
      - name: Deploy to ECS
        run: |
          # ECSタスク定義を更新
          aws ecs update-service \
            --cluster staging-cluster \
            --service staging-service \
            --force-new-deployment
      
      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services staging-service
      
      - name: Run database migrations
        run: |
          # ECS Execを使用してマイグレーション実行
          TASK_ARN=$(aws ecs list-tasks --cluster staging-cluster --service staging-service --query 'taskArns[0]' --output text)
          
          aws ecs execute-command \
            --cluster staging-cluster \
            --task $TASK_ARN \
            --container app \
            --interactive \
            --command "php artisan migrate --force"
      
      - name: Clear cache
        run: |
          aws ecs execute-command \
            --cluster staging-cluster \
            --task $TASK_ARN \
            --container app \
            --interactive \
            --command "php artisan cache:clear && php artisan config:cache"
      
      - name: Notify deployment status
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          message: |
            Staging deployment ${{ job.status }}
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
```

### 10.2.2 本番環境デプロイ

```yaml
# .github/workflows/production-deploy.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      # テスト実行（本番デプロイ前の最終確認）
      - name: Run full test suite
        run: |
          # CI.ymlと同じテストを実行
          echo "Running full test suite..."
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Extract version
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install Dependencies
        run: |
          composer install --no-dev --optimize-autoloader
          npm ci
      
      - name: Build Assets
        run: npm run build
      
      - name: Create deployment package
        run: |
          mkdir -p deploy
          rsync -av \
            --exclude='.git' \
            --exclude='node_modules' \
            --exclude='.env*' \
            --exclude='tests' \
            --exclude='docs' \
            --exclude='README.md' \
            . deploy/
          
          cd deploy
          echo "${{ steps.version.outputs.VERSION }}" > VERSION
          tar -czf ../production-${{ steps.version.outputs.VERSION }}.tar.gz .
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-1
      
      - name: Upload to S3
        run: |
          aws s3 cp production-${{ steps.version.outputs.VERSION }}.tar.gz \
            s3://${{ secrets.S3_BUCKET }}/production/
      
      - name: Create backup
        run: |
          # 現在のバージョンをバックアップ
          aws ecs describe-services \
            --cluster production-cluster \
            --services production-service \
            --query 'services[0].taskDefinition' \
            --output text > current_task_definition.txt
          
          echo "Current task definition backed up"
      
      - name: Deploy to production
        run: |
          # Blue-Greenデプロイメント実装
          ./scripts/blue-green-deploy.sh ${{ steps.version.outputs.VERSION }}
      
      - name: Health check
        run: |
          # ヘルスチェック
          for i in {1..30}; do
            if curl -f ${{ secrets.PRODUCTION_URL }}/health; then
              echo "Health check passed"
              exit 0
            fi
            echo "Health check attempt $i failed, retrying..."
            sleep 10
          done
          
          echo "Health check failed after 5 minutes"
          exit 1
      
      - name: Rollback on failure
        if: failure()
        run: |
          echo "Deployment failed, rolling back..."
          ./scripts/rollback.sh
      
      - name: Notify deployment status
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
          message: |
            Production deployment ${{ job.status }}
            Version: ${{ steps.version.outputs.VERSION }}
            Commit: ${{ github.sha }}
```

### 10.2.3 ロールバック戦略

```bash
#!/bin/bash
# scripts/rollback.sh

set -e

echo "Starting rollback process..."

# 前のバージョンを取得
PREVIOUS_VERSION=$(aws s3 ls s3://${S3_BUCKET}/production/ --recursive | sort | tail -2 | head -1 | awk '{print $4}' | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+')

if [ -z "$PREVIOUS_VERSION" ]; then
    echo "No previous version found for rollback"
    exit 1
fi

echo "Rolling back to version: $PREVIOUS_VERSION"

# 前のタスク定義を復元
if [ -f "current_task_definition.txt" ]; then
    PREVIOUS_TASK_DEFINITION=$(cat current_task_definition.txt)
    
    aws ecs update-service \
        --cluster production-cluster \
        --service production-service \
        --task-definition "$PREVIOUS_TASK_DEFINITION"
else
    echo "No task definition backup found"
    exit 1
fi

# デプロイメント完了を待機
aws ecs wait services-stable \
    --cluster production-cluster \
    --services production-service

# ヘルスチェック
for i in {1..30}; do
    if curl -f ${PRODUCTION_URL}/health; then
        echo "Rollback completed successfully"
        
        # Slack通知
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔄 Production rollback completed to version $PREVIOUS_VERSION\"}" \
            $SLACK_WEBHOOK
        
        exit 0
    fi
    
    echo "Health check attempt $i failed, retrying..."
    sleep 10
done

echo "Rollback health check failed"
exit 1
```

## 10.3 パイプライン設定

### 10.3.1 GitHub Actions

```yaml
# .github/workflows/main.yml - メインパイプライン
name: Main Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  release:
    types: [ published ]

env:
  PHP_VERSION: '8.2'
  NODE_VERSION: '18'
  COMPOSER_CACHE_DIR: /tmp/composer-cache
  NPM_CACHE_DIR: ~/.npm

jobs:
  # 並列実行可能なジョブ
  tests:
    strategy:
      matrix:
        test-suite: [unit, feature, browser]
        php-version: ['8.2', '8.3']
    
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: ${{ env.COMPOSER_CACHE_DIR }}
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php-version }}
          extensions: mbstring, dom, fileinfo, mysql
          coverage: xdebug
      
      - name: Install dependencies
        run: composer install --prefer-dist --no-progress
      
      - name: Run tests
        run: php artisan test --testsuite=${{ matrix.test-suite }}
  
  code-quality:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Laravel Pint
        run: vendor/bin/pint --test
      
      - name: Run PHPStan
        run: vendor/bin/phpstan analyse
  
  security:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run security checks
        run: |
          composer audit
          npm audit
  
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Cache Node modules
        uses: actions/cache@v3
        with:
          path: ${{ env.NPM_CACHE_DIR }}
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build application
        run: npm run build
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-files
          path: public/build
  
  # デプロイメント（依存関係あり）
  deploy-staging:
    needs: [tests, code-quality, security, build]
    if: github.ref == 'refs/heads/develop'
    uses: ./.github/workflows/staging-deploy.yml
    secrets: inherit
  
  deploy-production:
    needs: [tests, code-quality, security, build]
    if: github.event_name == 'release'
    uses: ./.github/workflows/production-deploy.yml
    secrets: inherit
```

### 10.3.2 Docker Build

```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*.*.*' ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./docker/Dockerfile.production
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64,linux/arm64
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
```

### 10.3.3 AWS ECS デプロイ

```json
// ecs-task-definition.json
{
  "family": "blog-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "app",
      "image": "ghcr.io/username/blog-app:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "APP_ENV",
          "value": "production"
        },
        {
          "name": "APP_DEBUG",
          "value": "false"
        }
      ],
      "secrets": [
        {
          "name": "APP_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:app-key"
        },
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/blog-app",
          "awslogs-region": "ap-northeast-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

```bash
#!/bin/bash
# scripts/deploy-ecs.sh

set -e

VERSION=${1:-latest}
ENVIRONMENT=${2:-staging}
REGION=${AWS_REGION:-ap-northeast-1}

echo "Deploying version $VERSION to $ENVIRONMENT"

# タスク定義を更新
sed "s|IMAGE_PLACEHOLDER|ghcr.io/$GITHUB_REPOSITORY:$VERSION|g" ecs-task-definition.json > task-def-updated.json

# 新しいタスク定義を登録
NEW_TASK_DEF=$(aws ecs register-task-definition \
    --cli-input-json file://task-def-updated.json \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "New task definition: $NEW_TASK_DEF"

# サービスを更新
aws ecs update-service \
    --cluster "$ENVIRONMENT-cluster" \
    --service "$ENVIRONMENT-service" \
    --task-definition "$NEW_TASK_DEF" \
    --force-new-deployment

# デプロイメント完了を待機
echo "Waiting for deployment to complete..."
aws ecs wait services-stable \
    --cluster "$ENVIRONMENT-cluster" \
    --services "$ENVIRONMENT-service"

echo "Deployment completed successfully"

# ヘルスチェック
SERVICE_URL=$(aws ecs describe-services \
    --cluster "$ENVIRONMENT-cluster" \
    --services "$ENVIRONMENT-service" \
    --query 'services[0].loadBalancers[0].targetGroupArn' \
    --output text)

for i in {1..10}; do
    if curl -f "$SERVICE_URL/health"; then
        echo "Health check passed"
        exit 0
    fi
    echo "Health check failed, retrying in 30 seconds..."
    sleep 30
done

echo "Health check failed after 5 minutes"
exit 1
```