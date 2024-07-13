SUCCESS=0
FAILED=1
username="$(whoami)"

function success_log() {
    echo -e "\033[32m $* \033[0m"
}

function error_log() {
    echo -e "\033[31m $* \033[0m"
}

function trim() {
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function get_continue() {
    # read不能在管道里使用
    read -p "$@" toContinue
    echo
    if [[ "Y" == "$toContinue" || "y" == "$toContinue" ]]; then
        return $SUCCESS
    fi
    return $FAILED
}

# 获取当前目录下所有文件夹
# usage: get_directories
function get_directories() {
    # 在 Bash 中，可以使用如下命令将当前目录下所有目录名保存到一个数组中：
#    dirs=( */ )
    # `*/` 用来匹配所有目录名，保存到 `dirs` 数组中。注意，此时数组中包含的是目录名后面带有 `/` 的字符串，如果需要去掉 `/`，可以使用 `${dirs[@]%/}` 命令。完整示例代码如下：
    dirs=( */ )
    dirs=("${dirs[@]%/}")
    echo "${dirs[@]}"
    # 输出结果为所有目录名，每个目录名占用一行。
}

# get_value_by_key <filename> <key> <key_index> <value_index>
# key_index,value_index 从0开始
function get_value_by_key() {
    filename=$1
    key=$2
    key_index=$3
    value_index=$4
    # grep 出符合条件的多行数据
    # 根据key弱匹配 | 去除#开头的注释行 | 根据kv索引取对应列 | 根据key强匹配 | 取第1行 | 取第2列value
    grep "$key" "$filename" | grep -v '^#' | awk -v n1="$(($key_index+1))" -v n2="$(($value_index+1))" '{print $n1,$n2}' | grep "^$key " | sed -n '1p' | cut -d" " -f2
}

# get_value_by_index <filename> <value_index>
# value_index 从0开始
function get_value_by_index() {
    filename=$1
    value_index=$2
    OLD_IFS=$IFS
    IFS=$'\n'
    lines=(`grep -v '^#' $filename | awk -v N1="$(($value_index + 1))" '{print $N1}'`)
    IFS=$OLD_IFS
    echo "${lines[@]}"
}

# 获取真实的配置文件路径
# 优先从当前路径获取，其次从工作空间获取，最后从脚本路径下的config目录下获取
# get_real_config_path <real_file> [work_dir]
function get_real_config_path() {
    real_file=$1
    work_dir=$2
    if [ "$work_dir" != '' ]; then
        work_dir=`realpath $work_dir`
    fi
    if [ ! -f "$real_file" ]; then
        # 如果当前路径找不到，在工作空间路径下寻找
        if [[ ! -f "$work_dir/$real_file" ]]; then
            # 如果工作空间路径找不到，在脚本路径下寻找
            if [ ! -f "$bash_dir/config/$real_file" ]; then
                # 还找不到，报错
                error_log "未找到对应的配置文件：$real_file"
                return $FAILED
            fi
            echo "$bash_dir/config/$real_file"
            return $SUCCESS
        fi
        echo "$work_dir/$real_file"
        return $SUCCESS
    fi
    echo `realpath "$remote_file"`
    return $SUCCESS
}