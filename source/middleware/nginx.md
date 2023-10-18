title: nginx基础知识
---
## 目录结构
```bash
# 目前项目采用的文件命名示例
nginx/
├── conf               #用来存放配置文件相关
├── html               #用来存放静态文件的默认目录 html、css等
├── sbin               #nginx的主程序
├── client_body_temp   #用来存放运行过程中的临时文件
├── fastcgi_temp       #用来存放运行过程中的临时文件
├── fproxy_temp        #用来存放运行过程中的临时文件
└── scgi_temp          #用来存放运行过程中的临时文件
```

## 运行原理

<img src="/images/middleware/nginx/run.png" width="50%" />

## Nginx配置与应用场景
### 最小配置
1. worker_processes
```bash 
worker_processes 1; # 默认为1，表示开启一个业务进程
```
2. worker_connections
```bash 
worker_connections 1024; # 单个业务进程可接受连接数
```
3. include mime.types;
```bash 
include mime.types; # 引入http mime类型
```
4. default_type application/octet-stream;
```bash 
default_type application/octet-stream; # 如果mime类型没匹配上，默认使用二进制流的方式传输。
```
5. sendfile on;
```bash 
sendfile on; # 使用linux的 sendfile(socket, file, len) 高效网络传输，也就是数据0拷贝。
```
(1) 未开启sendfile

<img src="/images/middleware/nginx/send_file_off.png" width="50%" />

(2) 开启sendfile

<img src="/images/middleware/nginx/send_file_on.png" width="50%" />

6. keepalive_timeout 65;
```bash 
keepalive_timeout 65; # 指定每个 TCP 连接最多可以保持65s
```

## 虚拟主机
原本一台服务器只能对应一个站点，通过虚拟主机技术可以虚拟化成多个站点同时对外提供服务。
```bash 
# 虚拟主机配置
server {
  listen 80; 监听端口号
  server_name localhost; 主机名
  location / { 匹配路径
    root html; 文件根目录
    index index.html index.htm; 默认页名称
  }
  error_page 500 502 503 504 /50x.html; 报错编码对应页面
  location = /50x.html {
    root html;
  }
}
```
### servername匹配规则
需要注意的是servername匹配分先后顺序，写在前面的匹配上就不会继续往下匹配了。
1. 完整匹配
```bash 
# 可以在同一servername中匹配多个域名
server_name vod.mmban.com www1.mmban.com;
```
2. 通配符匹配
```bash 
server_name *.mmban.com;
```
3. 通配符结束匹配
```bash 
server_name vod.*;
```
4. 正则匹配
```bash 
server_name ~^[0-9]+\.mmban\.com$;
```

### 反向代理
```bash 
location / {
  proxy_pass http://baidu.com/;
}
```

### 基于反向代理的负载均衡
```bash 
upstream httpd {
  server 192.168.44.102:80;
  server 192.168.43.103:80;
}

server {
  listen 80; 监听端口号
  server_name httpd; 主机名
  location / { 匹配路径
    root html; 文件根目录
    index index.html index.htm; 默认页名称
  }
}
```

#### 负载均衡策略

##### 轮询
默认情况下使用轮询方式，逐一转发，这种方式适用于无状态请求。

##### weight(权重)
指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。
```bash 
upstream httpd {
  server 127.0.0.1:8050 weight=10 down;  #down：表示当前的server暂时不参与负载
  server 127.0.0.1:8060 weight=1;        #weight：默认为1.weight越大，负载的权重就越大。
  server 127.0.0.1:8060 weight=1 backup; #backup： 其它所有的非backup机器down或者忙的时候，请求backup机器。
}
```
##### ip_hash
根据客户端的ip地址转发同一台服务器，可以保持回话。
##### least_conn
最少连接访问
##### url_hash
根据用户访问的url定向转发请求
##### fair
根据后端服务器响应时间转发请求

