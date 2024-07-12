# gitbash 2.0

## 简介

git脚本

| 脚本名                    | 别名   | 功能          | 
|------------------------|------|-------------|
| task_manage.sh         | task | 任务管理        |
| batch_get_remote.sh    | bgr  | 批量获取远程url脚本 |
| batch_set_remote.sh    | bsr  | 批量设置远程url脚本 |
| new_workspace          | nwo  | 新建工作空间      |
| batch_new_branch.sh    | nb   | 批量创建分支脚本    |
| cb.sh                  | cb   | 批量切换分支脚本    |
| mg.sh                  | mg   | 一键合并分支脚本    |
| batch_pull             | gpl  | 批量拉取远程代码    |
| batch_delete_branch.sh | db   | 批量删除分支脚本    |
| batch_del.sh           | bd   | 批量删除脚本      |

## 环境配置

### Windows git配置

1. 安装windows版本的git(操作步骤参考：https://zhuanlan.zhihu.com/p/123195804)
2. 下载gitbash脚本到本地C:\github\gitbash目录下
3. 打开git安装目录(根据个人情况区分，我这里是，C:\Program Files\Git\etc\profile.d\)
4. 在aliases.sh文件最后添加如下代码

```bash
if [ -f /c/github/gitbash/.bash_profile ]; then
        . /c/github/gitbash/.bash_profile
fi
```

### 脚本config配置

1. 复制config_demo文件夹，创建config文件夹
2.

## 脚本使用

1. 打开git bash
2. 输入task，显示任务管理帮助
3. 其他命令直接输入也会有帮助文档显示，根据文档进行使用即可
