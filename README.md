shin
====

Manage those dotfiles and shell snippets like a human, you dirty ape.

## OK, so what?

`shin` is a simple package manager geared towards wrangling all those dotfiles you've got stuck in `.profile` right now.  Instead of a giant file of death, you can now separate them into neat, versionable little packages.

## Installation

To install `shin`, simply run the `install.sh` file from the repo.  You can do so like this:

	wget https://raw.github.com/jm/shin/master/install.sh
	sh install.sh

Or if you're feeling risky:

	curl https://raw.github.com/jm/shin/master/install.sh | sh

The install will do three things:

* Create a directory in your home directory named `.shin`
* Clone a copy of `shin` to `.shin/system`
* Install a small little initializer snippet into the bottom of your `.profile`

Once that's finished up, you should be good to go.

## Usage

There are five basic commands.

### Installing

To install a package into `shin`, it must be built to work with `shin` (see information on package format below; it's simple!).  Once you've got a Git repository you'd like to install from, you can install from it in a couple of ways using the `.install` command (aliased as `shin install`).  If it's a GitHub repository, you can simply give `shin` the `owner/repo` format like so:

	mymachine$ .install jm/silly

You can also give it a Git repo URL straight up if you want:

	mymachine$ .install git://github.com/jm/silly.git

If the package you want to install is hosted on Gist (you can have multiple files in the repo, remember?), you can give `shin` the repo URL or you can give it a Gist number:

	mymachine$ .install 12345

### Uninstalling

To uninstall a package, simply run the `.uninstall` (aliased as `shin uninstall` also) command followed by the package name:

	mymachine$ .uninstall silly

### Updating

Updating a package will go to its origin and pull the `master` branch (I may support other branches later or something, but it's an unlikely addition unless someone makes a compelling patch).  To update a package, run the `.update` command (aliased as `shin update`) followed by the package name:

	mymachine$ .update silly

### Listing

To get a list of all packages, run `.list` (or `shin list`).  One day I'll support in-list searching, but that's pretty far down the list.

### Initializing

If you choose to remove the shell initializer from your `.profile`, you can init the `shin` environment by running `shin init`.

### The bucket

`shin` also has the concept of a "bucket" package.  This package is basically just a holder for any random dotfiles you want to place in there.  For example, let's say you want to add `http://example.com/awesome_script.sh` for use but don't want to build a package with it.  Simply run `.install` followed by the URL:

	mymachine$ .install http://example.com/awesome_script.sh

This will append the contents of the URL to your bucket file.  To edit your bucket file directly in your default editor, simply run `shin bucket`.

## Anatomy of a package

A package is simply a Git repository with a few special files:

	* A `shinit.sh` file (required)
	* Your code (either in the `shinit.sh` or sourced from there)
	* A `.shin_description` file that is a short description of the package

That's all!  The `shinit.sh` file is where the magic happens.  If you need to source anything from there, simply use the `$package_path` variable the loader will expose to your script to source things in the package's path:

	source $package_path/this_file.sh

Otherwise, you can put everything in the `shinit.sh` file.  You should include a `.shin_description` file since one day I may build out an index for these things.

## Contributing and such

Feel free to file issues in the issue tracker here on GitHub; pull requests are, of course, accepted.
