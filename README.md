# gitbash

git脚本

batchdel.sh        批量删除脚本<br/>
batchSetRemote.sh  批量设置远程url脚本<br/>
cb.sh              一键切换分支脚本[git一键切换多个项目分支并拉取远程_git 切换到 target分支-CSDN博客](https://blog.csdn.net/shashengwan0313/article/details/115870528)<br/>
mg.sh              一键合并分支脚本[git一键合并分支并推送远程脚本_git 分支合并win脚本-CSDN博客](https://blog.csdn.net/shashengwan0313/article/details/115870211)<br/>
rb.sh              rebase合并分支脚本<br/>
rbt                rebase to 分支<br/>
taga               git打tag并推送远程<br/>
tagd               git删除tag并推送远程<br/>

## Windows配置

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

## ubuntu配置

```shell
vi ~/.bashrc

# 添加如下代码
if [ -f /mnt/c/github/gitbash/.bash_aliases ]; then
        . /mnt/c/github/gitbash/.bash_aliases
fi
```
