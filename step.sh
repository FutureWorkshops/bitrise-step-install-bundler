set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
    color=$1
    msg=$2
    echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
    msg=$1
    echo
    color_echo "${RED}" "${msg}"
    exit 1
}

function echo_warn {
    msg=$1
    color_echo "${YELLOW}" "${msg}"
}

function echo_info {
    msg=$1
    echo
    color_echo "${BLUE}" "${msg}"
}

function echo_details {
    msg=$1
    echo "  ${msg}"
}

function echo_done {
    msg=$1
    color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
    key=$1
    value=$2
    if [ -z "${value}" ] ; then
        echo_fail "[!] Missing required input: ${key}"
    fi
}

function validate_required_input_with_options {
    key=$1
    value=$2
    options=$3

    validate_required_input "${key}" "${value}"

    found="0"
    for option in "${options[@]}" ; do
        if [ "${option}" == "${value}" ] ; then
            found="1"
        fi
    done

    if [ "${found}" == "0" ] ; then
        echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
    fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
echo_details "* gemfilelock_dir: ${gemfilelock_dir}"
echo

validate_required_input "gemfilelock_dir" $gemfilelock_dir

cd "$gemfilelock_dir"

if [[ -f Gemfile.lock ]]; then
	GEM_BUNDLER_VERSION=$(grep -A1 -E -i -w '(BUNDLED WITH){1,1}' Gemfile.lock | grep -E -i -w "[0-9\.]{1,}" | xargs)
	CURRENT_BUNDLER_VERSION=$(bundle --version | grep -o -E -i -w "[0-9\.]{1,}" | xargs)

	if [[ $GEM_BUNDLER_VERSION != $CURRENT_BUNDLER_VERSION ]]; then
		echo_info "Gemfile expected version: ${GEM_BUNDLER_VERSION}"
		echo_info "Current reported version: ${CURRENT_BUNDLER_VERSION}"

        	echo_info "Uninstalling current bundler"
        	gem uninstall bundler --force

		echo_info "Installing bundler, version ${GEM_BUNDLER_VERSION}"
		gem install bundler -v=$GEM_BUNDLER_VERSION --force

		echo_done "Updated bundler to version: ${GEM_BUNDLER_VERSION}"
	else
		echo_done "Current Bundler [$(bundle --version)] follows Gemfile [${GEM_BUNDLER_VERSION}]"
	fi
else
	echo_done "No Gemfile to match version."
fi
