function shin() {
	case "$1" in
		install)
		__shin_install "$2"
		;;

		uninstall)
		__shin_uninstall "$2"
		;;

		update)
		__shin_update "$2"
		;;

		list)
		__shin_list "$2"
		;;

		bucket)
		__shin_edit_bucket
		;;

		init)
		__shin_init
		;;
	esac	
}

function .install() {
	__shin_install "$1"
}

function .uninstall() {
	__shin_uninstall "$1"
}

function .update() {
	__shin_update "$1"
}

function .list() {
	__shin_list "$1"
}

function .ps1() {
	__shin_set_ps1 "$1"
}

function __shin_home() {
	echo "$HOME/.shin"
}

function __shin_init()
{
	echo "PS1=\"$PS1\"" > `__shin_home`/ps1_reset.sh

	if [ -e "`__shin_home`/sets/all.sh" ]
	then
		source `__shin_home`/sets/all.sh
	fi
}

function __shin_install() {
	local install_target=$1
	local return_to=`pwd`

	mkdir -p `__shin_home`/packages
	cd `__shin_home`/packages

	if [[ "$install_target" =~ "gist.github.com" ]]
	then
 		echo "Installing from Gist repo $install_target..."
 		local repo_name=`echo ${install_target##*/}`
 		__shin_install_from_repo "$install_target" "gist-${repo_name/%.*}"
 	elif [[ "$install_target" =~ ^[0-9]*$ ]]
 	then
 		local gist_repo="git://gist.github.com/$install_target.git"

 		echo "Installing from Gist repo $gist_repo..."
 		__shin_install_from_repo "$install_target" "gist-$install_target"
	elif [[ "$install_target" =~ ^http[s]?://.* ]]
	then
		__shin_http_install "$install_target" "$2"
	elif [[ "$install_target" =~ ^git://.* ]]
	then
		echo "Installing from repo $install_target..."
		echo ""

 		local repo_name=`echo ${install_target##*/}`
		__shin_install_from_repo "$install_target" "${repo_name/%.*}"
 	elif [[ "$install_target" =~ .*/[a-zA-Z0-9\.\-_]* ]]
 	then
 		local repo=$1

		# lolhax
		local user=`dirname $1`
		local repo_name=`basename $1`

		local github_url="git://github.com/$user/$repo_name.git"

 		echo "Installing from GitHub repo $install_target..."
 		__shin_install_from_repo "$github_url" "$repo_name"
 	else 
 		echo "I don't know what you're trying to install."
 	fi

	cd $return_to
}

function __shin_http_install() {
	local install_target=$1
	local install_name=$2

	if [ "$install_name" = "" ]
	then
		local trimmed_install_name=`echo ${install_target##*/}`
		install_name="${trimmed_install_name/%.*}"
	fi

	echo "Installing script as $install_name..."
	echo ""

	local bucket_path="`__shin_home`/packages/$install_name"
	mkdir -p $bucket_path
	local script_text=`curl $install_target`

	if [ $? -eq 0 ]
	then
		echo "$script_text" > $bucket_path/shinit.sh
		echo "Downloaded from $install_target" > $bucket_path/.shin_description
		echo "$install_target" > $bucket_path/.shin_origin 

		__shin_capture_function_list $install_name
		__shin_regenerate_manifests

		echo "$install_name installed."
	else
		echo "There was a problem fetching $install_target."
	fi
}

function __shin_install_from_repo() {
	local clone_url=$1
	local repo_name=$2
	git clone $clone_url $repo_name --depth 1

	if [ $? -eq 0 ]
	then
		__shin_check_package_init $repo_name

		if [ $__shin_package_init_result -eq 1 ]
		then
			if [ -e `__shin_home`/packages/$repo_name/shinstall.sh ]
			then
				source `__shin_home`/packages/$repo_name/shinstall.sh
			fi

			__shin_capture_function_list $repo_name
			__shin_regenerate_manifests

			echo ""
			echo "$repo_name installed."
		fi
	else
		echo "There was a problem cloning $repo.  Make sure the repo exists and you have permission to access it."
	fi
}

function __shin_uninstall() {
	local package_name=$1
	
	if [ -e `__shin_home`/packages/$package_name ]
	then
		rm -rf `__shin_home`/packages/$package_name
		__shin_regenerate_manifests

		echo "Package $package_name uninstalled." 
	else
		echo "Package $package_name not found."
	fi
}

function __shin_update() {
	local package_name=$1
	
	if [ "$package_name" = "self" ]
	then
		__shin_update_self
	else
		__shin_update_package "$package_name"
	fi
}

function __shin_update_self() {
	local return_to=`pwd`
	echo "Updating shin system..."
	echo ""

	cd `__shin_home`/system
	git pull origin master
	source functions.sh

	echo ""
	echo "Updated!"
	cd $return_to
}

function __shin_update_package() {
	local package_name=$1

	if [ -e `__shin_home`/packages/$package_name ]
	then
		local return_to=`pwd`

		cd `__shin_home`/packages/$package_name
		
		if [ -e `__shin_home`/packages/$package_name/.git ]
		then
			__shin_update_repo "$package_name"
		elif [ -e `__shin_home`/packages/$package_name/.shin_origin ]
		then
			__shin_update_http "$package_name"
		else
			echo "No data present to update with.  Aborting!"
		fi

		cd $return_to
	else
		echo "Package $package_name not found."
	fi
}

function __shin_update_http() {
	local package_name=$1

	local package_path="`__shin_home`/packages/$package_name"
	local package_origin="`cat $package_path/.shin_origin`"
	local script_text=`curl $package_origin`

	if [ $? -eq 0 ]
	then
		echo "$script_text" > $package_path/shinit.sh

		__shin_capture_function_list $package_name

		echo "$package_name updated from $package_origin."
	else
		echo "There was a problem updating from $package_origin."
	fi
}

function __shin_update_repo() {
	local package_name=$1
	git pull

	if [ $? -eq 0 ]
	then
		__shin_capture_function_list $package_name
		__shin_regenerate_manifests

		echo "Package $package_name updated." 
	else
		echo "There was a problem updating $repo.  Make sure the repo still exists on GitHub and you have permission to access it."
	fi
}

function __shin_list() {
	if [ -e "`__shin_home`/manifest" ]
	then
		echo "Listing all packages"
		echo ""
		cat `__shin_home`/manifest | while read line ; do
			local name=`echo "$line" | sed "s/\:.*$//"`
	 		local rest=`echo ${line#*:}`

	 		if [ $name = "bucket" ]
	 		then
	 			continue
	 		fi

			echo "[$name]"
			echo "$rest"
			echo ""
		done
	else
		echo "No packages installed."
	fi
}

# We use this to unset functions added by a specific package.  Useful for managing sets of
# functions RVM-style.
function __shin_capture_function_list() {
	mkdir -p `__shin_home`/function_maps

	# Get function list, init package, get function list again
	local existing_function_list=`compgen -A function`

	package_path="`__shin_home`/packages/$1"
	source `__shin_home`/packages/$1/shinit.sh
	local new_function_list=`compgen -A function`

	# Basically diffing the function lists from before and after we init the package
	local new_functions=`comm -13 -i <(echo "$existing_function_list") <(echo "$new_function_list")`
	echo "$new_functions" > `__shin_home`/function_maps/$1
}

# Regenerates our toplevel manifest file so we know which packages we have installed.
function __shin_regenerate_manifests() {
	local package_directories=`find $(__shin_home)/packages -maxdepth 1 -type d | sort -u`
	mkdir -p `__shin_home`/sets

	rm `__shin_home`/sets/all.sh 2>/dev/null
	rm `__shin_home`/manifest 2>/dev/null

	for package in $package_directories
	do
		local package_name=`basename $package`

		# If it's the base directory or "..", skip it.
		if [ "$package_name" = "packages" ] || [ "$package_name" = "" ]
		then
			continue
		fi

		__shin_check_package_init $package_name

		if [ $__shin_package_init_result -eq 0 ]
		then
			break
		fi

		if [ -e `__shin_home`/packages/$package_name/.shin_description ]
		then
			echo "$package_name:$(cat `__shin_home`/packages/$package_name/.shin_description)" >> `__shin_home`/manifest
		else
			echo "$package_name:(No description given.)" >> `__shin_home`/manifest
		fi

		echo "package_path=\"`__shin_home`/packages/$package_name\"" >> `__shin_home`/sets/all.sh
		echo "source `__shin_home`/packages/$package_name/shinit.sh" >> `__shin_home`/sets/all.sh
	done
}

function __shin_check_package_init() {	
	if [ ! -e `__shin_home`/packages/$1/shinit.sh ]
	then
		echo ""
		echo "!!!"
		echo "$1 does not have a shinit.sh file; it's cloned but isn't usable at all."
		echo "Make sure this is a package designed for use with shin."
		echo "!!!"
		__shin_package_init_result=0;
	else
		__shin_package_init_result=1;
	fi
}

function __shin_edit_bucket() {
	mkdir -p `__shin_home`/packages/bucket 2>/dev/null
	touch `__shin_home`/packages/bucket/shinit.sh

	${FCEDIT:-${VISUAL:-${EDITOR:-vi}}} `__shin_home`/packages/bucket/shinit.sh
	source `__shin_home`/packages/bucket/shinit.sh
}

function __shin_set_ps1() {
	local package_name=$1

	if [ "$package_name" = "reset" ]
	then
		source `__shin_home`/ps1_reset.sh
		echo "PS1 reset."
	elif [ -e `__shin_home`/packages/$package_name/ps1.sh ]
	then
		source `__shin_home`/packages/$package_name/ps1.sh
	else
		echo "Package $package_name doesn't have a prompt script."
	fi
}