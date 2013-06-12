 #!/bin/sh
enddir=$(
	startdir=$(dirname $1);
	cd $startdir;
	while [[ $PWD != $HOME && $(ls -a | grep '^.git$') != '.git' && $PWD != "/" ]]; do
		cd ..;
	done;
	if [[ $PWD == "/" ]]; then cd $HOME; fi;
	echo $PWD;
);
/usr/local/bin/mvim +"cd $enddir" --remote-silent $1
