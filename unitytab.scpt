on run argv
	tell application "iTerm"
		activate
		set myterm to (current terminal)
		tell myterm
			repeat with mysession in sessions
				tell mysession
					set the_name to get name
					if the_name contains "Unity" then
						tell application "System Events"
							keystroke "z" using {control down}
						end tell
						write text "cd ~/workrepos/farm3/branches/dev/src"
						write text "/usr/local/bin/vim --servername UNITY --remote-silent " & item 1 of argv & " " & item 2 of argv 
						write text "fg /usr/local/bin/vim"
						return
					end if
				end tell
			end repeat

			-- make a new session
			-- make new session at the end of sessions)
			set mysession to (launch session "Default Session") 
			tell mysession
				-- set some attributes
				set name to "UNITY"
				-- execute a command
				write text "cd ~/workrepos/farm3/branches/dev/src"
				write text "/usr/local/bin/vim --servername UNITY --remote-silent " & item 1 of argv & " " & item 2 of argv 
			end tell
		end tell
	end tell
end run
