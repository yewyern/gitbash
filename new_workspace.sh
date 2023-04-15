#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 使用当前目录的remote.txt，根据指定的项目列表，拉取所有指定的项目，已存在的不拉取
# @author: 徐宙
# @date: 2020-12-08

remote_filename=remote.txt

function success_log() {
    echo -e "\033[32m $* \033[0m"
}

function error_log() {
    echo -e "\033[31m $* \033[0m"
}

if [ $# -lt 2 ]; then
    error_log "Usage: cb.sh filename workspace_name"
    error_log "example: cb.sh brach_list.txt esjob"
    error_log "brach_list.txt like this: "
    error_log "test1	dev"
    error_log "test2	dev"
    exit 1
fi

filename=$1
workspace_name=$2
# 取当前目录
base_dir=`pwd`
if [ ! -d "$base_dir/$workspace_name" ];then
    success_log "创建工作目录：$workspace_name"
    mkdir "$workspace_name"
fi
cp $filename $base_dir/$workspace_name/$filename
cd $workspace_name
success_log "当前目录：`pwd`"
# 遍历文件，每次处理一行
while read line || [[ -n $line ]]; do
    line=`echo $line | tr --delete '\n'`
    line=`echo $line | tr --delete '\r'`
    # 跳过以"#"号开头的行，可以注释某些行，更灵活
    if [[ -z "$line" ]] || [[ ${line:0:1} == "#" ]]; then
        continue
    fi
    success_log
    success_log "当前行：$line"
    # 根据空格或tab分割字符串
    arr=($line)
    # 第一个是项目
    project=${arr[0]}
    if [ ! -d "$base_dir/$workspace_name/$project" ];then
        # 目标项目git url
        remote_url=`grep "^$project " $base_dir/$remote_filename | awk '{print $2}'`
        if [[ -z "$remote_url" ]]; then
            error_log "未找到项目远程地址，请确认$base_dir/$remote_filename是否正确！"
            continue
        fi
        cd $base_dir/$workspace_name
        success_log "当前目录：`pwd`"
        git clone $remote_url
    fi
    # 打开文件夹
    cd $base_dir/$workspace_name/$project
    success_log "当前目录：`pwd`"
    success_log "-----------------------"
done < $filename
