# gitbash 2.0

## change-list

1. 设计了任务模式
   > 复制config_demo文件夹，创建config文件夹，向tasks.txt中添加任务，即可通过任务进行分支管理
2. cb.sh,mg.sh,batch_pull,new_workspace,均采用任务模式

## 简介

git脚本

| 脚本名                 | 功能            | 
|---------------------|---------------|
| batch_del.sh        | 批量删除脚本        |
| batch_set_remote.sh | 批量设置远程url脚本   |
| cb.sh               | 批量切换分支脚本      |
| mg.sh               | 一键合并分支脚本      |
| rb.sh               | rebase合并分支脚本  |
| rbt                 | rebase to 分支  |
| taga                | git打tag并推送远程  |
| tagd                | git删除tag并推送远程 |
| batch_pull          | 批量拉取远程代码      |
| new_workspace       | 新建工作空间        |

## 环境配置

### Windows配置

打开cmd

```bash
# 打开git安装目录，以下简称GIT_HOME（如：C:\Program Files\Git\etc\profile.d）
cd $GIT_HOME
vi aliases.sh

# 添加如下代码
if [ -f /c/github/gitbash/.bash_profile ]; then
        . /c/github/gitbash/.bash_profile
fi
```

### ubuntu配置

```shell
vi ~/.bashrc

# 添加如下代码
if [ -f /mnt/c/github/gitbash/.bash_aliases ]; then
        . /mnt/c/github/gitbash/.bash_aliases
fi
```

