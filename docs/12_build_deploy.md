# 11. ビルド・デプロイ

## 11.1 Vite設定

### 11.1.1 基本設定

```typescript
// vite.config.js
import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.ts'],
            refresh: true,
        }),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
    ],
    resolve: {
        alias: {
            '@': resolve(__dirname, 'resources/js'),
            '~': resolve(__dirname, 'resources'),
        },
    },
    build: {
        outDir: 'public/build',
        emptyOutDir: true,
        manifest: true,
        rollupOptions: {
            output: {
                manualChunks: {
                    vendor: ['vue', 'vue-router', 'pinia'],
                    ui: ['@headlessui/vue', '@heroicons/vue'],
                },
            },
        },
        chunkSizeWarningLimit: 1000,
    },
    server: {
        hmr: {
            host: 'localhost',
        },
        host: true,
        port: 5173,
    },
    define: {
        __VUE_PROD_DEVTOOLS__: false,
    },
})
```

### 11.1.2 環境別設定

```typescript
// vite.config.production.js
import { defineConfig } from 'vite'
import baseConfig from './vite.config.js'

export default defineConfig({
    ...baseConfig,
    build: {
        ...baseConfig.build,
        minify: 'esbuild',
        sourcemap: false,
        rollupOptions: {
            ...baseConfig.build.rollupOptions,
            output: {
                ...baseConfig.build.rollupOptions.output,
                assetFileNames: (assetInfo) => {
                    const info = assetInfo.name.split('.')
                    const ext = info[info.length - 1]
                    if (/png|jpe?g|svg|gif|tiff|bmp|ico/i.test(ext)) {
                        return `assets/images/[name]-[hash][extname]`
                    }
                    if (/css/i.test(ext)) {
                        return `assets/css/[name]-[hash][extname]`
                    }
                    return `assets/[name]-[hash][extname]`
                },
                chunkFileNames: 'assets/js/[name]-[hash].js',
                entryFileNames: 'assets/js/[name]-[hash].js',
            },
        },
    },
    esbuild: {
        drop: ['console', 'debugger'],
    },
})

// vite.config.development.js
import { defineConfig } from 'vite'
import baseConfig from './vite.config.js'

export default defineConfig({
    ...baseConfig,
    build: {
        ...baseConfig.build,
        sourcemap: true,
        minify: false,
    },
    define: {
        ...baseConfig.define,
        __VUE_PROD_DEVTOOLS__: true,
    },
})
```

### 11.1.3 最適化設定

```typescript
// vite.config.optimized.js
import { defineConfig } from 'vite'
import { splitVendorChunkPlugin } from 'vite'
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig({
    plugins: [
        // ... other plugins
        splitVendorChunkPlugin(),
        visualizer({
            filename: 'dist/stats.html',
            open: true,
            gzipSize: true,
        }),
    ],
    build: {
        rollupOptions: {
            output: {
                manualChunks: {
                    // Core Vue ecosystem
                    'vue-vendor': ['vue', 'vue-router', 'pinia'],
                    
                    // UI libraries
                    'ui-vendor': [
                        '@headlessui/vue',
                        '@heroicons/vue/24/outline',
                        '@heroicons/vue/24/solid',
                    ],
                    
                    // Utility libraries
                    'utils-vendor': [
                        'axios',
                        'lodash-es',
                        'date-fns',
                    ],
                    
                    // Form libraries
                    'form-vendor': [
                        '@vueform/vueform',
                        'yup',
                    ],
                },
            },
        },
        
        // バンドルサイズを制限
        chunkSizeWarningLimit: 500,
        
        // アセットインライン化の闾値
        assetsInlineLimit: 4096,
    },
    
    // 依存関係の事前バンドル化
    optimizeDeps: {
        include: [
            'vue',
            'vue-router',
            'pinia',
            'axios',
            'lodash-es',
        ],
        exclude: [
            'vue-demi',
        ],
    },
})
```

## 11.2 npm scripts

### 11.2.1 package.json 設定

