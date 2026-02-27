FROM php:8.2-apache

# 必要なパッケージとPHP拡張をインストール
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl \
    && docker-php-ext-install pdo pdo_mysql zip

# Apacheのmod_rewriteを有効化
RUN a2enmod rewrite


#Xdebugのインストール
RUN pecl install xdebug-3.3.0 && \
    docker-php-ext-enable xdebug && \
    docker-php-ext-install ftp

# Composerをインストール
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

##追加 npmのインストール(コンテナ内でnpmコマンドを実行するため)
## その他モジュール追加
RUN apt update && apt install nodejs npm -y \
    libicu-dev \
    && docker-php-ext-install intl bcmath



# ApacheのドキュメントルートをLaravel用に変更
ENV APACHE_DOCUMENT_ROOT=/var/www/cms/public

# LaravelのpublicディレクトリをApacheに正しく認識させる
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

WORKDIR /var/www
