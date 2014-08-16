tell application "iTerm"
	activate
	set myterm to (current terminal)
	tell myterm
		set mysession to (current session)
		tell mysession
			tell application "System Events"
				keystroke key code 53
			end tell
			tell application "System Events"
				keystroke "z" using {control down}
			end tell
		end tell
	end tell
end tell
