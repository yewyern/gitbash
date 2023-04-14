function success_log() {
  echo -e "\033[32m $* \033[0m"
}

function error_log() {
  echo -e "\033[31m $* \033[0m"
}

function trim() {
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function get_value_by_key() {
    filename=$1
    key=$2
    sep=$3
    arr=(`grep "^$key$sep" $filename`)
    echo ${arr[1]}
}
