FROM ruby:3.3.1
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