```json
{
  "name": "laravel-blog",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "npm run build:production",
    "build:production": "vite build --config vite.config.production.js",
    "build:development": "vite build --config vite.config.development.js",
    "build:analyze": "vite build --config vite.config.optimized.js",
    "preview": "vite preview",
    
    "lint": "npm run lint:js && npm run lint:css",
    "lint:js": "eslint resources/js --ext .vue,.ts,.js",
    "lint:css": "stylelint \"resources/**/*.{css,vue}\"",
    "lint:fix": "npm run lint:js -- --fix && npm run lint:css -- --fix",
    
    "format": "prettier --write resources/js/**/*.{vue,ts,js}",
    "format:check": "prettier --check resources/js/**/*.{vue,ts,js}",
    
    "type-check": "vue-tsc --noEmit",
    
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:run": "vitest run",
    "test:coverage": "vitest --coverage",
    
    "clean": "rimraf public/build node_modules/.vite",
    "clean:all": "npm run clean && rimraf node_modules",
    
    "postinstall": "npm run build:production",
    
    "docker:dev": "docker-compose -f docker-compose.dev.yml up -d",
    "docker:prod": "docker-compose -f docker-compose.prod.yml up -d",
    "docker:down": "docker-compose down"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "@vitejs/plugin-vue": "^4.4.0",
    "@vue/eslint-config-typescript": "^12.0.0",
    "@vue/test-utils": "^2.4.0",
    "@vue/tsconfig": "^0.4.0",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.0.0",
    "eslint-plugin-vue": "^9.17.0",
    "jsdom": "^22.1.0",
    "laravel-vite-plugin": "^0.8.0",
    "postcss": "^8.4.31",
    "prettier": "^3.0.0",
    "rimraf": "^5.0.0",
    "rollup-plugin-visualizer": "^5.9.0",
    "stylelint": "^15.0.0",
    "stylelint-config-standard": "^34.0.0",
    "tailwindcss": "^3.3.0",
    "typescript": "~5.2.0",
    "vite": "^4.4.5",
    "vitest": "^0.34.0",
    "vue-tsc": "^1.8.0"
  },
  "dependencies": {
    "@headlessui/vue": "^1.7.16",
    "@heroicons/vue": "^2.0.18",
    "axios": "^1.1.2",
    "pinia": "^2.1.6",
    "vue": "^3.3.0",
    "vue-router": "^4.2.0"
  }
}
```

### 11.2.2 カスタムスクリプト

```bash
#!/bin/bash
# scripts/build.sh - カスタムビルドスクリプト

set -e

ENV=${1:-production}
VERBOSE=${2:-false}

echo "Building application for $ENV environment..."

# クリーンアップ
echo "Cleaning up previous builds..."
npm run clean

# 環境別ビルド
case $ENV in
    "production")
        echo "Building for production..."
        npm run build:production
        ;;
    "development"|"dev")
        echo "Building for development..."
        npm run build:development
        ;;
    "analyze")
        echo "Building with bundle analysis..."
        npm run build:analyze
        ;;
    *)
        echo "Unknown environment: $ENV"
        echo "Available environments: production, development, analyze"
        exit 1
        ;;
esac

# ビルド結果の確認
if [ -d "public/build" ]; then
    BUILD_SIZE=$(du -sh public/build | cut -f1)
    ASSET_COUNT=$(find public/build -type f | wc -l)
    
    echo "Build completed successfully!"
    echo "Build size: $BUILD_SIZE"
    echo "Asset count: $ASSET_COUNT files"
    
    if [ "$VERBOSE" = "true" ]; then
        echo "\nBuild contents:"
        ls -la public/build/
        
        echo "\nLargest files:"
        find public/build -type f -exec ls -lh {} + | sort -k5 -hr | head -10
    fi
else
    echo "Build failed: public/build directory not found"
    exit 1
fi

# Gzipサイズの確認（productionのみ）
if [ "$ENV" = "production" ]; then
    echo "\nGzipped sizes:"
    find public/build -name "*.js" -o -name "*.css" | while read file; do
        original_size=$(wc -c < "$file")
        gzip_size=$(gzip -c "$file" | wc -c)
        compression_ratio=$(echo "scale=1; $gzip_size * 100 / $original_size" | bc)
        echo "$(basename "$file"): $(numfmt --to=iec $original_size) -> $(numfmt --to=iec $gzip_size) (${compression_ratio}%)"
    done
fi
```

## 11.3 Docker環境

### 11.3.1 Nginx設定

```nginx
# docker/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for" '
                   '$request_time $upstream_response_time';
    
    access_log /var/log/nginx/access.log main;
    
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;
    
    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Brotli Settings (if available)
    # brotli on;
    # brotli_comp_level 6;
    # brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    
    # Include additional configs
    include /etc/nginx/conf.d/*.conf;
}
```

```nginx
# docker/nginx/conf.d/app.conf
upstream php-fpm {
    server app:9000;
    keepalive 16;
}

server {
    listen 80;
    server_name localhost;
    root /var/www/html/public;
    index index.php index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self';" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Asset caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
        
        # CORS for fonts
        location ~* \.(woff|woff2|ttf|eot)$ {
            add_header Access-Control-Allow-Origin "*";
        }
    }
    
    # API rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # Auth endpoints rate limiting
    location ~ ^/(login|register|password) {
        limit_req zone=login burst=5 nodelay;
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Deny access to sensitive files
    location ~* \.(env|git|svn|htaccess|htpasswd)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # PHP handling
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php-fpm;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
        # FastCGI settings
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 64k;
        fastcgi_buffers 4 64k;
        fastcgi_busy_buffers_size 128k;
        fastcgi_temp_file_write_size 128k;
        
        # Hide PHP version
        fastcgi_hide_header X-Powered-By;
    }
}

# HTTPS redirect (production)
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 10m;
    ssl_ciphers PROFILE=SYSTEM;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Rest of the configuration same as HTTP
    root /var/www/html/public;
    index index.php index.html;
    
    # ... (same location blocks as above)
}
```

