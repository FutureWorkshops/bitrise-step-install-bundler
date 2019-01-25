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
echo_details "* gemfile_path: ${gemfile_path}"
echo

validate_required_input "gemfile_path" $gemfile_path

set +e

bundle install

if [[ $? -eq 0 ]]; then
    echo_info "Current bundle can be used to handle the project"
    exit 0
else
	echo_info "Current bundler can't be used to run this project. Updating..."
fi

set -e

if [[ -f $gemfile_path ]]; then
	GEM_BUNDLER_VERSION=$(grep -A1 -E -i -w '(BUNDLED WITH){1,1}' $gemfile_path | grep -E -i -w "[0-9\.]{1,}" | xargs)
	CURRENT_BUNDLER_VERSION=$(bundle --version | grep -o -E -i -w "[0-9\.]{1,}" | xargs)

	if [[ $GEM_BUNDLER_VERSION != $CURRENT_BUNDLER_VERSION ]]; then
		echo_info "Gemfile expected version: ${GEM_BUNDLER_VERSION}"
		echo_info "Current reported version: ${CURRENT_BUNDLER_VERSION}"

		echo_info "Installing bundler, version ${GEM_BUNDLER_VERSION}"
		gem install bundler -v=$GEM_BUNDLER_VERSION --force

        echo_info "Configuring environment"
        bundle install

		if [[ "$(bundle --version | grep -o -E -i -w "[0-9\.]{1,}" | xargs)" == $GEM_BUNDLER_VERSION ]]; then
            bundle check
			echo_done "Updated bundler to version: ${GEM_BUNDLER_VERSION}"
		else
			echo_fail "Failed to update version: $(bunlde --version)"
		fi
	else
		echo_done "Current Bundler follows Gemfile"
	fi
else
	echo_done "No Gemfile to match version"
fi