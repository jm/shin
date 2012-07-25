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

function __shin_home() {
	echo "$HOME/.shin"
}

function __shin_init()
{
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
	elif [[ "$install_target" =~ ^http://.* ]]
	then
		echo "Installing $install_target to your bucket..."
		__shin_bucket_install $install_target
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

function __shin_bucket_install() {
	local install_target=$1
	local bucket_path="`__shin_home`/packages/bucket"
	mkdir -p $bucket_path
	touch $bucket_path/shinit.sh
	local script_text=`curl $install_target`

	if [ $? -eq 0 ]
	then
		echo "$script_text" >> $bucket_path/shinit.sh
		__shin_capture_function_list "bucket"
		__shin_regenerate_manifests

		echo "Script installed to your bucket."
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
		git pull

		if [ $? -eq 0 ]
		then
			__shin_capture_function_list $package_name
			__shin_regenerate_manifests

			echo "Package $package_name updated." 
		else
			echo "There was a problem updating $repo.  Make sure the repo still exists on GitHub and you have permission to access it."
		fi

		cd $return_to
	else
		echo "Package $package_name not found."
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
	touch `__shin_home`/packages/bucket/shinit.sh
	${FCEDIT:-${VISUAL:-${EDITOR:-vi}}} `__shin_home`/packages/bucket/shinit.sh
}