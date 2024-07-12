# gitbash 2.1
## change-list

1. 环境分支可支持任务级别配置，支持多个release并行开发

# gitbash 2.0
## change-list

1. 设计了任务模式，集中管理任务
   > 复制config_demo文件夹，创建config文件夹，向tasks.txt中添加任务，即可通过任务进行分支管理
2. cb.sh,mg.sh,batch_pull,new_workspace,均采用任务模式

# gitbash 1.0
## change-list

1. git 批量脚本，提供批量切换分支，批量合并分支，批量删除分支，批量打tag，批量删除tag，批量拉取远程代码等功能
2. 每个工作空间中使用一个project.txt文件，记录当前工作空间中所有项目，任务分支等信息