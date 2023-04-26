bash_dir=$(dirname "$0")
source $bash_dir"/util.sh"

# 查看当前分支名
function git_current_branch() {
    git symbolic-ref --short -q HEAD
    return $?
}

# 查看分支类型
# 0 - 分支不存在
# 1 - 本地分支，无远程
# 2 - 远程分支
function git_branch_type() {
    # 判断远程分支是否存在
    if [ $(git ls-remote --heads $(git remote | head -1) "$1" | cut -d$'\t' -f2 | sed 's,refs/heads/,,' | grep ^"$1"$ | wc -l) != 0 ]; then
        echo 2
    # 判断只存在于本地，没有远程的分支
    elif [ -z "$(git branch --list $1)" ]; then
        echo 0
    else
        echo 1
    fi
    return 0
}

function is_git_repository() {
    git status > /dev/null
    if [ $? != $SUCCESS ]; then
        error_log "** 非git仓库"
        return $FAILED
    fi
}

# 确认当前分支类型，如果是远程分支，推送到远程
function git_status_ok() {
    is_git_repository
    if [ $? != $SUCCESS ]; then
        return $FAILED
    fi
    if [[ -n "$(git status --porcelain)" ]]; then
        error_log "** 有内容修改未提交"
        return $FAILED
    fi
    return $SUCCESS
}

# 保存工作空间
function git_stash() {
    git stash
    git_status_ok
    return $?
}

# 还原工作空间
function git_stash_apply() {
    git stash apply
    return $?
}

# 设置远程url
function git_set_remote() {
    if [ $# -lt 1 ]; then
        exit $FAILED
    fi
    git remote set-url origin $1
    return $?
}

# 获取远程url
function git_get_remote() {
    is_git_repository
    if [ $? != $SUCCESS ]; then
        return $FAILED
    fi
    git remote -v | grep fetch | awk '{print $2}'
}

# 确认当前分支类型，如果是远程分支，拉取远程分支
function git_pull() {
    git_status_ok
    if [ $? == $FAILED ]; then
        error_log "** 无法更新远程分支到本地"
        return $FAILED
    fi
    curr_branch=$(git_current_branch)
    branch_type=$(git_branch_type "$curr_branch")
    if [ $branch_type == 2 ]; then
        # 更新远程分支到本地
        git pull --rebase
        if [ $? != $SUCCESS ]; then
            error_log "** 更新远程仓库到本地失败"
            return $FAILED
        fi
    fi
    return $SUCCESS
}

# 确认当前分支类型，如果是远程分支，推送到远程
function git_push() {
    curr_branch=$(git_current_branch)
    branch_type=$(git_branch_type "$curr_branch")
    if [ $branch_type == 2 ]; then
        # 更新远程分支到本地
        git push
        if [ $? == $SUCCESS ]; then
            success_log "已推送分支 $curr_branch 到远程"
            return $SUCCESS
        fi
        return $FAILED
    fi
    return $SUCCESS
}

# 切换git分支
# git_switch_branch <switch_target_branch> [--fetch_before|--fb] [--pull_after|--pa] [--stash <prompt|force|reject>]
function git_switch_branch() {
    # 解析参数
    params=`getopt -o yY --long fetch_before,pull_after,stash: -n "$0" -- "$@"`
    [ $? != 0 ] && return 1
    eval set -- "$params"
    checkout_prompt=1
    stash_strategy="reject"
    fetch_before=0
    pull_after=0
    while true ; do
        case "$1" in
            -y|-Y) checkout_prompt=0; shift ;;
            --stash) stash_strategy=$2; shift 2 ;;
            --fb | --fetch_before) fetch_before=1; shift ;;
            --pa | --pull_after) pull_after=1; shift ;;
            --) shift; break ;;
            *) return 1 ;;
        esac
    done

    if [ $# -lt 1 ]; then
        success_log "分支为空，不切换"
        return 1
    fi

    switch_target_branch=$1
    success_log "切换到分支："$switch_target_branch
    # 如果分支相同无需切换
    if [ "$(git_current_branch)" == "$switch_target_branch" ]; then
        success_log "分支相同，无需切换"
        if [ $pull_after == 1 ]; then
            git_pull
        fi
        return 0
    fi

    # 切换前fetch
    if [ $fetch_before == 1 ]; then
        git fetch
    fi

    branch_type=$(git_branch_type "$switch_target_branch")
    if [[ $branch_type == 0 ]]; then
        error_log "** 分支不存在，请检查是否添加过分支"
        return 1
    fi

    # 提示是否需要切换
    if [[ $checkout_prompt == 1 ]]; then
        get_continue "是否进行切换？(y/n)"
        toContinue=$?
        if [ $toContinue == $FAILED ]; then
            return $SUCCESS
        fi
    fi

    git_status_ok
    needStash=$?
    # 如果有内容修改，根据策略进行stash
    if [ $needStash == 1 ]; then
        if [[ "$stash_strategy" == 'reject' || "$stash_strategy" == 'prompt' ]]; then
            error_log "** 有内容修改未提交"
            error_log "** 请确认是否需要切换，如确认切换，将使用git stash保存空间之后，再切换分支"
            error_log "** 反之，请确认提交，或保存之后，再切换分支"
        fi
        if [ "$stash_strategy" == 'reject' ]; then
            return $FAILED
        fi
        if [ "$stash_strategy" == 'prompt' ]; then
            get_continue "是否进行stash？(y/n)"
            if [ $? == $FAILED ]; then
                return $FAILED
            fi
        fi
        git_stash
        if [ $? == $FAILED ]; then
            error_log "** 使用git stash保存空间失败，无法切换分支"
            return $FAILED
        fi
    fi

    git switch "$switch_target_branch"
    curr_branch=$(git_current_branch)
    if [ "$(git_current_branch)" != "$switch_target_branch" ]; then
        error_log "** 切换分支失败，当前分支：$curr_branch"
        return $FAILED
    fi
    success_log "切换成功，当前分支：$curr_branch"
    # 切换后pull
    if [ $pull_after == 1 ]; then
        git_pull
    fi
    # 切换后还原工作空间
    if [ $needStash = 1 ]; then
        get_continue "有保存的工作空间，是否需要还原？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
        git_stash_apply
    fi
}

