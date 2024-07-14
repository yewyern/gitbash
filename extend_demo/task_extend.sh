# 获取任务分支扩展
# 注意在本shell自定义的方法不能与git_common.sh, task_common.sh, maven_batch_deploy.sh中的相同


# 获取分支
# 任务分支获取使用：task_info["task_br"]
# 环境分支获取使用：task_info[$env"_br"]
# 或者 根据项目从环境分支文件中获取: `get_value_by_key "$branch_env_file" "$project" 0 1`
# get_branch_extend [env [project]]
function get_branch_extend() {
    env=$1
    project=$2
#    branch_env_file=$bash_dir"/config/branch_"$env".txt"
    if [ "$env" == 'pre' ]; then
        user=`git config user.name`
        if [ "$user" == "" ]; then
            error_log "git用户名未配置"
            error_log "可使用 git config --global user.name \"Your Name\"进行全局配置"
            error_log "或使用 git config user.name \"Your Name\"进行单个项目配置"
            return $FAILED
        fi
        # 获取release分支
        res_br=`do_get_branch release $project`
        if [ $? == $FAILED ]; then
            # 有异常，直接结束
            echo $res_br
            return $FAILED
        fi
        if [ "$res_br" == '' ]; then
            echo ""
            return $SUCCESS
        fi
        res_br=$res_br"."$user
        echo $res_br
        return $SUCCESS
    fi
    echo ""
    return $SUCCESS
}