# K8s集群部署实践

## 环境部署
### 基础环境
#### 操作系统Centos7
操作系统需要提前设置的有
1. selinux关闭
2. swap没有做
3. iptables没安装
4. ip地址规划

#### 终端连接工具 Mobaxterm
#### 虚拟机VMware 16
#### 网络NAT模式
1. 网段192.168.150.0
2. 网关192.168.150.2

#### 机器配置2C4G

#### 基础环境配置
##### 主机名规划

| 序号 | 主机IP            | 主机名规划                          |
|----|-----------------|--------------------------------|
| 1  | 192.168.150.131 | k8s-master.dengnanhao.com k8s-master  |
| 2  | 192.168.150.134 | k8s-node1.dengnanhao.com k8s-node1    |
| 3  | 192.168.150.135 | k8s-node2.dengnanhao.com k8s-node2    |
| 4  | 192.168.150.136 | k8s-node3.dengnanhao.com k8s-node3    |
| 5  | 192.168.150.140 | k8s-register.dengnanhao.com k8s-register |

```bash 
#配置hosts文件
vim /etc/hosts
```

##### 跨主机免密码认证
```bash
#生成密钥对
ssh-keygen -t rsa
#复制到其他主机
for i in 134 135 136 140; 
do  ssh-copy-id root@192.168.150.$i; 
done
#跨主机免密码认证
ssh-copy-id root@远程主机ip地址

#配置其他主机hosts文件
for i in  134 135 136 140; 
do scp /etc/hosts root@192.168.150.$i:/etc/hosts;
done

#设置主机名
hostnamectl set-hostname k8s-master
exec /bin/bash

#设置其他主机主机名
ssh root@192.168.150.134 "hostnamectl set-hostname k8s-node1"
ssh root@192.168.150.135 "hostnamectl set-hostname k8s-node2"
ssh root@192.168.150.136 "hostnamectl set-hostname k8s-node3"
ssh root@192.168.150.140 "hostnamectl set-hostname k8s-register"

#查看主机名是否全部更改
for i in 131  134 135 136 140; 
do ssh root@192.168.150.$i "hostname"; 
done
```

##### swap环境配置（所有主机操作）

```bash
#查看是否有swap分区
cat /etc/fstab

#临时禁用
swapoff -a

#永久禁用
sed -i 's/.*swap.*/#&/' /etc/fstab

#内核参数调整
cat >> /etc/sysctl.d/k8s.conf << EOF
vm.swappiness=0
EOF
sysctl -p /etc/sysctl.d/k8s.conf

#配置其他主机
for i in  134 135 136 140; 
do ssh root@192.168.150.$i "swapoff -a;sed -i 's/.*swap.*/#&/' /etc/fstab;"; 
done
```

##### 网络参数调整（所有主机操作）
```bash
#配置iptables参数，使得流经网桥的流量也经过iptables/netfilter防火墙
cat >> /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

#配置生效
#(官方配置地址)[https://kubernetes.io/zh-cn/docs/setup/production-environment/container-runtimes/]
modprobe br_netfilter
modprobe overlay
sysctl -p /etc/sysctl.d/k8s.conf

#配置其他主机
for i in  134 135 136 140; 
do scp /etc/sysctl.d/k8s.conf root@192.168.150.$i:/etc/sysctl.d/k8s.conf;ssh root@192.168.150.$i "modprobe br_netfilter;modprobe overlay;sysctl -p /etc/sysctl.d/k8s.conf";
done

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
```

