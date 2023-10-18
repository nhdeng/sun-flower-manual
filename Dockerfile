FROM node:13 as build-deps
WORKDIR /app
COPY  . /app
RUN npm config set registry https://registry.npm.taobao.org/
RUN npm install -g hexo-cli
RUN npm install
CMD ["hexo", "s"]