#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 批量添加git exclude
# @author: 徐宙
# @date: 2024-07-16

# 获取脚本的全路径
script_path="$(realpath $0)"
# 提取脚本所在的目录
bash_dir="$(dirname $script_path)"
source "$bash_dir/task_common.sh"
source "$bash_dir/git_common.sh"

flag=0
git_exclude_config_file="$bash_dir/config/git_exclude"
exclude_content=
projects=()
work_dir=$base_dir

function usage() {
    cat "$bash_dir/usage/batch_exclude.usage"
}

# exclude_with_content <content>
function exclude_with_content() {
    content=$1
    if [ $(grep ^"$content"$ .git/info/exclude | wc -l) != 0 ]; then
        # 判断是否已存在
        success_log "已添加过exclude （$content）"
        return $SUCCESS
    fi
    # 提示是否添加exclude
    if [[ $flag == 0 ]]; then
        get_continue "是否添加exclude（$content）？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
    fi
    echo "$content" >> .git/info/exclude
    success_log "添加exclude （$content） 成功"
}

# exclude_with_project <project_dir>
function exclude_with_project() {
    project_dir=$1
    # 打开文件夹
    cd "$project_dir" || return $FAILED
    curr_dir=$(pwd)
    if [ "$exclude_content" == '' ]; then
        # 遍历文件，每次处理一行
        for line in `cat "$git_exclude_config_file"`; do
            line=`echo $line | tr --delete '\n'`
            line=`echo $line | tr --delete '\r'`
            exclude_with_content "$line"
        done
        return $SUCCESS
    fi
    exclude_with_content $exclude_content
}

# batch_exclude
function batch_exclude() {
    for i in "${!projects[@]}";
    do
        project=${projects[$i]}
        exclude_with_project $work_dir"/"$project
        success_log "-----------------------"
        success_log
    done
}

function main() {
    # 解析参数
    params=`getopt -o hyc: --long content: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -c | --content) exclude_content=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        # 判断配置文件是否存在
        if [[ $exclude_content == '' && ! -f "$git_exclude_config_file" ]]; then
            error_log "git_exclude 配置文件不存在"
            error_log "请在 $bash_dir/config/ 目录下创建 git_exclude 文件"
            exit 0
        fi
        # 获取项目列表
        projects=($(git_directories))
    else
        # 获取任务信息
        get_task $1
        work_dir=${task_info["work_dir"]}
        projects=(${task_projects[*]})
    fi
    # 批量创建分支
    batch_exclude
    exit 0
}

main "$@"