# 合并分支
# git_merge_branch <merge_source_branch> <merge_target_branch> [-y]
function git_merge_branch() {
    # 解析参数
    params=`getopt -o yY -n "$0" -- "$@"`
    [ $? != 0 ] && return 1
    eval set -- "$params"
    merge_prompt=1
    while true ; do
        case "$1" in
            -y|-Y) merge_prompt=0; shift ;;
            --) shift; break ;;
            *) return 1 ;;
        esac
    done

    merge_source_branch=$1
    merge_target_branch=$2
    success_log "源分支：$merge_source_branch"
    success_log "目标分支：$merge_target_branch"
    # 分支为空，不合并
    if [[ -z "$merge_source_branch" ]]; then
        success_log "源分支为空，不合并"
        return $FAILED
    fi
    if [[ -z "$merge_target_branch" ]]; then
        success_log "目标分支为空，不合并"
        return $FAILED
    fi
    # 如果分支一样的无需合并
    if [ "$merge_source_branch" == "$merge_target_branch" ]; then
        success_log "分支相同无需合并"
        return $FAILED
    fi

    # 判断是否存在未提交的文件
    if [[ $merge_prompt == 1 ]]; then
        get_continue "是否进行合并？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
    fi

    # 切换到源分支
    git_switch_branch $merge_source_branch -y --fetch_before --pull_after
    if [ $? == $FAILED ]; then
        return $FAILED
    fi
    # 切换到目标分支
    git_switch_branch $merge_target_branch -y --fetch_before --pull_after
    if [ $? == $FAILED ]; then
        return $FAILED
    fi
    # 判断是否已经合并成功
    git merge-base --is-ancestor $merge_source_branch HEAD
    if [ $? == 0 ]; then
        success_log "分支已经合并无需再次合并"
        return $SUCCESS
    fi
    project=$(basename "$(pwd)")
    # 合并分支
    git merge $merge_source_branch
    git_status_ok
    if [ $? == $FAILED ]; then
        error_log "合并$project分支$merge_source_branch到$merge_target_branch，存在冲突"
        return 0
    fi
    success_log "合并$project分支$merge_source_branch到$merge_target_branch成功"
    # 推送到远程
    git_push
    return $?
}


# 合并分支
# git_create_branch <create_source_branch> <create_target_branch> [-y]
function git_create_branch() {
    # 解析参数
    params=`getopt -o yYp -n "$0" -- "$@"`
    [ $? != 0 ] && return $FAILED
    eval set -- "$params"
    create_prompt=1
    while true ; do
        case "$1" in
            -y|-Y) create_prompt=0; shift ;;
            --) shift; break ;;
            *) return $FAILED ;;
        esac
    done

    create_source_branch=$1
    create_target_branch=$2
    success_log "源分支：$create_source_branch"
    success_log "目标分支：$create_target_branch"
    # 分支为空，不创建
    if [[ -z "$create_source_branch" ]]; then
        error_log "** 源分支为空，不创建"
        return $FAILED
    fi
    if [[ -z "$create_target_branch" ]]; then
        error_log "** 目标分支为空，不创建"
        return $FAILED
    fi
    # 如果分支一样的无需创建
    if [ "$create_source_branch" == "$create_target_branch" ]; then
        error_log "** 分支相同无需创建"
        return $FAILED
    fi

    # 如果分支存在，不创建
    branch_type=$(git_branch_type "$create_target_branch")
    if [[ $branch_type != 0 ]]; then
        success_log "分支已存在，不需要创建"
        return $SUCCESS
    fi

    # 判断是否存在未提交的文件
    if [[ $create_prompt == 1 ]]; then
        get_continue "是否进行创建？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
    fi

    # 切换到源分支
    git_switch_branch $create_source_branch -y --fetch_before --pull_after
    if [ $? == $FAILED ]; then
        return $FAILED
    fi

    # 创建目标分支
    git checkout -b $create_target_branch

    # 判断是否创建成功
    curr_branch=$(git_current_branch)
    if [ "$curr_branch" != "$create_target_branch" ]; then
        error_log "分支创建失败，请手工处理"
        return $FAILED
    fi
    project=$(basename "$(pwd)")
    success_log "基于$project 分支 $create_source_branch 创建 $create_target_branch 成功"

    # 判断是否要推送远程
    remote_url=`git_get_remote`
    if [ "$curr_branch" == "" ]; then
        # 不存在远程url，不推送
        return $SUCCESS
    fi
    if [[ $create_prompt == 1 ]]; then
        get_continue "是否推送远程？(y/n)"
        if [ $? == $FAILED ]; then
            return $SUCCESS
        fi
    fi
    # 推送到远程
    git_push
    if [ $? == 0 ]; then
        success_log "已推送分支 $curr_branch 到远程"
        return $SUCCESS
    fi
    error_log "推送分支 $curr_branch 到远程失败"
    return $FAILED
}