### 动静分离
```bash 
# 配置反向代理
location / {
  proxy_pass http://127.0.0.1:8080;
  root html;
  index index.html index.htm;
}

# css 
location /css {
  root /usr/local/nginx/static;
  index index.html index.htm;
}

# js 
location /js {
  root /usr/local/nginx/static;
  index index.html index.htm;
}

# images
location /images {
  root /usr/local/nginx/static;
  index index.html index.htm;
}
```
1. 使用一个location
```bash
# 使用正则
location ~*/(css|img|js) {
  root /usr/local/nginx/static;
  index index.html index.htm;
}
```
2. location 前缀
```bash 
/  # 通用匹配，任何请求都会匹配到。
=  # 精准匹配，不是以指定模式开头
~  # 正则匹配，区分大小写
~* # 正则匹配，不区分大小
^~ # 非正则匹配，匹配以指定模式开头的location
```
3. location 匹配顺序
```bash
# 多个正则location直接按书写顺序匹配，成功后就不会继续往后面匹配
# 普通（非正则）location会一直往下，直到找到匹配度最高的（最大前缀匹配）
# 当普通location与正则location同时存在，如果正则匹配成功,则不会再执行普通匹配
# 所有类型location存在时，“=”匹配 > “^~”匹配 > 正则匹配 > 普通（最大前缀匹配）
```
4. alias与root
```bash 
location /css {
  alias /usr/local/nginx/static/css;
  index index.html index.htm;
}
```
* **root**用来设置根目录，而**alias**在接受请求的时候在路径上不会加上**location**。
* **alias**指定的目录是准确的，即location匹配访问的path目录下的文件直接是在alias目录下查找的； 
* **root**指定的目录是location匹配访问的path目录的上一级目录,这个path目录一定要是真实存在root指定目录下的； 
* 使用**alias**标签的目录块中不能使用rewrite的break（具体原因不明）；另外，**alias**指定的目录后面必须要加上"/"符号！！ 
* **alias**虚拟目录配置中，location匹配的path目录如果后面不带"/"，那么访问的url地址中这个path目录后面加不加"/"不影响访问，访问时它会自动加上"/"； 但是如果location匹配的path目录后面加上"/"，那么访问的url地址中这个path目录必须要加上"/"，访问时它不会自动加上"/"。如果不加上"/"，访问就会失败！ 
* **root**目录配置中，location匹配的path目录后面带不带"/"，都不会影响访问。

### UrlRewrite
#### rewrite语法格式及参数语法
```bash 
#rewrite是实现URL重写的关键指令，根据regex (正则表达式)部分内容，重定向到replacement，结尾是flag标记。
rewrite <regex> <replacement> [flag];
关键字   正则     替代内容       flag标记
```
1. 关键字：其中关键字error_log不能改变
2. 正则：perl兼容正则表达式语句进行规则匹配
3. 替代内容：将正则匹配的内容替换成replacement
4. flag标记：rewrite支持的flag标记
5. rewrite参数的标签段位置：server,location,if
6. flag标记说明:
```bash
last      #本条规则匹配完成后，继续向下匹配新的location URI规则
break     #本条规则匹配完成即终止，不再匹配后面的任何规则
redirect  #返回302临时重定向，浏览器地址会显示跳转后的URL地址
permanent #返回301永久重定向，浏览器地址栏会显示跳转后的URL地
```
```bash
#示例
rewrite ^/([0-9]+).html$ /index.jsp?pageNum=$1 break;
```

```bash
# 配合负载均衡使用
upstream httpds {
  server 192.168.44.102 weight=8 down;
  server 192.168.44.103:8080 weight=2;
  server 192.168.44.104:8080 weight=1 backup;
}
location / {
  rewrite ^/([0-9]+).html$ /index.jsp?pageNum=$1 redirect;
  proxy_pass http://httpds ;
}
```

### 防盗链配置
防止别人引用网站中的图片或其它资源文件
```bash
valid_referers none | blocked | server_names | strings ....;
# none， 检测 Referer 头域不存在的情况。
# blocked，检测 Referer 头域的值被防火墙或者代理服务器删除或伪装的情况。这种情况该头域的值不以“http://” 或 “https://” 开头。
# server_names ，设置一个或多个 URL ，检测 Referer 头域的值是否是这些 URL 中的某一个。
```
1. 在需要防盗链的location中配置
```bash
valid_referers 192.168.44.101;
if ($invalid_referer) {
  return 403;
}
```

### 高可用配置