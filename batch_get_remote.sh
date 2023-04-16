#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 获取文件夹内所有git项目的remote url并生成文件remote.txt
# @author: 徐宙
# @date: 2020-12-08

function success_log() {
    echo -e "\033[32m $* \033[0m"
}

function error_log() {
    echo -e "\033[31m $* \033[0m"
}

# 获取当前目录下所有文件夹
filename=$1
if [[ -z "$filename" ]]; then
    filename=temp.txt
    echo >$filename
    fileList=$(ls)
    for fn in $fileList; do
        if test -d "$fn"; then
            echo "$fn" >>$filename
        fi
    done
fi

# 取当前目录
base_dir=$(pwd)
# 初始化结果文件
res_file=remote.txt
echo >$res_file
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
    cd "$base_dir/$project" || continue
    success_log "当前目录：$(pwd)"
    # 查看当前分支
    remote_url=$(git remote -v | grep fetch | awk '{print $2}')
    echo "$remote_url"
    echo "$project $remote_url" >>"$base_dir/$res_file"
    success_log "-----------------------"
done
