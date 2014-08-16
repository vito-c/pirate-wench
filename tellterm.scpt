on run argv
	tell application "iTerm"
		activate
		set myterm to (current terminal)
		tell myterm
			set mysession to (current session)
			tell mysession
				write text "" & item 1 of argv
			end tell
		end tell
	end tell
end run
