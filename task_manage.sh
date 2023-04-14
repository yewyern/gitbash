#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 展示task
# @author: 徐宙
# @date: 2023-04-14

# 默认选项值
bash_dir=$(dirname "$0")
base_dir=$(pwd)
command=show
task_table=$bash_dir"/config/tasks.txt"
task_table_config=$bash_dir"/config/tasks.cfg"

function usage() {
    cat $bash_dir"/usage/task_manage.usage"
}

# 处理command
if [ $# -lt 1 ]; then
    usage
    exit 1
fi
command=$1
shift 1

function show() {
    if [ $# == 1 ]; then
        # 展示指定的任务
        head -n1 $task_table
        grep "^$1 *|" $task_table | grep -v "deleted"
    else
        # 展示所有的任务(不包含deleted)
        grep -v "deleted" $task_table
    fi
}

function del() {
    echo "删除task, id="$@
    if [ $# != 1 ]; then
        usage
        exit 1
    fi
    # 查找并标记为删除
    sed -i "/^$1 *|.*| *$/s/$/ deleted/" $task_table
}

function get() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    task_id=$1
    task_field=$2
    source $task_table_config
    field_index_name=$task_field"_field_index"
    grep "^$task_id *|" $task_table | grep -v "deleted" | cut -d"|" -f${!field_index_name}
}

if [ 'show' == $command ]; then
    show $@
elif [ 'del' == $command ]; then
    del $@
elif [ 'get' == $command ]; then
    get $@
fi
