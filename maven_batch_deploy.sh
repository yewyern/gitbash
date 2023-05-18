#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# 一键切换分支
# @author: 徐宙
# @date: 2020-12-08

bash_dir=$(dirname "$0")
#base_dir=$(pwd)
flag=0
deploy_mode=0
work_dir=
work_branch=
env=
branch_env_file=
maven_setting_env_file=
maven_deploy_type=
group_id=
artifact_id=
artifact_version=
artifact_file=
artifact_pom_file=
repository_url=
repository_id=

source "$bash_dir/git_common.sh"
source "$bash_dir/task_common.sh"
source "$bash_dir/extend/maven_extend.sh"
source "$bash_dir/config/maven.config"

function usage() {
    cat "$bash_dir/usage/maven_batch_deploy.usage"
}

function execute_maven_goals() {
    if [[ "$JAVA_CMD_PATH" == "" || $MAVEN_HOME == "" || $MAVEN_CLASSPATH == "" || $MAVEN_MAIN_CLASS == "" ]]; then
        mvn -s "$maven_setting_env_file" $@
        return $?
    fi
    multiModuleProjectDirectory=$(basename "$(pwd)")
    "$JAVA_CMD_PATH" -classpath "$MAVEN_HOME/$MAVEN_CLASSPATH" \
            -Dclassworlds.conf=$MAVEN_HOME/bin/m2.conf \
            -Dmaven.home=$MAVEN_HOME \
            -Dmaven.multiModuleProjectDirectory=$multiModuleProjectDirectory \
            $MAVEN_MAIN_CLASS \
            -s "$maven_setting_env_file" \
            $@
}

function get_maven_info() {
    group_id=`execute_maven_goals org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.groupId | grep -v "\["`
    artifact_id=`execute_maven_goals org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.artifactId | grep -v "\["`
    artifact_version=`execute_maven_goals org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v "\["`
    maven_deploy_type=`execute_maven_goals org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.packaging | grep -v "\["`
    if [ "$maven_deploy_type" == "jar" ]; then
        maven_deploy_type=jar_and_pom
    fi
}

function maven_package() {
    if [[ $flag == 0 ]]; then
        get_continue "是否需要编译["$group_id":"$artifact_id":"$artifact_version"]？(y/n)"
        if [ $? != $SUCCESS ]; then
            # 跳过编译
            return $SUCCESS
        fi
    fi
    # maven 编译
    success_log "开始编译: ["$group_id":"$artifact_id":"$artifact_version"]"
    execute_maven_goals --update-snapshots clean -DskipTests package
    if [ $? != $SUCCESS ]; then
        error_log "编译["$group_id":"$artifact_id":"$artifact_version"]失败"
        return $FAILED
    else
        success_log "编译["$group_id":"$artifact_id":"$artifact_version"]成功"
        return $SUCCESS
    fi
}

