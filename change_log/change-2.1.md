# gitbash 2.1 更新记录
## 1、新增批量添加git exclude功能 2024-07-16
![2_1_batch_exclude.png](imgs/2_1_batch_exclude.png)

## 2、新增config/git.config配置 2024-07-17

```bash
# 新建工作空间模式，默认是0，从远程仓库拉取，如果设置为1，代表在本地复制
new_workspace_mode=0
# 本地项目仓库，新建工作空间模式=1时，需要设置
# local_repos_dir=/e/git/all
```