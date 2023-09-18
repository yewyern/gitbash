#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量设置远程url，git迁移时使用
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"

flag=0
remote_file=
work_dir=
projects=()

function usage() {
    cat "$bash_dir/usage/batch_set_remote.usage"
}

function set_remote_with_project() {
    if [ $flag == 0 ]; then
        get_continue "是否进行修改远程url？(y/n)"
        toContinue=$?
        if [ $toContinue == $FAILED ]; then
            return $SUCCESS
        fi
    fi
    project_dir=$1
    target_br=$2
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    success_log "当前目录：$curr_dir"
    # 目标项目git url
    remote_url=$(get_value_by_key "$remote_file" "$project" 0 1)
    if [[ -z "$remote_url" ]]; then
        error_log "未找到项目远程地址，请确认$remote_file 是否正确！"
        return $FAILED
    fi
    git_set_remote $remote_url
}

function batch_set_remote() {
    if [ ! -d "$work_dir" ]; then
        error_log "工作目录：$work_dir 不存在，请确认！"
        exit $FAILED
    fi
    cd "$work_dir" || exit
    for i in "${!projects[@]}"; do
        project=${projects[$i]}
        success_log "当前项目："$project
        set_remote_with_project "$work_dir/$project"
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hyr:w: --long remote-file:,work-dir: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true; do
        case "$1" in
        -h)
            usage
            exit 0
            ;;
        -y)
            flag=1
            shift
            ;;
        -r | --remote-file)
            remote_file=$2
            shift 2
            ;;
        -w | --work-dir)
            work_dir=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 1
            ;;
        esac
    done

    get_task $1
    if [ "$work_dir" == "" ]; then
        work_dir=${task_info["work_dir"]}
    fi
    if [ "$work_dir" == '' ]; then
        usage
        exit 1
    fi
    # remote_file 默认使用remote.txt
    if [ "$remote_file" == '' ]; then
        remote_file="remote.txt"
    fi
    if [ ! -f "$remote_file" ]; then
        # 如果找不到配置文件，在脚本路径下寻找
        if [ ! -f "$bash_dir/config/$remote_file" ]; then
            # 还找不到，报错
            error_log "未找到对应的远程配置文件：$remote_file"
            usage
            exit 1
        fi
        remote_file="$bash_dir/config/$remote_file"
    fi

    remote_file=`realpath "$remote_file"`
    work_dir=`realpath "$work_dir"`
    projects=($(get_value_by_index $remote_file 0))

    batch_set_remote
    exit 0
}

main "$@"