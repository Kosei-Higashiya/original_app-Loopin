FROM ruby:3.2.3
ENV APP /app
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

# Node.js(安定板) リポジトリ登録＋ビルドツール＋MariaDBクライアント導入
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
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


# CMD: 起動時にプリコンパイルして Rails サーバーを起動
CMD bash -c "\
    echo 'プリコンパイル開始'; \
    RAILS_ENV=production bundle exec rails assets:precompile && \
    echo 'マイグレーション実行'; \
    RAILS_ENV=production bundle exec rails db:migrate && \
    echo 'サーバー起動'; \
    bundle exec rails s -b 0.0.0.0 -p \$PORT \
"
