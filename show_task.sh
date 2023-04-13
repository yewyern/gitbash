#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 展示task
# @author: 徐宙
# @date: 2023-04-14

# 默认选项值
bash_dir=$(dirname "$0")
base_dir=$(pwd)
show_all=true
task_name=
# 解析选项
while getopts ":tn:" opt; do
  case $opt in
    v)
      verbose=1
      ;;
    t)
      task_name=$OPTARG
      ;;
    \?)
      echo "无效的选项： -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "选项 -$OPTARG 需要一个参数" >&2
      exit 1
      ;;
  esac
done
# 输出选项值
echo "verbose=$verbose, output=$output"
# 移除已处理的选项参数
shift $((OPTIND-1))
# 处理剩余的参数
echo "剩余的参数：$@"

source task_demo
echo $task_work_dir