echo "                                                                            
                                                                              
            /¯¯¯¯/|¯¯¯¯|‘'|¯¯¯¯|'|¯¯¯¯|°|¯¯¯¯| |¯¯¯¯\   |¯¯¯¯|'
            \___ '\|____| '| .:|_|   |  |.::.| | .::|\\  | .:.|'
            |¯¯¯¯|\  ¯¯¯\''|   |¯|.:.|  |.:.:| |::..|||/::.. |‘
            |____|/____/|'|____|¯|____| |____| |____| '\_____| 
            |;;;;;;;;'|'|'|;;;||'||;;;| |;;;;| |;;;;|\ |;;;;;| 
            |_________|/ '|___|| ||___|‘|____| |____| \|____ | 

============================================================================
 THE PACKAGE MANAGER YOU AND YOUR DOTFILES WISH YOU HAD AND NOW DO SO YEAH!
============================================================================

"

if [ -e "$HOME/.shin" ]
then
	echo
	echo "Whoa, there!  Looks like you've already installed shin."
	echo "You'll need to be removing that existing install at $HOME/.shin."
	echo
	exit
fi

echo "OK, so basically I'm going to install a few files to ~/.shin and append some
shell goodness to .profile in a safe way.  Is that cool? (yes/no)"

read choice

if [ "$choice" = "yes" ]
then
	echo "OK, creating the directories I need..."
	mkdir -p "$HOME/.shin"
	echo ""

	echo "Now I'm cloning shin..."
	return_to=`$pwd`
	cd "$HOME/.shin"
	git clone git://github.com/jm/shin.git system
	echo ""

	echo "Installing my little shell initializer..."
	touch "$HOME/.profile"
	cat "$HOME/.shin/system/initializer.sh" >> "$HOME/.profile"
	echo ""

	echo "OK, all done!"
	cd $return_to
else
	echo
	echo "Run me again if you end up wanting to install shin!"
	echo
fi