FROM ruby:3.2.3
ENV APP /app
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# Node.js リポジトリ登録＋ビルドツール＋MariaDBクライアント導入
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
 && apt update -qq \
 && apt install -y build-essential postgresql-client nodejs \
 && npm install --global yarn

WORKDIR $APP

# まずは Gemfile だけコピーして bundle install（キャッシュ活用）
COPY Gemfile      $APP/Gemfile
COPY Gemfile.lock $APP/Gemfile.lock
RUN bundle install

# アプリ全体をコピー
COPY . $APP

# Webpacker / JSアセットが必要なら yarn install
RUN yarn install --check-files

ENV RAILS_ENV=development
ENV RACK_ENV=development


# デフォルトコマンドは Rails サーバー
CMD ["rails", "server", "-b", "0.0.0.0"]