function maven_deploy_default() {
    # maven 发布
    maven_deploy_args="-DgroupId=$group_id -DartifactId=$artifact_id -Dversion=$artifact_version"
    if [ "$maven_deploy_type" == "jar" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=jar -Dfile=$artifact_file"
    elif [ "$maven_deploy_type" == "jar_and_pom" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=jar -Dfile=$artifact_file -DpomFile=$artifact_pom_file"
    elif [ "$maven_deploy_type" == "pom" ]; then
        maven_deploy_args="$maven_deploy_args -Dpackaging=pom -DpomFile=$artifact_pom_file"
    else
        error_log "发布失败, maven_deploy_type 只支持：jar jar_and_pom pom 3种"
        exit 1
    fi
    maven_deploy_args="$maven_deploy_args -Durl=$repository_url -DrepositoryId=$repository_id"
    execute_maven_goals deploy:deploy-file $maven_deploy_args
    return $?
}

function maven_deploy() {
    artifact_file=
    artifact_pom_file=
    if [[ $flag == 0 ]]; then
        get_continue "是否需要发布["$group_id":"$artifact_id":"$artifact_version"]到$env？(y/n)"
        if [ $? != $SUCCESS ]; then
            # 跳过发布
            return $SUCCESS
        fi
    fi
    if [ "$maven_deploy_type" == "jar" ]; then
        artifact_file="target/$artifact_id-$artifact_version.jar"
    elif [ "$maven_deploy_type" == "jar_and_pom" ]; then
        artifact_file="target/$artifact_id-$artifact_version.jar"
        artifact_pom_file="pom.xml"
    elif [ "$maven_deploy_type" == "pom" ]; then
        artifact_pom_file="pom.xml"
    else
        error_log "发布失败, maven_deploy_type 只支持：jar jar_and_pom pom 3种"
        exit 1
    fi
    if [ $deploy_mode == 0 ]; then
        # 默认使用maven 命令发布
        maven_deploy_default
    else
        # 可用于扩展
        maven_deploy_extend
    fi
    if [ $? != $SUCCESS ]; then
        error_log "发布["$group_id":"$artifact_id":"$artifact_version"]到$env 失败"
        return $FAILED
    else
        success_log "发布["$group_id":"$artifact_id":"$artifact_version"]到$env 成功"
        return $SUCCESS
    fi
}

function maven_deploy_with_project() {
    # 查看当前目录下所有包含pom.xml的文件夹名
    # - `find "$(pwd)" -name "pom.xml"`：查找包含pom.xml的文件；
    # - `-printf '%h\n'`：将文件路径去掉文件名，只输出文件夹路径；
    # - `sort -u`：去重并按照字典序排序。
    maven_artifact_dirs=(`find "$(pwd)" -name "pom.xml" -printf '%h\n' | sort -u`)
    for i in "${!maven_artifact_dirs[@]}";
    do
        maven_artifact_dir=${maven_artifact_dirs[$i]}
        cd $maven_artifact_dir || exit
        curr_dir=$(pwd)
        success_log "当前目录：$curr_dir"
        if [[ $flag == 0 ]]; then
            get_continue "是否需要发布？(y/n)"
            if [ $? != $SUCCESS ]; then
                # 快速跳过不发布的项目
                continue
            fi
        fi
        get_maven_info
        maven_package
        if [ $? != $SUCCESS ]; then
            return $FAILED
        fi
        maven_deploy
    done
    return $SUCCESS
}

function switch_branch_with_project() {
    project=$1
    target_br=$2
    # 切换分支
    if [ $flag == 1 ]; then
        git_switch_branch $target_br -y --fetch_before --pull_after --stash prompt
    else
        git_switch_branch $target_br --fetch_before --pull_after --stash prompt
    fi
}

function batch_deploy_maven() {
    for i in "${!task_projects[@]}";
    do
        project=${task_projects[$i]}
        target_branch=$work_branch
        if [ -z "$target_branch" ]; then
            target_branch=$(get_value_by_key "$branch_env_file" "$project" 0 1)
        fi
        if [ -z "$target_branch" ]; then
            error_log "要编译的分支不能为空"
            exit 1
        fi
        # 打开文件夹
        cd "$work_dir/$project" || exit
        curr_dir=$(pwd)
        success_log "当前目录：$curr_dir"
        if [[ $flag == 0 ]]; then
            get_continue "是否需要发布？(y/n)"
            if [ $? != $SUCCESS ]; then
                # 跳过发布
                continue
            fi
        fi
        # 切换到目标分支
        switch_branch_with_project $project $target_branch
        # maven编译
        maven_deploy_with_project $project
        success_log "-----------------------"
        success_log
    done
}


function main() {
    # 解析参数
    params=`getopt -o hyb: -n "$0" -- "$@"`
    [ $? != 0 ] && exit 1
    eval set -- "$params"
    while true ; do
        case "$1" in
            -h) usage; exit 0 ;;
            -y) flag=1; shift ;;
            -b) work_branch=$2; shift 2 ;;
            --) shift; break ;;
            *) usage; exit 1 ;;
        esac
    done
    if [ $# -lt 2 ]; then
        usage
        exit 1
    else
        env=$2
        branch_env_file="$bash_dir/config/branch_$env.txt";
        maven_setting_env_file="$bash_dir/config/settings-$env.xml";
        get_task $1
        work_dir=${task_info["work_dir"]}
        batch_deploy_maven
        exit 0
    fi
}


main "$@"