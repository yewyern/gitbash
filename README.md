# gitbash 2.0

## 1. 简介

git脚本

| 脚本名                    | 别名   | 功能                |
|------------------------|------|-------------------|
| task_manage.sh         | task | 任务管理，管理工作空间，项目，分支 |
| batch_get_remote.sh    | bgr  | 批量获取远程url脚本       |
| batch_set_remote.sh    | bsr  | 批量设置远程url脚本       |
| new_workspace          | nwo  | 新建工作空间            |
| batch_new_branch.sh    | nb   | 批量创建分支脚本          |
| cb.sh                  | cb   | 批量切换分支脚本          |
| mg.sh                  | mg   | 一键合并分支脚本          |
| batch_pull             | gpl  | 批量拉取远程代码          |
| batch_delete_branch.sh | db   | 批量删除分支脚本          |
| batch_del.sh           | bd   | 批量删除脚本            |

## 2. 环境配置

### 2.1 Windows git配置

#### 2.1.1 安装windows版本的git(操作步骤参考：https://zhuanlan.zhihu.com/p/123195804)

![1_no_alias.png](imgs/1_no_alias.png)

#### 2.1.2 下载gitbash脚本到本地C:\github\gitbash目录下

#### 2.1.3 打开git安装目录(根据个人情况区分，我这里是，C:\Program Files\Git\etc\profile.d\)，在aliases.sh文件最后添加如下代码

```bash
if [ -f /c/github/gitbash/.bash_profile ]; then
  . /c/github/gitbash/.bash_profile
fi
```

![2_edit_alias.png](imgs/2_edit_alias.png)

#### 2.1.4 修改保存后，重新打开git，可以看到别名已经生效

![3_alias.png](imgs/3_alias.png)

### 2.2 脚本config配置

#### 2.2.1 复制config_demo文件夹，并命名为config文件夹

![4_copy_config.png](imgs/4_copy_config.png)

#### 2.2.2 项目地址配置（remote.txt）

![6_remote.png](imgs/6_remote.png)

##### 2.2.2.1 本地已有项目，快速生成remote.txt

> 打开本地项目目录，执行 `bgr` 命令，没有远程url的项目不会生成（可通过git remote -v命令查看是否远程项目）

![7_remote_generate.png](imgs/7_remote_generate.png)

> 生成的remote.txt在当前目录下，查看并移动到gitbash/config/remote.txt文件

![8_remote_res.png](imgs/8_remote_res.png)

#### 2.2.3 集中式环境分支配置（branch_${环境名}.txt，示例：branch_dev.txt）

![9_branch_env.png](imgs/9_branch_env.png)

## 3. 常用脚本使用

### 3.1 添加任务（gitbash/config/task.txt）

> 1.直接修改文件内容

![5_task_config.png](imgs/5_task_config.png)

```bash
# 命令添加模式1
task add
```
![5_task_add.png](imgs/5_task_add.png)

```bash
# 命令添加模式2，指定模板为任务4
task add -t 4
```
![5_task_add2.png](imgs/5_task_add2.png)

### 3.2 根据任务创建工作空间

```bash
# 创建任务id 4 对应的工作空间
# 1、自动拉取远程项目
# 2、根据master分支创建并切换到任务分支，推送到远程
nwo 4 
```
![10_new_workspace.png](imgs/10_new_workspace.png)

### 3.3 批量创建分支

```bash
# 
nb 4 -e dev
```