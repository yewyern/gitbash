# !/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键合并代码
#

function success_log() {
	echo -e "\033[32m $* \033[0m"
}

function error_log() {
	echo -e "\033[31m $* \033[0m"
}

if [ $# -lt 1 ] ; then
	echo "Usage: meg from_branch_name [to_branch_name]"
	echo "example: meg dev"
	echo "example: meg dev master"
	git branch
	exit 1
fi

from_br=$1
to_br=$2

# 如果没有to_br，用当前分支作为to_br
if [ $# -lt 2 ] ; then
	to_br=`git symbolic-ref --short -q HEAD`
fi

success_log "源分支：$from_br"
success_log "目标分支：$to_br"
# 如果分支一样的无需合并
if [ "$from_br" = "$to_br" ]; then
	success_log "分支相同无需合并"
return 1
fi
# 判断是否存在未提交的文件
if [ -n "$(git status --porcelain)" ]; then
	error_log "** 有内容修改未提交，无法切换分支"
	error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
	return 0
fi

# 提示是否需要合并
if [[ $no_prompt = 0 ]]; then
	echo -n "是否进行合并？(y/n)"
	read toContinue
	if [[ "$toContinue" != "y" ]]; then
	  return 1
	fi
fi

# 拉取远程分支
git fetch

# 切换源分支
swith_branch $from_br
if [ $? = 0 ]; then
	return 0
fi
success_log "切换源分支成功，$from_br"

# 切换目标分支
swith_branch $to_br
if [ $? = 0 ]; then
	return 0
fi
success_log "切换目标分支成功，$to_br"

# 判断是否已经合并成功
git merge-base --is-ancestor $from_br HEAD
if [ $? = 0 ]; then
	success_log "分支已经合并无需再次合并"
	return 1
fi

git merge $from_br

if [ -n "$(git status --porcelain)" ]; then
	error_log "合并$project分支$from_br到$to_br，存在冲突"
	return 0
fi
success_log "合并$project分支$from_br到$to_br成功"

branch_type=`get_branch_type $to_br`
if [ $branch_type = 2 ]; then
	git push
	success_log "已推送$project分支$to_br到远程"
fi
return 1