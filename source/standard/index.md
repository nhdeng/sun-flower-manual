title: 前端规范
---
# 前端规范
制定该规范的目的在于建立一套统一的标准和规则，以指导团队成员在前端开发过程中的工作，提高代码质量、可维护性和可扩展性，增强团队协作效率，并降低项目出错的风险。规范包含以下几个内容：

1. 技术栈规范
2. 命名规范
3. 编码规范
4. 代码提交规范
5. 前后端协作规范
6. UI设计规范
7. CodeReview规范

## 技术栈规范

WEB端
1. 一律使用[Typescript](https://www.typescriptlang.org/)进行编码
2. [前端框架React](https://react.dev/)
3. [UI组件库 Antd Design](https://ant.design/index-cn/)
4. CSS框架选用[Tailwind CSS](https://tailwindcss.com/)，Tailwind CSS 的优势在于其高度可定制性、简化开发流程、响应式设计且上手简单
5. 构建工具[Vite](https://cn.vitejs.dev/)，特点是上手简单，构建速度快，开发效率高
6. 状态库选用[Redux Toolkit](https://redux-toolkit.js.org/)
7. 包管理工具选用`pnpm`
8. ...

小程序
1. 一律使用微信官方提供的[小程序](https://developers.weixin.qq.com/miniprogram/dev/framework/)开发方式，没有多端适配需求，请勿使用三方的多端框架如：[uni-app]()、[taro]()
2. 一律使用[Typescript](https://www.typescriptlang.org/)进行编码
3. CSS样式库使用[weui](https://github.com/Tencent/weui-wxss/)官方推荐
4. ...

Node项目
1. [koa框架](https://koa.bootcss.com/)
2. ORM使用[Sequelize](https://sequelize.org/)
3. 包管理工具选用`pnpm`
4. ...

## 命名规范
文件资源命名
1. 文件名不得含有空格
2. 组件（component）及页面（page）文件/文件夹全部使用大驼峰（eg:MyHeader），其余文件使用小驼峰（eg:useTheme）。

```bash
# 目前项目采用的文件命名示例
src/
├── components/
│   ├── MyHeader.tsx
│   └── MyFooter.tsx
├── pages/
│   ├── Home.tsx
│   ├── About.tsx
│   └── Widget/
│       ├── components/
│       │   ├── Tool.tsx
│       │   └── Option.tsx
│       ├── helpers/
│       │   └── setOptionStorage.ts
│       ├── Widget.tsx
│       └── index.ts
├── hooks/
│   └── useTheme.ts
├── utils/
│   └── getRamdomNumber.ts
└── constants.ts
```

变量命名
1. 命名方式: 采用小驼峰式命名方法
2. 命名规范: 普通变量(number, string, date);布尔类型：需要一个标识变量含义的前缀，比如has, is, wether, can, should等;数组/集合等复数形式：最好以s或list等能够标识复数形式的后缀结尾，标识当前变量是复数形式，提高可读性；
3. 常量全部大写，且用下划线来分割单词，eg：MAX_LENGTH = 1

函数命名
1. 命名方式 : 小驼峰方式 ( 构造函数使用大驼峰命名法 )
2. 命名规则 : 前缀为动词，动词 eg：add / update / delete / detail / get
```ts
// 更新数据
function updateData(){
    return {};
}

// 获取用户信息
function getUserInfo(){
    return {}
}
```
```bash
# 函数方法常用的动词: 
get 获取/set 设置, 
add 增加/remove 删除, 
create 创建/destory 销毁, 
start 启动/stop 停止, 
open 打开/close 关闭, 
read 读取/write 写入, 
load 载入/save 保存,
begin 开始/end 结束, 
backup 备份/restore 恢复,
import 导入/export 导出, 
split 分割/merge 合并,
inject 注入/extract 提取,
attach 附着/detach 脱离, 
bind 绑定/separate 分离, 
view 查看/browse 浏览, 
edit 编辑/modify 修改,
select 选取/mark 标记, 
copy 复制/paste 粘贴,
undo 撤销/redo 重做, 
insert 插入/delete 移除,
add 加入/append 添加, 
clean 清理/clear 清除,
index 索引/sort 排序,
find 查找/search 搜索, 
increase 增加/decrease 减少, 
play 播放/pause 暂停, 
launch 启动/run 运行, 
compile 编译/execute 执行, 
debug 调试/trace 跟踪, 
observe 观察/listen 监听,
build 构建/publish 发布,
input 输入/output 输出,
encode 编码/decode 解码, 
encrypt 加密/decrypt 解密, 
compress 压缩/decompress 解压缩, 
pack 打包/unpack 解包,
parse 解析/emit 生成,
connect 连接/disconnect 断开,
send 发送/receive 接收, 
download 下载/upload 上传, 
refresh 刷新/synchronize 同步,
update 更新/revert 复原, 
lock 锁定/unlock 解锁, 
check out 签出/check in 签入, 
submit 提交/commit 交付, 
push 推/pull 拉,
expand 展开/collapse 折叠, 
enter 进入/exit 退出,
abort 放弃/quit 离开, 
obsolete 废弃/depreciate 废旧, 
collect 收集/aggregate 聚集
```

## CSS规范
1. 项目中统一使用TailWind，className中必须使用TailWind样式，优先使用Tailwind必要时可以使用style行内样式


## React编码规范
编码规范的意义在于提高代码的可读性，降低维护成本，提高开发效率。在编码规范中，约定一些代码的书写规则，比如命名规范、注释规范等等。这些规则都是为了让代码更加规范，便于团队协作开发，提高代码的可读性。工程中也会引入一些代码检查工具，`eslint`、`stylelint`及`prettier`，来检查代码是否符合规范，如果不符合规范，会在编译阶段报错，及时发现问题。

1. 只允许使用Functional Component来编写组件，配合Hooks进行开发；
2. 如果**页面**是一个目录，则页面主入口命名为 index.tsx。如果**组件**是一个目录，则组件主入口命名为 index.ts在index.ts中导出所有外部需要引用的变量及方法。
```ts
// 组件导出示例
// bad
import Footer from './Footer/Footer'

// bad
import Footer from './Footer/index'

// good
import Footer from './Footer'
```

3. import 顺序

    在规范前的引入是无序的，一个文件可能会很乱，但是当你打开大量文件时候，尝试找到一个特定的包真的很难。使用规范之后的方式对导入的包进行分组，通过 空格行分割 每个模块。又因为所有文件将保持一致，就可以删除注释了。
```tsx
// bad
import React, { useEffect, useState, useRef } from 'react';
import { saleRefund } from '@/services/api';
import { PageContainer } from '@ant-design/pro-layout';
import type { ProColumns, ActionType } from '@ant-design/pro-table';
import ProTable from '@ant-design/pro-table';
import SellMode from './components/SellMode';
import ViewDetails from './components/viewDetails';
import BillingMsg from './components/billingMsg';
import RefundMsg from './components/refundMsg';
import Tab from '@/assets/images/tab.png';
import { formatTime } from '@/utils/utils';
import { getListActiveVersion } from './utils/index';
import { showErrorMessage } from '@/mamagement/Notification';
import styles from "./index.less";
```

```tsx 
// good

// node_modules
import React, { useEffect, useState, useRef } from 'react';
import { PageContainer } from '@ant-design/pro-layout';
import type { ProColumns, ActionType } from '@ant-design/pro-table';
import ProTable from '@ant-design/pro-table';

// 项目公共模块
import { formatTime } from '@/utils/utils';
import { showErrorMessage } from '@/mamagement/Notification';
import { saleRefund } from '@/services/api';

// 当前业务耦合模块
import { getListActiveVersion } from './utils/index';
import SellMode from './components/SellMode';
import ViewDetails from './components/viewDetails';
import BillingMsg from './components/billingMsg';
import RefundMsg from './components/refundMsg';

// 图片、字体等资源
import Tab from '@/assets/images/tab.png';

// 样式文件
import styles from "./index.less";
```

4. 尽可能使用解构，防止不必要的嵌套和重复（将对象的属性值保存为局部变量）。
* 对象成员嵌套越深，读取速度也就越慢。所以好的经验法则是：如果在函数中需要 多次 读取一个对象属性，最佳做法是将该属性值保存在局部变量中，避免多次查找带来的性能开销（对象变量避免嵌套过深）
* 函数参数越少越好，如果参数超过两个，要使用 ES6 的解构语法，这样就不用考虑参数的顺序了
* 使用参数默认值 替代使用条件语句进行赋值

```tsx
//bad
const Page = (deliveryCompany, carrierName, driverInfo, driverInfo) => {
  return (
        <Descriptions.Item label="供应商">{deliveryCompany || '未知'}</Descriptions.Item>
        <Descriptions.Item label="承运商">{carrierName || '未知'}</Descriptions.Item>
        <Descriptions.Item label="司机">{driverInfo.driver || '未知'}</Descriptions.Item>
        <Descriptions.Item label="联系方式">{driverInfo.contact || '未知'}</Descriptions.Item>
  );
}
```
```tsx
//good
const defaultValue = '未知';
const Page = dataDetail => {
  const {
    deliveryCompany = defaultValue,
    carrierName = defaultValue,
    driverInfo = { driver: defaultValue, contact: defaultValue },
  } = props;

  const { driver, contact } = driverInfo;

  return (
        <Descriptions.Item label="供应商">{deliveryCompany}</Descriptions.Item>
        <Descriptions.Item label="承运商">{carrierName}</Descriptions.Item>
        <Descriptions.Item label="司机">{driver}</Descriptions.Item>
        <Descriptions.Item label="联系方式">{contact}</Descriptions.Item>
  );
}
```
5. 删除弃用代码

   很多时候有些代码已经没有用了，但是没有及时去删除，这样导致代码里面包括很多注释的代码块，好的习惯是提交代码前记得删除已经确认弃用的代码。
```tsx
// bad

// queryUserInfo();
newQueryUserInfo();
```

```tsx
// good
newQueryUserInfo();
```
6. 保持必要的注释

    代码注释不是越多越好，保持必要的业务逻辑注释，至于函数的用途、代码逻辑等，要通过语义化的命令、简单明了的代码逻辑，来让阅读代码的人快速看懂。
7. 遵守 Hooks 规则

   不要在 循环、条件 和 嵌套函数 内调用 Hooks。当你想有条件地使用某些 Hooks 时，请在这些 Hooks 中写入条件。
```tsx
//bad

if (name !== "") {
  useEffect(function persistForm() {
    localStorage.setItem("formData", name);
  });
}
```
```tsx
//good
useEffect(function persistForm() {
    if (name !== "") {
        localStorage.setItem("formData", name);
    }
});
```

8. 使用 useContext 避免 prop drilling

   prop-drilling 是 React 应用程序中的常见问题，指的是将数据从一个父组件向下传递，经过各层组，直到到达指定的子组件，而其他嵌套组件实际上并不需要它们。 React Context 是一项功能，它提供了一种通过组件树向下传递数据的方法，这种方法无需在组件之间手动传 props。父组件中定义的 React Context 的值可由其子级通过 useContext Hook 访问。
9. 组件名称和定义该组件的文件名称建议要保持一致。
```tsx
//bad
import FooterComponent from "./Footer";
```

```tsx
//good
import Footer from "./Footer";
```
10. JSX 的 属性 都采用 双引号，其他的 JS 都使用 单引号 ，因为 JSX 属性不能包含转义的引号, 所以当输入 "don't" 这类的缩写的时候用双引号会更方便。
```tsx
//bad
<Foo bar='bar' />

<Foo style={{ left: "20px" }} />
```
```tsx
//good
<Foo bar="bar" />

<Foo style={{ left: '20px' }} />
```
11. 为你的组件接收公共变量做好准备
```tsx
//bad
const UserInfo = (props) => {
    const { name, gender, age } = props;
    return (
        <div>
            <div>姓名:{name}</div>
            <div>性别:{gender}</div>
            <div>年龄:{age}</div>
        </div>
    );
};
```

```tsx
//good
const UserInfo = (props) => {
    const { name, gender, age, ...rest } = props;
    return (
        <div {...rest}>
            <div>姓名:{name}</div>
            <div>性别:{gender}</div>
            <div>年龄:{age}</div>
        </div>
    );
};
```
12. 组件遵循单一职责原则

    组件遵循单一职责原则（Single Responsibility Principle）可以让你轻松创建和贡献代码，并保持代码库的整洁。即容器组件与傻瓜组件。
* 容器组件负责数据的请求与获取，props/state 的更新
* 傻瓜组件只负责接收 props，抛出事件
13. 使用参数默认值

    使用参数默认值 替代 使用条件语句进行赋值。
```tsx
//bad
function createMicrobrewery(name) {
    const breweryName = name || "Hipster Brew Co.";
    // ...
}
```
```tsx
//good
function createMicrobrewery(name = "Hipster Brew Co.") {
    // ...
}
```
14. 页面跳转数据传递

    页面跳转，例如 A 页面跳转到 B 页面，需要将 A 页面的数据传递到 B 页面，参数个数小于等于三个时，推荐使用 路由参数 进行传参，而不是将需要传递的数据保存内存，然后在 B 页面取出内存的数据，因为如果在 B 页面刷新会导致内存数据丢失，导致 B 页面无法正常显示数据。如果参数是个对象或者超过三个以上时，推荐在A页面将参数加密缓存在浏览器的sesstionStore中，在B页面取出解密使用
15. 变量声明

    常量必须以`const`进行声明，变量必须使用`let`进行声明
```tsx
// bad
var WATERMARK_TYPE = 1
let WATERMARK_TYPE = 1
var type = 2

// good
const WATERMARK_TYPE = 1
let type = 2
```
16. 非驱动视图的变量不要使用Hooks来进行声明
    如果一个变量仅仅是组件内部的局部变量，不会影响组件的状态或行为，或者不需要在多个组件间共享，那么它可以直接在函数组件中声明，而不使用 Hooks

```tsx
// bad
const App:React.FC = () => {
    const [flag, setFlag] = useState(true)
    const [name, setName] = useState('dnh')
    const onChange = () => {
        setName(flag ? 'dnh' : 'mj')
        setFlag(!flag)
    }
    return <div>
    <span>{name}</span>    
    <button onCLick={() => onChange()>change</button>
    </div>
}

// good
let flag = true
const App:React.FC = () => {
    const [name, setName] = useState('dnh')
    const onChange = () => {
        setName(flag ? 'dnh' : 'mj')
        flag = !flag
    }
    return <div>
    <span>{name}</span>    
    <button onCLick={() => onChange()>change</button>
    </div>
}
```

## 代码提交规范
前端代码提交规范是在公司[研发仓库管理](https://wiki.gwlocal.com/pages/viewpage.action?pageId=31360745)基础之上新增的内容，如果对公司[研发仓库管理](https://wiki.gwlocal.com/pages/viewpage.action?pageId=31360745)内容不了解的话请先移步至[研发仓库管理](https://wiki.gwlocal.com/pages/viewpage.action?pageId=31360745)进行阅读
1. web端代码提交时会通过`Husky`+`lint-staged`在 Git commit 时进行代码校验，如果代码不符合ESlint相关规则代码将不能提交成功，请根据控制台提示修改代码中不符合规范的地方，修改完毕之后再次进行提交。
2. web端代码提交时会通过`commitlint`对提交信息进行校验, 所有commit信息必须符合以下格式：

```bash
<type>(<scope>): <subject>
```
其中<type> 表示提交的类型，<scope> 表示影响的范围（可选），<subject> 是提交的简要描述。

常见的 <type> 类型有：

- feat: 新功能（feature）
- fix: 修复 Bug
- docs: 文档更新
- style: 样式调整，不涉及代码逻辑变化
- refactor: 代码重构
- test: 添加或修改测试代码
- chore: 构建过程或辅助工具的变动
- perf: 性能优化

```bash
#示例
style(button): 添加loading样式
```

## 前后端协作规范

前后端协作规范在一个项目中具有重要的意义，它有助于确保整个开发团队能够高效协作，减少沟通成本，提高项目的质量和成功交付的概率。
1. 协作规范的流程
   - 需求分析。确保大家对需求有一致的认知；
   - 设计接口文档。由前端开发者拟出前段需要的接口及字段，服务之间调用的接口及字段由后端开发者自行拟定；
   - 并行开发。前端需要根据接口文档使用YAPI进行Mock, 模拟对接后端接口；联调之前，要求后端做好接口测试；
   - 真实环境联调。前端将接口请求代理到后端服务，进行真实环境联调；

2. 接口规范
   - 接口返回的数据格式必须是JSON格式，其中返回值`code`值为0代表请求服务端成功，非0代表请求异常；
   ```json
   {
    "code": 0,
    "message": "success",
    "data": {
        "name": "dnh",
        "age": 18
    }
   }
   ```
   - 请求方法统一使用`POST`/`GET`，暂不使用restful接口规范；
   - 接口URL结尾不包含`/`；
   - 正斜杆`/`分隔符必须用来指示层级关系；
   - 不得在URI中使用下划线`_`；
   - URI路径中全都使用小驼峰命名法；
   - 接口注释与字段的描述必须填写，字段是类型值时必须列举类型值代表的含义；
   - 分页接口必须包含`current`和`pageSize`两个参数，如果有排序请使用`orderField`（代表排序字段）`orderType`（代表排序类型：asc/desc），返回值结构必须是：
  
   ```json
    {
        "code": 0,
        "message": "success",
        "data": {
            "totalCount": 1024, // 总条数
            "items": [] // 数据列表
        }
    }
   ```
   - 如果接口返回值是`List`类型的数据，并且子元素是对象，那么子元素必须返回`“id”`（唯一值）字段；

**注意：以上为接口规范的通用规范，如果有特殊情况请私下沟通商议处理**

## UI设计规范
...

## CR规范（code review）
Code Review（代码审查）在软件开发过程中具有重要的意义，它是指团队成员对彼此编写的代码进行仔细检查和评审，能够提升代码质量、规范代码风格、知识分享、增强代码可读性、一致性、减少维护成本。在团队中，代码审查是一种相互学习、相互尊重、相互信任的体现，是一种团队精神的体现。

1. 严格按照编程规范指南（见上）来 Reivew 代码；
2. 可以人人 Review —— 合适的 Reviewer；
3. 快速响应；
4. 遇到紧急需求上线，来不及代码审查，最好是在dingding中，创建一个 代办，用来后续跟踪，确保后续补上 Code Review，并对 Code Review 结果有后续的代码更新。
5. 在 Code Reivew 的评论中适当加入 Code Sample；
6. 批注中对要改的内容作出说明原因时候，尽量能有理论依据支撑，而不是我觉得就应该这样；

**好的 Code Review 不仅能提前发现隐藏的 Bug，还能使得团队成员的代码能力得到提高。相反，不好的 Code Review 带来的不仅不能发现 Bug，不能帮助团队提升，更可怕的是会影响整个团队的开发氛围和团队成员之间的关系。**

### 问题记录模板

| 问题位置（file->func->line)  |  问题描述 |  类型（设计or功能or复杂度or命名or注释or风格） |  审查人 |  代码作者 |  解决思路 |  解决时间 |  问题解决跟踪 | 验证人  |
|---|---|---|---|---|---|---|---|---|
| src/services/DataSource.go →GetSampleDataAndTotalCount → 658  |  抽样过程中过滤大类型的样本数据 |  功能 | 金尔松  | 邓南浩  | 抽样查询过程中过滤大类型字段  |  2023/8/16 |  已解决 | 金尔松   |


