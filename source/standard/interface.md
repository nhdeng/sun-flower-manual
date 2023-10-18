---
layout: page
title: "接口规范"
date: 2023-08-25 11:05:51
tags:
---

# 接口规范

<!-- ## 目录

- [接口规范](#接口规范)
  - [目录](#目录)
  - [相关组件参数结构规范](#相关组件参数结构规范)
  - [总体规范](#总体规范)
    - [**Path具体的实现**](#path具体的实现)
    - [**Response 规范**](#response-规范)
    - [**错误处理**](#错误处理)
  - [部分组件字段统一](#部分组件字段统一)
    - [分页](#分页)
    - [下拉菜单](#下拉菜单)
    - [多选框、单选框、选择器](#多选框单选框选择器)
    - [树形控件](#树形控件) -->

## 总体规范

1. <font color='red'>【强制】</font>前后端交互的 API，需要明确协议、域名、路径、请求方法、请求内容、状态码、响应体。
   <font color='#9E8426'>说明：</font>
- 路径：每一个 API 需对应一个路径，表示 API 具体的请求地址：
    1. 代表一种资源，只能为名词，推荐使用复数，不能为动词，请求方法已经表达动作意义。
    2. URL 路径不能使用大写，单词如果需要分隔，统一使用下划线。
- 请求方法：对具体操作的定义，常见的请求方法如下：
    1. GET：从服务器取出资源。
    2. POST：在服务器新建一个资源。
    3. PUT：在服务器更新资源。
    4. DELETE：从服务器删除资源。
- 请求内容：URL 带的参数必须无敏感信息或符合安全要求；body 里带参数时必须设置 Content-Type。
    1. 响应体：响应体 body 可放置多种数据类型，由 Content-Type 头来确定。

2.<font color='red'>【强制】</font>前后端数据列表相关的接口返回，如果为空，则返回空数组[]或空集合{}。
<font color='#9E8426'>说明：</font>此条约定有利于数据层面上的协作更加高效，减少前端很多琐碎的 null 判断。

3.<font color='red'>【强制】</font>服务端发生错误时，返回给前端的响应信息必须包含HTTP 状态码，errorCode、
errorMessage、用户提示信息四个部分。
<font color='#9E8426'>说明：</font>四个部分的涉众对象分别是浏览器、前端开发、错误排查人员、用户。其中输出给用户的提示信息要求：简短清
晰、提示友好，引导用户进行下一步操作或解释错误原因，提示信息可以包括错误原因、上下文环境、推荐操作等。
errorCode：参考 。errorMessage：简要描述后端出错原因，便于错误排查人员快速定位问题，注意不要包含敏
感数据信息。
<font color='#32C5AA'><font color='#32C5AA'>正例：</font></font> 常见的 HTTP 状态码如下
1）200 OK：表明该请求被成功地完成，所请求的资源发送到客户端。
2）401 Unauthorized：请求要求身份验证，常见对于需要登录而用户未登录的情况。
3）403 Forbidden：服务器拒绝请求，常见于机密信息或复制其它登录用户链接访问服务器的情况。
4）404 NotFound：服务器无法取得所请求的网页，请求资源不存在。
5）500 InternalServerError：服务器内部错误。

4.<font color='red'>【强制】</font>在前后端交互的 JSON 格式数据中，所有的 key 必须为小写字母开始的 lowerCamelCase
风格，符合英文表达习惯，且表意完整。
<font color='#32C5AA'>正例：</font>errorCode / errorMessage / assetStatus / menuList / orderList / configFlag
<font color='#FF8833'>反例：</font> ERRORCODE / ERROR_CODE / error_message / error-message / errormessage

5.<font color='red'>【强制】</font>errorMessage 是前后端错误追踪机制的体现，可以在前端输出到 type="hidden" 文字类控件中，或者用户端的日志中，帮助我们快速地定位出问题。

6.<font color='red'>【强制】</font>对于需要使用超大整数的场景，服务端一律使用 String 字符串类型返回，禁止使用 Long 类型。
<font color='#9E8426'>说明：</font>Java 服务端如果直接返回 Long 整型数据给前端，Javascript 会自动转换为 Number 类型（注：此类型为双精度浮
点数，表示原理与取值范围等同于 Java 中的 Double）。Long 类型能表示的最大值是 263-1，在取值范围之内，超过 253
（9007199254740992）的数值转化为 Javascript 的 Number 时，有些数值会产生精度损失。扩展说明，在 Long 取值范
围内，任何 2 的指数次的整数都是绝对不会存在精度损失的，所以说精度损失是一个概率问题。若浮点数尾数位与指数位
空间不限，则可以精确表示任何整数，但很不幸，双精度浮点数的尾数位只有 52 位。
反例：通常在订单号或交易号大于等于 16 位，大概率会出现前后端订单数据不一致的情况。
比如，后端传输的 "orderId"：362909601374617692，前端拿到的值却是：362909601374617660

7.<font color='red'>【强制】</font>HTTP 请求通过 URL 传递参数时，不能超过 2048 字节。
<font color='#9E8426'>说明：</font>不同浏览器对于 URL 的最大长度限制略有不同，并且对超出最大长度的处理逻辑也有差异，2048 字节是取所
有浏览器的最小值。
反例：某业务将退货的商品 id 列表放在 URL 中作为参数传递，当一次退货商品数量过多时，URL 参数超长，传递到后端的
参数被截断，导致部分商品未能正确退货。

8.<font color='red'>【强制】</font>HTTP 请求通过 body 传递内容时，必须控制长度，超出最大长度后，后端解析会出错。
<font color='#9E8426'>说明：</font>nginx 默认限制是 1MB，tomcat 默认限制为 2MB，当确实有业务需要传较大内容时，可以调大服务器端的限制。

9.<font color='red'>【强制】</font>在翻页场景中，用户输入参数的小于 1，则前端返回第一页参数给后端；后端发现用户输入的
参数大于总页数，直接返回最后一页。

10.<font color='red'>【强制】</font>服务器内部重定向必须使用 forward；外部重定向地址必须使用 URL 统一代理模块生成，否
则会因线上采用 HTTPS 协议而导致浏览器提示“不安全”，并且还会带来 URL 维护不一致的问题。

11.<font color='gold'>【推荐】</font>服务器返回信息必须被标记是否可以缓存，如果缓存，客户端可能会重用之前的请求结果。
<font color='#9E8426'>说明：</font>缓存有利于减少交互次数，减少交互的平均延迟。
<font color='#32C5AA'>正例：</font>http1.1 中，s-maxage 告诉服务器进行缓存，时间单位为秒，用法如下，
response.setHeader("Cache-Control", "s-maxage=" + cacheSeconds);

12.<font color='gold'>【推荐】</font>前后端的时间格式统一为"yyyy-MM-dd HH:mm:ss"，统一为 GMT。

13.<font color='#779466'>【参考】</font>在接口路径中不要加入版本号，版本控制在 HTTP 头信息中体现，有利于向前兼容。
<font color='#9E8426'>说明：</font>当用户在低版本与高版本之间反复切换工作时，会导致迁移复杂度升高，存在数据错乱风险

14. 其他
- POST、GET请求没有具体使用规范，只有特殊请求强制规范

    - 文件下载接口必须使用GET请求，接口返回类型为文件流形式

    - 涉及敏感数据必须使用POST请求、( 涉及密码传输全部使用sm2加解密 )

    - 根据请求参数数量自行决定POST和GET请求  ( 建议有参数统一使用POST请求 )

- 所有路径path全部小驼峰，包括所有参数，POST里面的body ( 例外： header 中参数使用大驼峰加'-'，  例：Content-Encoding：gzip）

- 我们返回一般统一使用json格式返回

- 在url上必须包含行为

### **Path具体的实现**

path = /api/{版本}/{具体的业务功能}/{行为}

例如：/api/v1/sysadm/lists

/api/v1/sysadm/edit


### **错误处理**

(一) 错误码
1.<font color='red'>【强制】</font>错误码的制定原则：快速溯源、沟通标准化。
<font color='#9E8426'>说明：</font>错误码想得过于完美和复杂，就像康熙字典的生僻字一样，用词似乎精准，但是字典不容易随身携带且简单易懂。
<font color='#32C5AA'>正例：</font>错误码回答的问题是谁的错？错在哪？
1）错误码必须能够快速知晓错误来源，可快速判断是谁的问题。
2）错误码必须能够进行清晰地比对（代码中容易 equals）。
3）错误码有利于团队快速对错误原因达到一致认知。

2.<font color='red'>【强制】</font>错误码不体现版本号和错误等级信息。
<font color='#9E8426'>说明：</font>错误码以不断追加的方式进行兼容。错误等级由日志和错误码本身的释义来决定。

3.<font color='red'>【强制】</font>全部正常，但不得不填充错误码时返回五个零：00000。

4.<font color='red'>【强制】</font>错误码为字符串类型，共 5 位，分成两个部分：错误产生来源+四位数字编号。
<font color='#9E8426'>说明：</font>错误产生来源分为 A/B/C，A 表示错误来源于用户，比如参数错误，用户安装版本过低，用户支付超时等问题；
B 表示错误来源于当前系统，往往是业务逻辑出错，或程序健壮性差等问题；C 表示错误来源于第三方服务，比如 CDN
服务出错，消息投递超时等问题；四位数字编号从 0001 到 9999，大类之间的步长间距预留 100，参考文末附表 3。

5.<font color='red'>【强制】</font>编号不与公司业务架构，更不与组织架构挂钩，以先到先得的原则在统一平台上进行，审批生
效，编号即被永久固定。

6.<font color='red'>【强制】</font>错误码使用者避免随意定义新的错误码。
<font color='#9E8426'>说明：</font>尽可能在原有错误码附表中找到语义相同或者相近的错误码在代码中使用即可。

7.<font color='red'>【强制】</font>错误码不能直接输出给用户作为提示信息使用。
<font color='#9E8426'>说明：</font>堆栈（stack_trace）、错误信息(error_message) 、错误码（error_code）、提示信息（user_tip）是一个有效关
联并互相转义的和谐整体，但是请勿互相越俎代庖。

8.<font color='gold'>【推荐】</font>错误码之外的业务信息由 error_message 来承载，而不是让错误码本身涵盖过多具体业务属性。

9.<font color='gold'>【推荐】</font>在获取第三方服务错误码时，向上抛出允许本系统转义，由 C 转为 B，并且在错误信息上带上原
有的第三方错误码。

10.<font color='#779466'>【参考】</font>错误码分为一级宏观错误码、二级宏观错误码、三级宏观错误码。
<font color='#9E8426'>说明：</font>在无法更加具体确定的错误场景中，可以直接使用一级宏观错误码，分别是：A0001（用户端错误）、B0001（系
统执行出错）、C0001（调用第三方服务出错）。
<font color='#32C5AA'>正例：</font>调用第三方服务出错是一级，中间件错误是二级，消息服务出错是三级。

11.<font color='#779466'>【参考】</font>错误码的后三位编号与 HTTP 状态码没有任何关系。

12.<font color='#779466'>【参考】</font>错误码有利于不同文化背景的开发者进行交流与代码协作。
<font color='#9E8426'>说明：</font>英文单词形式的错误码不利于非英语母语国家（如阿拉伯语、希伯来语、俄罗斯语等）之间的开发者互相协作。

13.<font color='#779466'>【参考】</font>错误码即人性，感性认知+口口相传，使用纯数字来进行错误码编排不利于感性记忆和分类。
<font color='#9E8426'>说明：</font>数字是一个整体，每位数字的地位和含义是相同的。
<font color='#FF8833'>反例：</font>一个五位数字 12345，第 1 位是错误等级，第 2 位是错误来源，345 是编号，人的大脑不会主动地拆开并分辨每
位数字的不同含义

不要直接将异常抛给客户端处理，一般需要一个统一的异常处理类，并且以统一格式将异常信息返回前端，统一格式参照:

```react
switch (case) {
    case 400:
      message = '请求错误(400)'
      break
    case 401:
      message = '未授权，请重新登录(401)'
      break
    case 403:
      message = '拒绝访问(403)'
      break
    case 404:
      message = '请求出错(404)'
      break
    case 408:
      message = '请求超时(408)'
      break
    case 500:
      message = '服务器错误(500)'
      break
    case 501:
      message = '服务未实现(501)'
      break
    case 502:
      message = '网络错误(502)'
      break
    case 503:
      message = '服务不可用(503)'
      break
    case 504:
      message = '网络超时(504)'
      break
    case 505:
      message = 'HTTP版本不受支持(505)'
      break
    default:
      message = `连接出错(${status})!`
  }
```

## 安全规约

1.<font color='red'>【强制】</font>隶属于用户个人的页面或者功能必须进行权限控制校验。
<font color='#9E8426'>说明：</font>防止没有做水平权限校验就可随意访问、修改、删除别人的数据，比如查看他人的私信内容。

## 索引规约
1.<font color='red'>【强制】</font>业务上具有唯一特性的字段，即使是组合字段，也必须建成唯一索引。
<font color='#9E8426'>说明：</font>不要以为唯一索引影响了 insert 速度，这个速度损耗可以忽略，但提高查找速度是明显的；另外，即使在应用层
做了非常完善的校验控制，只要没有唯一索引，根据墨菲定律，必然有脏数据产生。

## 部分组件字段统一

### 分页

? 表示非必须

请求

```react
{
      current: number, // 页码
      pageSize: number, // 页数
      orderType?: string , // 排序字段类型  'asc'升序 : 'desc'降序
      orderField?: string, // 排序字段值
}
```

响应

```react
code: number //状态码
message: string //信息
data: { // 数据
    totalCount: number //总数
    items: [] // 具体数据 无数据items为[], 不能为null或没有items属性
}
```

### 下拉菜单

![](/images/dropdown.png)

```react
[{
    key: string,   //值
    label: string, //名称
}]
```

### 多选框、单选框、选择器

单选多选框

![](/images/radio.png)

选择器

![](/images/select.png)

```react
[{
     label: string, //名称
     value: string, //值
}]
```

### 树形控件

![](/images/tree.png)

```react
// 没有children 则不展示children字段
[{
    title: string, // 名称
    key: string,  // 值
    children: [{  // 子叶
       title: string,
       key: string,
       children: ......  
    }]
}]
```
