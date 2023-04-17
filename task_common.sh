#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# task公共方法
# @author: 徐宙
# @date: 2023-04-14

# 默认选项值
bash_dir=$(dirname "$0")
base_dir=$(pwd)
source $bash_dir"/util.sh"

task_table=$bash_dir"/config/tasks.txt"

declare -A task_info
task_projects=()

function list_task() {
    if [ $# -ge 1 ]; then
        # 展示指定的任务
        head -n1 $task_table
        grep "^$1 *|" $task_table | grep -v "deleted"
    else
        # 展示所有的任务(不包含deleted)
        grep -v "deleted" $task_table
    fi
    return 0
}

function del_task() {
    if [ $# -lt 1 ]; then
        return 1
    fi
    echo "删除task, id="$1
    # 查找并标记为删除
    sed -i "/^$1 *|.*| *$/s/$/ deleted/" $task_table
    return 0
}

function get_task() {
    if [ $# -lt 1 ]; then
        return 1
    fi
    # 解析taskInfo
    OLD_IFS=$IFS
    IFS=$'\n'
    lines=(`list_task $1`)
    len=${#lines[@]}
    if [ $len != 2 ]; then
        error_log "未找到对应的任务，请检查任务配置"
        exit 1
    fi
    IFS='|'
    read -r -a head <<< "${lines[0]}"
    read -r -a data <<< "${lines[1]}"
    for i in "${!head[@]}";
    do
        key=`trim ${head[$i]}`
        val=`trim ${data[$i]}`
        # 字符串拼接可以放到双引号内，也可以放到双引号外，放到双引号内可能出现问题，丢失部分字符，原因未知
        task_info["$key"]="$val"
    done
    IFS=','
    task_projects=(${task_info["projects"]})
    IFS=$OLD_IFS
}
