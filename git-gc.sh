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

no_prompt=0
if [[ "$1" == "-y" ]]; then
  #statements
  no_prompt=1
  shift 1
fi
filename=$1
if [[ -z "$filename" ]]; then
  filename=temp.txt
  echo>$filename
  fileList=$(ls)
  for fn in $fileList
  do
    if test -d "$fn"
     then
        echo "$fn">>$filename
     fi
  done
fi
branch_index=$2
if [ -z "$branch_index" ]; then
  branch_index=1
fi
# 取当前目录
base_dir=$(pwd)
# 一次读取所有行到数组
mapfile lines < $filename
# 遍历数组
for i in "${!lines[@]}";   
do
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
  git gc
  success_log "-----------------------"
done