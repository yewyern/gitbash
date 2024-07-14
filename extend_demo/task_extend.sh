# 获取任务分支扩展
# 注意在本shell自定义的方法不能与git_common.sh, task_common.sh, maven_batch_deploy.sh中的相同


# 获取分支
# get_branch_extend [env [project]]
function get_branch_extend() {
    # demo示例： pre环境分支以 $release_br.$username 命名
    env=$1
    project=$2
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