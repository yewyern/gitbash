#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键合并分支
# @author: 徐宙
# @date: 2020-12-08

function success_log() {
    echo -e "\033[32m $* \033[0m"
}

function error_log() {
    echo -e "\033[31m $* \033[0m"
}

# 0 - 分支不存在
# 1 - 本地分支，无远程
# 2 - 远程分支
function get_branch_type() {
    # 判断远程分支是否存在
    if [ `git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l` != 0 ]; then
        echo 2
    # 判断只存在于本地，没有远程的分支
    elif [ -z "$(git branch --list $1)" ]; then
        echo 0
    else
        echo 1
    fi
}

function swith_branch() {
    # 查看当前分支
    curr_br=`git symbolic-ref --short -q HEAD`
    target_br=$1
    res=1
    # 如果分支相同无需切换
    if [ "$curr_br" != "$target_br" ]; then
        # 如果没有内容修改
        if [ -z "$(git status --porcelain)" ]; then
            success_log "切换分支到：$target_br"
            branch_type=`get_branch_type $target_br`
            if [ $branch_type = 2 ]; then
                git checkout $target_br
                # 更新远程分支到本地
                git pull --rebase
                curr_br=`git symbolic-ref --short -q HEAD`
                success_log "切换成功，当前分支：$curr_br"
            elif [ $branch_type = 1 ]; then
                # 本地分支不需要拉远程
                git checkout $target_br
                curr_br=`git symbolic-ref --short -q HEAD`
                success_log "切换成功，当前分支：$curr_br"
            else
                error_log "** 分支不存在，请检查是否添加过分支"
                res=0
            fi
        else
            error_log "** 有内容修改未提交，无法切换分支"
            error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
            res=0
        fi
    fi
    return $res
}

if [ $# -lt 1 ]; then
    error_log "Usage: mg.sh filename [from_branch_index to_branch_index]"
    error_log "example: mg.sh brach_list.txt"
    error_log "example: mg.sh brach_list.txt 1 2"
    error_log "brach_list.txt like this: "
    error_log "api-rest	feature/FMS-4739	pre-develop-t1"
    error_log "framework-all	feature/FMS-4739	pre-develop-t1"
    exit 1
fi

filename=$1
from_branch_index=$2
if [ -z "$from_branch_index" ]; then
    from_branch_index=1
fi
to_branch_index=$3
if [ -z "$to_branch_index" ]; then
    to_branch_index=2
fi
# 取当前目录
base_dir=`pwd`
# 遍历文件，每次处理一行
while read line || [[ -n $line ]]; do
    success_log
    line=`echo $line | tr --delete '\n'`
    line=`echo $line | tr --delete '\r'`
    success_log "当前行：$line"
    # 根据空格或tab分割字符串
    arr=($line)
    # 第一个是项目
    project=${arr[0]}
    # 合并的源分支
    from_br=${arr[$from_branch_index]}
    # 合并之后的目标分支
    to_br=${arr[$to_branch_index]}
    # 打开文件夹
    cd $base_dir/$project
    success_log "当前目录：`pwd`"
    success_log "源分支：$from_br"
    success_log "目标分支：$to_br"
    # 如果分支一样的无需合并
    if [ "$from_br" != "$to_br" ]; then
        # 判断是否存在未提交的文件
        if [ -z "$(git status --porcelain)" ]; then
            # 拉取远程分支
            git fetch
            swith_branch $from_br
            sws=$?
            if [ $sws = 1 ]; then
                success_log "切换源分支成功，$from_br"
                swith_branch $to_br
                sws=$?
                if [ $sws = 1 ]; then
                    success_log "切换目标分支成功，$to_br"
                    git rebase $from_br
                    if [ -z "$(git status --porcelain)" ]; then
                        success_log "合并$project分支$from_br到$to_br成功"
                        branch_type=`get_branch_type $target_br`
                        if [ $branch_type = 2 ]; then
                            git push
                            success_log "已推送$project分支$to_br到远程"
                        fi
                    else
                        error_log "合并$project分支$from_br到$to_br，存在冲突"
                    fi
                fi
            fi
        else
            error_log "** 有内容修改未提交，无法切换分支"
            error_log "** 请确认提交，或使用git stash保存空间之后，再切换分支"
        fi
    else
        success_log "分支相同无需合并"
    fi
    success_log "-----------------------"
done < $filename