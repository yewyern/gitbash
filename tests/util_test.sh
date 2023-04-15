bash_dir=$(dirname "$0")
base_dir=$(pwd)
source $bash_dir"/../util.sh"

function test_get_value_by_key() {
    get_value_by_key $bash_dir"/../config/branch_dev.txt" "pay-center" 0 1
}

test_get_value_by_key