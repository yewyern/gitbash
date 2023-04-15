#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
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
    if [ $(git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l) != 0 ]; then
        echo 2
    # 判断只存在于本地，没有远程的分支
    elif [ -z "$(git branch --list $1)" ]; then
        echo 0
    else
        echo 1
    fi
}

function new_branch() {
    target_br2=$1
    branch_type=$(get_branch_type $target_br2)
    if [ $branch_type = 2 ]; then
        success_log "远程分支已存在，无需创建分支"
        return 1
    fi

    # 如果有内容修改
    if [ -n "$(git status --porcelain)" ]; then
        error_log "** 有内容修改未提交，无法创建分支"
        error_log "** 请确认提交，或使用git stash保存空间之后，再创建分支"
        return 0
    fi
    git fetch

    # 查看当前分支
    curr_br=$(git symbolic-ref --short -q HEAD)
    # 如果当前分支不是master，切换到master分支
    if [ "$curr_br" != "master" ]; then
        git checkout master
        git pull
    fi

    # 校验是否成功切换到master分支
    curr_br=$(git symbolic-ref --short -q HEAD)
    if [ "$curr_br" != "master" ]; then
        error_log "** 切换到master分支失败"
        return 0
    fi
    success_log "当前分支：$curr_br"
    success_log "目标分支：$target_br2"

    # 如果存在本地分支
    if [ $branch_type = 1 ]; then
        #        git checkout $target_br2
        #        git merge master
        #        git push --set-upstream origin $target_br2
        error_log "有本地分支，请手动处理"
        return 1
    fi

    # 提示是否进行创建
    if [[ $no_prompt = 0 ]]; then
        echo -n "是否进行创建？(y/n)"
        read toContinue
        if [[ "$toContinue" != "y" ]]; then
            return 1
        fi
    fi

    git checkout -b $target_br2
    curr_br=$(git symbolic-ref --short -q HEAD)
    if [ "$curr_br" != "$target_br2" ]; then
        error_log "** 创建分支失败，当前分支：$curr_br"
        return 0
    fi
    success_log "创建成功，当前分支：$curr_br"
    git push --set-upstream origin $target_br2
    success_log "已推送至远程"
    return 1
}

if [ $# -lt 2 ]; then
    error_log "Usage: newBranchFromMaster.sh [-y] filename branch_name"
    error_log "example: newBranchFromMaster.sh branch_list.txt pre-develop-t1"
    error_log "branch_list.txt like this: "
    error_log "test1"
    error_log "test2"
    exit 1
fi

no_prompt=0
if [[ "$1" == "-y" ]]; then
    #statements
    no_prompt=1
    shift 1
fi
filename=$1
target_br=$2

# 取当前目录
base_dir=$(pwd)
# 一次读取所有行到数组
mapfile lines <$filename
# 遍历数组
for i in "${!lines[@]}"; do
    line=${lines[$i]}
    # 过滤空行和#号开头的
    if [[ -z "$line" ]] || [[ ${line:0:1} == "#" ]]; then
        continue
    fi
    # 处理换行符
    line=$(echo $line | tr --delete '\n')
    line=$(echo $line | tr --delete '\r')
    # 过滤空行
    if [[ -z "$line" ]]; then
        continue
    fi
    success_log
    success_log "当前行：$line"
    # 根据空格或tab分割字符串
    arr=($line)
    # 第一个是项目
    project=${arr[0]}
    # 打开文件夹
    cd $base_dir/$project || continue
    success_log "当前目录：$(pwd)"
    # 查看当前分支
    curr_br=$(git symbolic-ref --short -q HEAD)
    # 切换分支到master
    new_branch $target_br
    success_log "-----------------------"
done
