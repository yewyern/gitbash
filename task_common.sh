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

function add_task() {
    task_headers=($(parse_task_table_headers))
    task_header_len=${#task_headers[@]}
    # flag=0，提示参数
    flag=0
    template_task_id=-1
    # 解析参数
    params=`getopt -o hyt: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -t) template_task_id=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done
    if [ $template_task_id != -1 ]; then
        # 通过现有任务创建
        get_task $template_task_id
    else
        # 普通创建，解析参数到task_info
        # id由脚本自动计算，所以少一个参数
        n=$(($task_header_len-1))
        if [ $n -gt $# ]; then
            n=$#
        fi
        for ((i=1; i<=$n; i++)) do
            key=${task_headers[$i]}
            val=$1
            task_info["$key"]="$val"
            shift
        done
    fi
    if [ $flag == 0 ]; then
        # 普通创建，提示输入任务信息
        for ((i=1; i<$task_header_len; i++)) do
            key=${task_headers[$i]}
            val=${task_info["$key"]}
            if [ "$val" != "" ]; then
                success_log "请输入$key($val):"
            else
                success_log "请输入$key:"
            fi
            read val1
            success_log
            if [ "$val1" != "" ]; then
                val=$val1
            fi
            task_info["$key"]="$val"
        done
    fi
    # 生成id
    last_id=`sed -n '2p' $task_table | cut -d '|' -f1 | awk '{print $1}'`
    task_id=$(($last_id+1))
    task_info["task_id"]=$task_id
    # 拼接数据行
    data=
    for ((i=0; i<$task_header_len; i++)) do
        key=${task_headers[$i]}
        val=${task_info["$key"]}
        data="$data $val |"
    done
    sed -i "1a $data" $task_table
    if [ $? == 0 ]; then
        success_log "添加任务成功"
        list_task $task_id
        return 0
    fi
    error_log "添加任务失败"
    return 1
}

function update_task() {
    task_headers=($(parse_task_table_headers))
    task_header_len=${#task_headers[@]}
    # flag=0，提示参数
    flag=0
    # 解析参数
    params=`getopt -o hyt: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done
    if [ $# -lt 1 ]; then
        # 修改必传任务id
        usage
        return 1
    fi
    task_id=$1
    # 通过现有任务创建
    get_task $task_id
    if [ $flag == 0 ]; then
        # 普通创建，提示输入任务信息
        for ((i=1; i<$task_header_len; i++)) do
            key=${task_headers[$i]}
            val=${task_info["$key"]}
            if [ "$val" != "" ]; then
                success_log "请输入$key($val):"
            else
                success_log "请输入$key:"
            fi
            read val1
            success_log
            if [ "$val1" != "" ]; then
                val=$val1
            fi
            task_info["$key"]="$val"
        done
    fi
    task_info["task_id"]=$task_id
    # 拼接数据行
    data=
    for ((i=0; i<$task_header_len; i++)) do
        key=${task_headers[$i]}
        val=${task_info["$key"]}
        data="$data $val |"
    done
    line_num=`grep "^$task_id *|" "$task_table" -n | grep -v "deleted" | cut -d: -f1`
    sed -i "${line_num}a $data" $task_table
    sed -i "${line_num}d" $task_table
    if [ $? == 0 ]; then
        success_log "修改任务成功"
        list_task $task_id
        return 0
    fi
    error_log "修改任务失败"
    return 1
}

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
        if [ "$key" == "" ]; then
            continue
        fi
        # 字符串拼接可以放到双引号内，也可以放到双引号外，放到双引号内可能出现问题，丢失部分字符，原因未知
        task_info["$key"]="$val"
    done
    IFS=','
    task_projects=(${task_info["projects"]})
    IFS=$OLD_IFS
}

function parse_task_table_headers() {
    OLD_IFS=$IFS
    IFS='|'
    read -r -a task_headers <<< `head -n1 $task_table`
    IFS=$OLD_IFS
    echo "${task_headers[@]}"
}