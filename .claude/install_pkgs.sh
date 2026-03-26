#!/bin/bash
# リモート環境（CC on Web）でのみ実行
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

PHP_VERSION=8.5

# -------------------------------------------------------
# PHP 環境のセットアップ
# -------------------------------------------------------
# CC on Web 環境ではプロキシにより ppa.launchpadcontent.net が
# ブロックされるため、apt-get での PPA パッケージ取得は不可。
# 代わりに shivammathur/php-builder の事前ビルド済みバイナリを
# GitHub Releases から取得してインストールする。
# -------------------------------------------------------
if ! php -v 2>/dev/null | grep -q "PHP ${PHP_VERSION}"; then
  UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
  TAR_FILE="php_${PHP_VERSION}+ubuntu${UBUNTU_VERSION}.tar.xz"
  DOWNLOAD_URL="https://github.com/shivammathur/php-builder/releases/download/${PHP_VERSION}/${TAR_FILE}"

  curl -sL "$DOWNLOAD_URL" -o "/tmp/${TAR_FILE}"
  tar -xJf "/tmp/${TAR_FILE}" -C /
  rm -f "/tmp/${TAR_FILE}"

  # 不要な拡張（共有ライブラリ未インストール）を無効化して警告を抑制
  CONF_DIR="/etc/php/${PHP_VERSION}/cli/conf.d"
  DISABLE_EXTS=(
    20-dba.ini 20-enchant.ini 20-imagick.ini 20-odbc.ini
    20-pdo_dblib.ini 20-pdo_firebird.ini 20-pdo_odbc.ini
    20-snmp.ini 20-tidy.ini 20-zmq.ini 20-imap.ini
    20-memcache.ini 25-memcached.ini
    20-sqlsrv.ini 20-pdo_sqlsrv.ini
  )
  for ini in "${DISABLE_EXTS[@]}"; do
    [ -f "$CONF_DIR/$ini" ] && mv "$CONF_DIR/$ini" "$CONF_DIR/$ini.disabled"
  done

  # デフォルトの PHP バージョンを切り替え
  update-alternatives --install /usr/bin/php php "/usr/bin/php${PHP_VERSION}" 85
  update-alternatives --set php "/usr/bin/php${PHP_VERSION}"
fi

# Composer のインストール（未インストールの場合）
if ! command -v composer &>/dev/null; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# -------------------------------------------------------
# 依存関係のインストール
# -------------------------------------------------------
cd "$CLAUDE_PROJECT_DIR"
composer install --no-interaction --prefer-dist

# -------------------------------------------------------
# lefthook のインストール
# -------------------------------------------------------
if ! command -v lefthook &>/dev/null; then
  npm install -g @evilmartians/lefthook
fi
lefthook install