### 11.3.2 PHP-FPM設定

```dockerfile
# docker/php/Dockerfile
FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    icu-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libzip-dev \
    supervisor

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    zip \
    opcache

# Install Redis extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Copy supervisor configuration
COPY docker/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create Laravel directories
RUN mkdir -p /var/www/html/storage/logs \
    && mkdir -p /var/www/html/storage/framework/cache/data \
    && mkdir -p /var/www/html/storage/framework/sessions \
    && mkdir -p /var/www/html/storage/framework/views \
    && mkdir -p /var/www/html/bootstrap/cache

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Copy application code
COPY --chown=www-data:www-data . /var/www/html

# Install dependencies
RUN composer install --optimize-autoloader --no-dev

# Generate application key
RUN php artisan key:generate --no-interaction

# Cache configuration
RUN php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

```ini
; docker/php/php.ini
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions =
disable_classes =
zend.enable_gc = On
zend.exception_ignore_args = On

expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 256M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On

post_max_size = 20M
default_mimetype = "text/html"
default_charset = "UTF-8"

file_uploads = On
upload_max_filesize = 20M
max_file_uploads = 20

[Date]
date.timezone = Asia/Tokyo

[Session]
session.save_handler = files
session.use_strict_mode = 1
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = "Lax"

[opcache]
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
```

### 11.3.3 MariaDB設定

```ini
# docker/mariadb/my.cnf
[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init-connect = 'SET NAMES utf8mb4'

# General settings
sql_mode = STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
max_connections = 200
thread_cache_size = 8
query_cache_type = 1
query_cache_size = 64M
query_cache_limit = 2M

# InnoDB settings
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_flush_log_at_trx_commit = 1

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1

# Binary logging
log-bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# Security
skip-name-resolve
bind-address = 0.0.0.0
```

### 11.3.4 MailHog設定

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    volumes:
      - ./:/var/www/html
      - ./docker/php/php.ini:/usr/local/etc/php/php.ini
    environment:
      - APP_ENV=local
      - DB_HOST=mariadb
      - REDIS_HOST=redis
      - MAIL_HOST=mailhog
      - MAIL_PORT=1025
    depends_on:
      - mariadb
      - redis
      - mailhog
    networks:
      - app-network
  
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/var/www/html
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./docker/nginx/conf.d:/etc/nginx/conf.d
      - ./docker/nginx/ssl:/etc/nginx/ssl
    depends_on:
      - app
    networks:
      - app-network
  
  mariadb:
    image: mariadb:latest
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: password
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./docker/mariadb/my.cnf:/etc/mysql/conf.d/my.cnf
      - ./docker/mariadb/init:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    networks:
      - app-network
  
  redis:
    image: redis:alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      - app-network
  
  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    networks:
      - app-network
  
  # Node.js development server
  vite:
    image: node:18-alpine
    working_dir: /app
    command: npm run dev
    volumes:
      - ./:/app
    ports:
      - "5173:5173"
    environment:
      - NODE_ENV=development
    networks:
      - app-network
  
  # Queue worker
  queue:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    command: php artisan queue:work --verbose --tries=3 --timeout=90
    volumes:
      - ./:/var/www/html
    environment:
      - APP_ENV=local
      - DB_HOST=mariadb
      - REDIS_HOST=redis
    depends_on:
      - mariadb
      - redis
    networks:
      - app-network
  
  # Scheduler
  scheduler:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    command: >
      sh -c "while true; do
        php artisan schedule:run --verbose --no-interaction
        sleep 60
      done"
    volumes:
      - ./:/var/www/html
    environment:
      - APP_ENV=local
      - DB_HOST=mariadb
      - REDIS_HOST=redis
    depends_on:
      - mariadb
      - redis
    networks:
      - app-network

volumes:
  mariadb_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

```bash
# docker/scripts/entrypoint.sh
#!/bin/bash
set -e

# Wait for database
until mysqladmin ping -h mariadb -u root -proot --silent; do
    echo 'Waiting for database...'
    sleep 2
done

# Run migrations
php artisan migrate --force

# Clear caches
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start PHP-FPM
exec "$@"
```