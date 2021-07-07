# gitbash
git脚本

batchdel.sh        批量删除脚本<br/>
batchSetRemote.sh  批量设置远程url脚本<br/>
cb.sh              一键切换分支脚本<br/>
meg                合并分支脚本<br/>
mg.sh              一键合并分支脚本<br/>
rb.sh              rebase合并分支脚本<br/>
rbt                rebase to 分支<br/>
taga               git打tag并推送远程<br/>
tagd               git删除tag并推送远程<br/>

## Windows配置

打开cmd

```bash
cd %USERPROFILE%
del .bash_profile
mklink /H .bash_profile C:\github\gitbash\.bash_profile
```

