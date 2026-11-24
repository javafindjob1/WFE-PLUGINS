## 本项目目标

帮助玩家分析游戏中伤害，死亡有明细可以查看。

### 记录魔兽的伤害明细

### 分组统计伤害

### 显示阵亡总结



## 代码管理

### 代码提交与回滚

- **每次发布前必须提交代码**，便于后续版本回滚。
- 提交信息应清晰描述本次变更内容，确保可追溯。

### 字符集规范

- **项目统一使用 UTF-8 字符集**。
- 所有源码、配置文件、脚本及相关文本文件均须以 UTF-8 编码保存，禁止使用其他编码（如 GBK、ANSI 等）。
- 新增或修改文件时，注意确认编辑器/IDE 的编码设置为 UTF-8，避免引入乱码问题。


### 记录需求

写代码之前，先改需求文档.md。如果代码与文档或者注释不符，要修改文档和注释。



## 自动化测试工具

### 启动魔兽

japi类的地图魔兽启动方式：C:\3rd\war5-jass\jass_plugin\魔兽启动器（可启动带japi的地图）

```
bin\YDWEConfig.exe -launchwar3 -loadfile <地图名>
```



### 管理员权限

如果需要提权

```
C:\Users\76769\Desktop\h026\work\elevated-input-bridge
```



## 死亡结算使用方式

### 作为WFE的附加库

wfe支持自动注入或者用户手动注入到war3从而运行



### 独立启动注入

暂时不用



## 遇到问题

### 记录问题

将问题和解决方案记录到[问题.md]中

### 联网搜索解决方案



## 参考资料

### 魔兽目录

```
C:\3rd\war5
```



### KK平台目录

```
C:\Program Files (x86)\kkduizhan
```



### WFE目录

```
C:\3rd\wc3gamesearcher\WFE
```



### 死亡结算目录

```
C:\3rd\war5-jass\jass_plugin\新建文件夹\WFE-PLUGINS\DeathSettlement
```



### YDWE源码目录

#### 这就是japi源码

```
C:\3rd\war5-jass\jass_plugin\魔兽启动器（可启动带japi的地图）\YDWE-master
```



#### japi设置头像

接口文档：

```
https://japi.war3rpg.top/Japi/%E8%AE%BE%E7%BD%AE%E5%8D%95%E4%BD%8D%E5%A4%B4%E5%83%8F%E6%A8%A1%E5%9E%8B.html
```