### 容器环境配置
(docker-ce安装教程)[https://developer.aliyun.com/mirror/]

**注意：所有主机操作**

1. 部署docker源文件
```bash
#定制软件源
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

#安装最新版docker
yum list docker-ce -showduplicates | sort -r
sudo yum -y install docker-ce
systemctl enable docker
systemctl start docker
```
2. docker加速器配置
3. cgroup drive调整为systemd
4. 私有镜像仓库
```bash
#配置加速器文件（register除外）
cat >> /etc/docker/daemon.json <<-EOF
{
  "registry-mirrors": [
    "http://74f21445.m.daocloud.io",
    "https://registry.docker-cn.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "insecure-registries": ["k8s-register.dengnanhao.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

#重启docker
systemctl restart docker
```

### cri-dockerd服务部署

**注意：所有主机操作**

1. 获取软件
```bash 
#下载软件
mkdir -p /data/softs && cd /data/softs
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.2/cri-dockerd-0.3.2.amd64.tgz

#解压软件
tar xf cri-dockerd-0.3.2.amd64.tgz
mv cri-dockerd/cri-dockerd /usr/local/bin/

#检查效果
cri-dockerd --version

#将cri-dockerd拷贝至register的所有机器
for i in 131 134 135 136
do scp cri-dockerd/cri-dockerd root@192.168.150.$i:/usr/local/bin/
done
```
2. 定制配置
```bash 
#定制配置文件
cat > /etc/systemd/system/cri-dockerd.service <<-EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
[Service]
Type=notify
ExecStart=/usr/local/bin/cri-dockerd --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9 
--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin --container-runtime-endpoint=unix:///var/run/cri-dockerd.sock --cri-dockerd-root-directory=/var/1ib/dockershim --docker-endpoint=unix:///var/run/docker.sock --cri-dockerd-root-directory=/var/lib/docker
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

#配置其他机器
for i in 131 134 135 136; 
do scp /etc/systemd/system/cri-dockerd.service root@192.168.150.$i:/etc/systemd/system/cri-dockerd.service; 
done
```

```bash 
#定制配置文件
cat > /etc/systemd/system/cri-dockerd.socket <<-EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service
[Socket]
ListenStream=/var/run/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF

#配置其他机器
for i in 131 134 135 136; 
do scp /etc/systemd/system/cri-dockerd.socket root@192.168.150.$i:/etc/systemd/system/cri-dockerd.socket; 
done
```

```bash 
#设置服务开机自启
systemctl daemon-reload
systemctl start cri-dockerd
systemctl enable cri-dockerd
systemctl is-active cri-dockerd

# 批量设置
for i in 131 134 135 136; do ssh root@192.168.150.$i "systemctl daemon-reload;systemctl start cri-dockerd;systemctl enable cri-dockerd;"; done
```

### harbor仓库操作

1. 准备工作
```bash 
#安装docker环境参考上面docker环境部署

#安装docker-compose 【register机器】
curl -SL https://github.com/docker/compose/releases/download/v2.17.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
docker-compose --version
```
2. 获取软件
```bash
#下载
mkdir -p /data/{softs,server} && cd /data/softs
wget https://ghproxy.com/https://github.com/goharbor/harbor/releases/download/v2.5.3/harbor-offline-installer-v2.5.3.tgz

#解压
tar -zxvf harbor-offline-installer-v2.5.3.tgz -C /data/server/
cd /data/server/harbor/

#加载镜像
docker load < harbor.v2.5.3.tar.gz
docker images

#备份配置
cp harbor.yml.tmpl harbor.yml
#修改harbor.yml文件
#1.域名地址
#2.https配置注释
#3.admin的默认密码
#4.数据卷挂在地址

#配置harbor
./prepare

#启动harbor
./install.sh

#检查效果
docker-compose ps 
```
3. 定制服务启动文件

```bash 
#定制服务启动文件 /etc/systemd/system/harbor.service
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=http://github.com/vmware/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
#需要注意harbor的安装位置
ExecStart=/usr/bin/docker-compose --file /data/server/harbor/docker-compose.yml up
ExecStop=/usr/bin/docker-compose --file /data/server/harbor/docker-compose.yml down
[Install]
WantedBy=multi-user.target
```

```bash 
#加载服务配置文件
systemctl daemon-reload
#启动服务
systemctl start harbor
#检查状态
systemctl status harbor
#设置开机自启动
systemctl enable harbor
```

4. harbor仓库定制
```bash 
#浏览器访问域名，用户名: admin，密码: 123456
#创建dengnanhao用户专用的项目仓库，名称为 dengnanhao，权限为公开的
```

5. harbor仓库测试

```bash 
#登录仓库
docker login k8s-register.dengnanhao.com -u dengnanhao
Password: #输入登录密码 A12345678a

#下载镜像
docker pull nginx

#定制镜像标签
docker tag nginx k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1

#推送镜像
docker push k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
```

### k8s集群初始化
大概步骤：软件源定制 -> 安装软件 -> 镜像获取 -> 主节点初始 -> 工作节点加入集群

1. 软件部署（master及node）
```bash 
#定制阿里云的关于kubernetes的软件源
cat > /etc/yum.repos.d/kubernetes.repo <<-EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
#更新软件源
yum makecache fast

#master环境软件部署 安装指定版本 yum install -y kubeadm-1.27.3
yum install -y kubelet-1.27.3 kubeadm-1.27.3 kubectl-1.27.3
#node环境软件部署
yum install -y kubelet-1.27.3 kubeadm-1.27.3 kubectl-1.27.3

#开机自启
systemctl enable kubelet && systemctl start kubelet
```
2. 确认基本配置
```bash 
#查看kubeadm版本
kubeadm version

#检查镜像文件列表
kubeadm config images list

#新建harbor仓库google_containers
#获取镜像文件
images=$(kubeadm config images list --kubernetes-version=1.27.3 | awk -F"/" '{print $NF}')
for i in ${images}
do
docker pull registry.aliyuncs.com/google_containers/$i
docker tag registry.aliyuncs.com/google_containers/$i k8s-register.dengnanhao.com/google_containers/$i
docker push k8s-register.dengnanhao.com/google_containers/$i
docker rmi registry.aliyuncs.com/google_containers/$i
done

# master节点初始化
#环境初始化命令
kubeadm init --kubernetes-version=1.27.3 \
--apiserver-advertise-address=192.168.150.131 \
--image-repository k8s-register.dengnanhao.com/google_containers \
--pod-network-cidr="10.244.0.0/16" \
--service-cidr="10.96.0.0/12" \
--ignore-preflight-errors=Swap \
--cri-socket=unix:///var/run/cri-dockerd.sock

#node节点初始化
#node节点加入集群(执行master节点的输出信息)
kubeadm join 192.168.150.131:6443 --token eyuhqa.o7syzuqltrq1n9mo \
--discovery-token-ca-cert-hash sha256:3fa6801f28e69450d242a0ded65e6dbfed37aa80fba50126b3189b3b2e854471 \
--cri-socket=unix:///var/run/cri-dockerd.sock

#master认证信息(执行master节点的输出信息)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#获取集群节点
kubectl get nodes
```
3.  终端tab键补全kubectl的命令
```bash 
#修改bash配置文件
vim .bashrc
#尾部追加
source <(kubectl completion zsh)
source <(kubeadm completion zsh)
#更新
source .bashrc
```
4.  打通网络
    
```bash 
#Flannel 是一个可以用于 Kubernetes 的 overlay 网络提供者。
mkdir /data/kubernetes/network/flannel -p
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

#查看kube-flannel.yml配置文件中的镜像
grep image: kube-flannel.yml

#下载其中的镜像并将其传入harbor
docker tag flannel/flannel:v0.22.2 k8s-register.dengnanhao.com/dengnanhao/flannel:v0.22.2
docker tag flannel/flannel-cni-plugin:v1.2.0 k8s-register.dengnanhao.com/dengnanhao/flannel-cni-plugin:v1.2.0

#推送镜像
docker push k8s-register.dengnanhao.com/dengnanhao/flannel:v0.22.2
docker push k8s-register.dengnanhao.com/dengnanhao/flannel-cni-plugin:v1.2.0

#修改kube-flannel.yml中的镜像地址
image: k8s-register.dengnanhao.com/dengnanhao/flannel-cni-plugin:v1.2.0
image: k8s-register.dengnanhao.com/dengnanhao/flannel:v0.22.2
#查看是否修改全
grep image: kube-flannel.yml

#运行配置文件
kubectl apply -f kube-flannel.yml
#查看节点
kubectl get nodes
```
**注意：`kubelet` `docker` `cri-dockerd`必须开机自启动**

5. node节点重新加入集群
```bash
#master删除节点
kubectl delete node k8s-node1

#node节点重置
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock

#master节点重新生成token
kubeadm token create --print-join-command



#查看节点
kubectl get nodes
```


## 应用部署
### 资源对象梳理
<img src="/images/k8s/source_object.png" alt="资源对象梳理"/>

### kubectl常见命令
<img src="/images/k8s/kubectl常见命令.png" alt="常见命令清单"/>

1. 基础命令
```bash 
#create
#expose
#run 在集群上运行特定镜像
#set 为对象设置指定特性

#explain 查看资源对象的相关属性
#get 显示一个或者多个资源对象
#edit 编辑资源对象
#delete 删除资源对象
```

2. 部署相关命令
```bash
#rollout 部署和回滚
#scale 扩缩容
```

3. 信息查看命令
```bash 
#describe 显示特定资源或资源组的信息（查看资源对象的创建过程）
#logs 打印pod中容器的日志
#exec 在某个容器中执行一个命令
#apply 基于资源对象文件把资源环境创建出来
```

### pod资源对象管理实践
创建pod的方式：命令方式、yaml清单文件方式
```bash 
#手工方式
kubectl run pod名称 --image=image地址:版本 #kubectl run pod nginx --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
#查看pod资源相关属性 可以看到pod在集群中的虚拟网络ip（此IP只能在集群内部访问)
kubectl get pod -o wide
#查看pod创建详情
kubectl describe pod nginx
#查看pod容器内部日志信息
kubectl logs nginx
#进入pod容器内部
kubectl exec -it nginx -- /bin/bash
```
```bash 
#资源清单方式
mkdir /data/kubernetes/pod -p
cd /data/kubernetes/pod
#查看pod资源清单文件（pod实际运行状态）
kubectl get pod nginx -o yaml 
#查看pod资源清单文件（预期状态）
kubectl run pod nginx --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1 --dry-run=client -o yaml 

#创建资源清单文件
kubectl run pod nginx --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1 --dry-run=client -o yaml >01_pod_create.yaml

#基于资源清单文件创建pod
kubectl apply -f 01_pod_create.yaml

#删除pod
kubectl delete -f nginx // 或者是 kubectl delete -f 01_pod_create.yaml 
#删除所有基于资源文件清单创建的pod ./资源清单的文件路径
kubectl delete -f ./ 
```
```bash 
#pod资源清单文件预期状态
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod
  name: pod
spec:
  containers:
  - args:
    - nginx
    image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
    name: pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
#修改资源清单文件（删除无关部分只保留最核心部分）
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx2
  name: nginx2
spec:
  containers:
  - image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
    name: nginx
```

### deployment资源对象管理实践
```bash 
#手动创建
kubectl create deployment nginx-deploy --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
#查看deployment
kubectl get deployment
#查看rs
kubectl get rs
#查看pod
kubectl get pod 
#删除deployment
kubectl delete deployments.apps nginx-deploy
```
!(deploy、rs以及pod之间的关联关系)[/images/k8s/deploy-rs-pod.png]

```bash 
#资源清单创建
#查看deployment资源清单文件
kubectl create deployment nginx-deploy --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1 --dry-run=client -o yaml
#保存deployment资源清单文件
kubectl create deployment nginx-deploy --image=k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1 --dry-run=client -o yaml > 02_pod_create.yaml
#基于deployment资源清单文件创建pod
kubectl apply -f 02_pod_create.yaml
```

```bash 
#deployment资源清单文件内容
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deploy
  name: nginx-deploy
spec:
  replicas: 1 #控制pod相关的数量
  selector:
    matchLabels:
      app: nginx-deploy #通过这个标签管理pod
  strategy: {}
  template:
    metadata:
      labels:
        app: nginx-deploy #pod标签
    spec:
      containers:
      - image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
        name: nginx
```
### 资源对象的扩缩容和修改
```bash 
#edit 直接在现有的资源对象基础上上修改xx属性（手工的需要进到资源清单文件中修改）
kubectl edit deployments.app nginx-deploy 

#scale直接动态调整数量
kubectl scale deployment nginx-deploy --replicas=10

#set  直接动态调整属性（如修改镜像属性）
kubectl set image deployment nginx-deploy nginx(原镜像)=mysql:8.0.25
```

### 命名空间namespace
k8s平台上的一个独立的小房间，每个房间的资源都是相互独立的

```bash
#查看所有命名空间
kubectl get ns
#查看命名空间下的pod
kubectl get pod -n kube-flannel
#查看创建命名空间的资源文件
kubectl create namespace test-ns --dry-run=client -o yaml
```

```yaml 
#命名空间资源文件
apiVersion: v1
kind: Namespace
metadata:
  name: test-ns
--- #短横杠的目的是在一个资源清单文件中可以添加多个资源对象属性
```
```bash
#将pod资源对象添加至namespace资源对象文件中
cat 01_pod_create.yaml >> 03_ns_create.yaml
```
<img src="/images/k8s/add-ns.png" />

```bash 
#创建命名空间
kubectl apply -f 03_ns_create.yaml
```

## 应用访问
Service资源对象的作用将外部的流量，引入到pod里面。关键点是通过label来引入的。service地址是一个虚拟的 cluster ip，k8s集群外部的主机是无法访问的。
<img src="/images/k8s/service.png" />
### 集群外部访问集群内部pod
#### 创建service
1. 命令方式
```bash 
#创建service
kubectl expose deployment nginx-deploy --port=80
#查看service
kubectl get svc 
#查看svc创建细节
kubectl describe svc nginx-deploy
```
2. yaml清单文件方式
```bash 
#创建service清单资源文件yaml
kubectl expose deployment nginx-deploy --port=8080 --dry-run=client -o yaml > 01_service_create.yaml
```
```bash 
#service资源清单文件
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx-deploy
  name: nginx-deploy
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: nginx-deploy
```
```bash 
#执行清单文件
kubectl apply -f 01_service_create.yaml
#查看service
kubectl get svc 
```

### 外部服务解析
如何让k8s内部的应用访问k8s集群外部的服务？
<img src="/images/k8s/service2.png">

1. 部署外部集群
2. 创建endpoint
3. 创建service
4. pod测试

### 集群内部pod访问外部service
#### 创建外部service
部署外部mysql环境
```bash
#准备软件源
#cat /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseur1 = http://yum.mariadb .org/10.3/centos7-amd64
gpgcheck=0

#更新系统软件包
yum makecache fast
#安装mysql服务
yum install -y mariadb-server mariadb
#设置mysql服务开机自启
systemctl enable mariadb && systemctl start mariadb

#开启mysql远程访问
#vim /etc/my.cnf.d/server.cnf
[mysqld]
bind-address = 0.0.0.0

#重启mysql服务
systemctl restart mariadb

#配置远程主机登录权限
mysql_secure_installation #设置root密码

mysql -uroot -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;"
mysql -uroot -p123456 -e "FLUSH PRIVILEGES;"

#创建数据库
mysq] -uroot -p123456 -e "
CREATE DATABASE books default charset utf8 collate utf8_general_ci;
USE books;
CREATE TABLE book_info (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_name VARCHAR(100),
    author VARCHAR(100),
    date_of_issue DATE,
    isDelete BOOLEAN
);
INSERT INTO book_info (book_name, author, date_of_issue, isDelete) VALUES
('Book 1', 'Author 1', '2022-01-01', FALSE),
('Book 2', 'Author 2', '2022-02-01', FALSE),
('Book 3', 'Author 3', '2022-03-01', TRUE);
"
```
#### 服务镜像
```bash
#创建Dockerfile
# build
ARG target_arch=x86
FROM golang:1.20.0 as build

RUN mkdir -p /k8s/service
WORKDIR /k8s/service

ADD . .

ENV GOPROXY=http://192.168.1.41:4000
RUN env && go vet ./...
RUN go build -trimpath -o gin-html-temp-service

#CMD ["/k8s/service/gin-html-temp-service"]

# runtime
FROM centos:7
RUN mkdir -p /k8s/bin
WORKDIR /k8s
COPY --from=build /k8s/service/gin-html-temp-service /k8s/bin/gin-html-temp-service

ENV GOGC=200
CMD ["/k8s/bin/gin-html-temp-service"]

#构建镜像
docker build -t k8s-register.dengnanhao.com/dengnanhao/gin-html-temp-service:v1.0.0 .
#推送镜像
docker push k8s-register.dengnanhao.com/dengnanhao/gin-html-temp-service:v1.0.0
```
#### 定制资源清单文件
```bash

```

## 应用数据
k8s中使用volumes来存储应用数据，volumes是一个目录或者磁盘分区，可以被容器中的应用程序使用。volumes的生命周期和pod的生命周期一致，当pod被删除时，volumes也会被删除。常用的volumes类型有emptyDir、hostPath、nfs、configMap、secret、persistentVolumeClaim等。

### emptyDir
emptyDir是k8s中最简单的volumes类型，它是一个空目录，可以被容器中的应用程序使用。emptyDir的生命周期和pod的生命周期一致，当pod被删除时，emptyDir也会被删除。emptyDir的使用场景是在pod中创建临时文件，比如在pod中创建一个临时的缓存目录。
1. 案例实践
```bash 
#创建pod
apiVersion: v1
kind: Pod
metadata:
  name: dengnanhao-emptydir
  namespace: default
spec:
  containers:
    - name: nginx-web
      image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.2
      ports:
      - containerPort: 8080
      volumeMounts:
      - name: nginx-index
        mountPath: /usr/share/nginx/html
    - name: change-index
      image: k8s-register.dengnanhao.com/dengnanhao/busybox:1.33.1
      #每过2s更改一下文件内容
      command: ["/bin/sh", "-c", "for i in $(seq 100); do echo index-$i > /testdir/index.html; sleep 2; done"]
      volumeMounts:
      - name: nginx-index
        mountPath: /testdir
  volumes:
  - name: nginx-index
    emptyDir: {}
```

2. curl pod地址查看nginx网页内容
### hostPath
hostPath是k8s中最简单的volumes类型，它是一个宿主机的目录，可以被容器中的应用程序使用。hostPath的使用场景是在pod中使用宿主机的目录，比如在pod中使用宿主机的日志目录。
1. 案例实践
```bash
#创建pod
apiVersion: v1
kind: Pod
metadata:
  name: dengnanhao-hostpath
  namespace: default
spec:
  volumes:
  - name: redis-backup
    hostPath:
      path: /data/backup/redis
  containers:
    - name: hostpath-redis
      image: k8s-register.dengnanhao.com/dengnanhao/redis:7.0.4
      volumeMounts:
        - name: redis-backup
          mountPath: /data
```
2. 进入pod查看设置并保存redis数据
```bash
kubectl exec -it dengnanhao-hostpath -- /bin/bash
redis-cli
set name dengnanhao
get name
BGSVAE
```
3. 到pod对应节点查看redis数据
```bash
#查看pod所在节点
kubectl get pod dengnanhao-hostpath -o wide
```
### PV
### PVC

## 应用配置
配置文件的引入：
 - 从程序代码中把配置文件独立出来
 - 将配置文件形成资源对象 cm
 - 将cm对象引入到pod里面 以volumes样式存在
 - 容器挂载volumes到应用程序代码的特定目录下
 - 程序正常启动
### configMap
<img src="/images/k8s/k8s-configmap.png" width="40%" alt="configmap"/>

1. 案例实践
```bash
#根据deployment创建nginx pod
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dengnanhao-nginx
  name: dengnanhao-nginx
spec:
  replicas: 1 #控制pod相关的数量
  selector:
    matchLabels:
      app: dengnanhao-nginx #通过这个标签管理pod
  strategy: {}
  template:
    metadata:
      labels:
        app: dengnanhao-nginx #pod标签
    spec:
      containers:
      - image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.1
        name: nginx
```

```bash
#根据deployment创建tomcat pod资源清单文件
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: dengnanhao-tomcat
  name: dengnanhao-tomcat
spec:
  replicas: 1 #控制pod相关的数量
  selector:
    matchLabels:
      app: dengnanhao-tomcat #通过这个标签管理pod
  strategy: {}
  template:
    metadata:
      labels:
        app: dengnanhao-tomcat #pod标签
    spec:
      containers:
      - image: k8s-register.dengnanhao.com/dengnanhao/tomcat:10.1.14
        name: tomcat
```
```bash
#创建nginx、tomcat service资源清单文件
apiVersion: v1
kind: Service
metadata:
  labels:
    app: dengnanhao-nginx
  name: dengnanhao-nginx-svc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: dengnanhao-nginx
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: dengnanhao-tomcat
  name: dengnanhao-tomcat-svc
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: dengnanhao-tomcat
```

```bash
#创建configmap资源清单文件
apiVersion: v1
kind: ConfigMap
metadata:
  name: dengnanhao-nginxconf
data:
  default.conf: |
    server {
      listen       80;
      server_name  www.dengnanhao.com;
      location /nginx {
        proxy_pass http://dengnanhao-nginx-svc/;
      }
      location /tomcat {
        proxy_pass http://dengnanhao-tomcat-svc:8080/;
      }
      location / {
        root   /usr/share/nginx/html;
      }
    }
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: dengnanhao-nginx-index
data:
  index.html: "hello nginx, this is nginx web page by dengnanhao\n"
```
```bash
#创建nginx-proxy应用资源清单文件
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dengnanhao-nginx-proxy
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.2
        volumeMounts:
        - name: nginxconf
          mountPath: /etc/nginx/conf.d
          readOnly: true
        - name: nginxindex
          mountPath: /usr/share/nginx/html
          readOnly: true
      volumes:
        - name: nginxconf
          configMap:
            name: dengnanhao-nginxconf
        - name: nginxindex
          configMap:
            name: dengnanhao-nginx-index
```
```bash
#创建nginx-proxy service资源清单文件
kubectl expose deployment dengnanhao-nginx-proxy --port=80 --dry-run=client -o yaml 

apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: dengnanhao-nginx-proxy-svc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
```

### secret
配置文件的引入：
  - 制作证书，并将证书文件生成secret对象
  - 根据配置文件创建cm资源对象
  - 将cm对象及secret对象引入到pod里面 以volumes样式存在
  - 容器挂载volumes到应用程序代码的特定目录下
  - 程序正常启动
1. 定义配置文件
```bash
#准备nginx容器的配置目录
mkdir tls-key
#做证书
openssl genrsa -out tls-key/tls.key 2048
#做成自签证书
openssl req -new -x509 -key tls-key/tls.key -out tls-key/tls.crt -subj "/CN=www.dengnanhao.com"
```

```bash
#定制专属nginx配置文件 nginx-conf-tls/default.conf
server {
  listen       443 ssl;
  server_name  www.dengnanhao.com;
  ssl_certificate /etc/nginx/certs/tls.crt;
  ssl_certificate_key /etc/nginx/certs/tls.key;
  location / {
    root   /usr/share/nginx/html;
  }
}

server {
  listen       80;
  server_name  www.dengnanhao.com;
  return 301 https://$host$request_uri;
}
```
2. 手动创建资源对象文件
```bash
#基于配置文件创建cm资源对象
kubectl create configmap nginx-ssl-conf --from-file=nginx-conf-tls/

#创建secret资源对象
kubectl create secret tls nginx-ssl-secret --cert=tls-key/tls.crt --key=tls-key/tls.key

#定制资源清单文件
apiVersion: v1
kind: Pod
metadata:
  name: dengnanhao-nginx-ssl
spec:
  containers:
  - image: k8s-register.dengnanhao.com/dengnanhao/nginx:1.25.2
    name: nginx
    volumeMounts:
    - name: nginxcerts
      mountPath: /etc/nginx/certs/
      readOnly: true
    - name: nginxconfs
      mountPath: /etc/nginx/conf.d/
      readOnly: true
  volumes:
    - name: nginxcerts
      secret:
        secretName: nginx-ssl-secret
    - name: nginxconfs
      configMap:
        name: nginx-ssl-conf
```
## 服务访问
### ingress
<img src="/images/k8s/ingress.png" width="40%" />

#### ingress部署
1. 环境部署
```bash
# 获取配置文件
cd /data/kubernetes; mkdir ingress; cd ingress
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/baremetal/deploy.yaml
mv deploy.yaml ingress-deploy.yaml
cp ingress-deploy.yaml ingress-deploy.yaml.bak
```

```bash
#默认ingress-deploy.yaml中的镜像文件
]#grep image: ingress-deploy.yaml | awk -F '/|@' '{print $(NF-1)}' | uniq
controller:v1.3.1
kube-webhook-certgen:v1.3.0
#下载国内阿里云镜像并提交到私有仓库
for i in nginx-ingress-controller:v1.3.1 kube-webhook-certgen:v1.3.0
do 
  docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/$i 
  docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/$i k8s-register.dengnanhao.com/google_containers/$i 
  docker push k8s-register.dengnanhao.com/google_containers/$i 
  docker rmi registry.cn-hangzhou.aliyuncs.com/google_containers/$i
done
#注意：controller的名称是需要更改以下的，因为阿里云的镜像名称多了一个标识
```

```bash
#修改基础镜像
]#grep image: ingress-deploy.yaml
image: registry.k8s.io/ingress-nginx/controller:v1.3.1@sha256:54f7fe2c6c5a9db9a0ebf1131797109bb7a4d91f56b9b362bde2abd237dd1974
image: registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.3.0@sha256:549e71a6ca248c5abd51cdb73dbc3083df62cf92ed5e6147c780e30f7e007a47
image: registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.3.0@sha256:549e71a6ca248c5abd51cdb73dbc3083df62cf92ed5e6147c780e30f7e007a47

#将ingress-deploy.yaml中的镜像替换为私有仓库中的镜像
image: k8s-register.dengnanhao.com/google_containers/nginx-ingress-controller:v1.3.1
image: k8s-register.dengnanhao.com/google_containers/kube-webhook-certgen:v1.3.0
image: k8s-register.dengnanhao.com/google_containers/kube-webhook-certgen:v1.3.0
```

```bash
#开放访问入口地址
]# vim ingress-deploy.yaml
...
334 apiVersion: v1
335 kind: Service
...
344 namespace: ingress-nginx
345 spec:
    ...
348   ipFamilyPolicy: SingleStack
349   externalIPs: ['192.168.98.131'] #限制集群外部访问的ip
350   ports:
351   - appProtocol: http
352     name: http
353     port: 80
...
628   failurePolicy: Ignore  #为了避免默认的准入控制限制，需要将failurePolicy设置为Ignore
```

```bash
]# kubectl apply -f ingress-deploy.yaml

#确认效果
]# kubectl get all -n ingress-nginx
pod/ingress-nginx-admission-create-fxlh5        0/1     Completed   0          5m41s
pod/ingress-nginx-admission-patch-rcdhd         0/1     Completed   0          5m41s
pod/ingress-nginx-controller-8566d47ff7-rq599   1/1     Running     0          5m41s
```

#### ingress实践
```bash
#定制资源清单文件
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dengnanhao-nginx-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: www.dengnanhao.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: dengnanhao-nginx-proxy-svc
            port:
              number: 80
```

```bash
#注释信息表明ingress是哪种环境
#对于k8s的1.24+，该属性默认被忽略，换成了spec.ingressClassName
annotations:
    kubernetes.io/ingress.class: "nginx"
    
#查看k8s资源对象有哪些属性
]# kubectl explain ingress.spec

#查看ingress的详细信息
]# kubectl describe ingress dengnanhao-nginx-ingress

#查看ingress的访问地址
]# kubectl get svc -n ingress-nginx

#注意：如果访问ingress使用IP地址，访问会失败，必须带上请求头host:www.dengnanhao.com
]# curl -H "host:www.dengnanhao.com" 192.168.98.131
```

## helm管理
### helm简介
helm的功能类似于yum/apt，提供应用部署时候所需要的各种配置、资源对象文件，他与yum工具不同的是，在k8s中helm是不提供镜像的，镜像需要专门的镜像仓库提供，helm只是提供了一种应用部署的方式，可以将应用的配置、资源对象文件打包成一个helm包，然后通过helm工具进行安装、卸载、升级等操作。
例如：k8s平台上的nginx应用部署，需要三类内容：1、nginx镜像；2、nginx的资源对象文件，Deployment/service/hpa等；3、专用文件，配置文件及证书等；helm管理的是资源定义文件及专用文件。

### helm v2版本
<img src="/images/k8s/helm-v2.png" width="80%" />

基于helm来成功的部署一个应用服务，完整的工作流程如下

- 部署一个稳定运行的k8s集群，在能管理k8s的主机上部署helm。
- 用户在客户端主机上，定制各种Chart资源和config资源，上传到专用的仓库(本地或者远程)。
- helm客户端向Tiller发出部署请求，如果本地有chart用本地的，否则从仓库获取。
- Tiller与k8s集群的api-server发送请求。
- api-server通过集群内部机制部署应用，需要依赖镜像的时候，从专门的镜像仓库获取。
- 基于helm部署好的应用实例，在k8s集群中，我们称之为release。

### helm v3版本

<img src="/images/k8s/helm-v2.png" width="80%" />

在客户端部署tiller来维护release相关的信息太重量级了，helm v3版本将tiller从客户端移除，将release相关的信息存储到k8s集群中，这样就不需要在客户端部署tiller了，helm v3版本的工作流程如下

- 部署一个稳定运行的k8s集群，在能管理k8s的主机上部署helm。
- 用户在客户端主机上，定制各种Chart资源和config资源，上传到专用的仓库(本地或者远程)。
- helm客户端向k8s集群的api-server发送部署请求。
- api-server通过集群内部机制部署应用，需要依赖镜像的时候，从专门的镜像仓库获取。
- 基于helm部署好的应用实例，在k8s集群中，我们称之为release。

### helm部署
1. 软件部署
```bash
#下载helm软件包
cd /data/softs
wget https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz

#配置环境
mkdir /data/server/helm/bin -p
tar -zxvf helm-v3.13.0-linux-amd64.tar.gz
mv linux-amd64/helm /data/server/helm/bin

#配置环境变量
vim /etc/profile.d/helm.sh
# !/bin/bash
# set helm env
export PATH=$PATH:/data/server/helm/bin

chmod +x /etc/profile.d/helm.sh
source /etc/profile.d/helm.sh

#查看helm版本
]# helm version
```
2. 命令帮助
```bash
helm --help

Common actions for Helm:

- helm search:    search for charts
- helm pull:      download a chart to your local directory to view
- helm install:   upload the chart to Kubernetes
- helm list:      list releases of charts
...
```
### helm仓库
1. 仓库管理
```bash
#添加仓库
helm repo add az-stable http://mirror.azure.cn/kubernetes/charts/
helm repo add bitnami https://charts.bitnami.com/bitnami

#查看仓库
]# helm repo list

#更新仓库属性信息
helm repo update
```

```bash
#搜索chart信息
]# helm search --help
Available Commands:
  hub         search for charts in the Artifact Hub or your own hub instance #无法访问
  repo        search repositories for a keyword in charts

#从自定义仓库中获取chart
helm search repo nginx

#查看chart的详细信息
helm show all bitnami/nginx
```

redis实践

```bash 
#安装chart
helm install my-redis bitnami/redis

#删除应用
helm uninstall my-redis

#更新应用
helm upgrade my-redis bitnami/redis --set master.persistence.enabled=false --set replica.persistence.enabled=false

#查看应用
helm list
helm get pod
```

### helm应用实践
```bash

```