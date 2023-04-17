#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 展示task
# @author: 徐宙
# @date: 2023-04-14

# 默认选项值
bash_dir=$(dirname "$0")
base_dir=$(pwd)
source $bash_dir"/task_common.sh"

function usage() {
    cat $bash_dir"/usage/task_manage.usage"
}

function main() {
    # 处理command
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi
    command=$1
    shift 1

    if [ 'show' == $command ]; then
        list_task "$@"
    elif [ 'del' == $command ]; then
        del_task "$@"
        if [ $? == 1 ]; then
            usage
        fi
    fi
}

main "$@"