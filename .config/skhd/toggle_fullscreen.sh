# only effect windows on active display
ACTIVE_DISPLAY_ID=$(yabai -m query --spaces | jq '.[] | select(."has-focus" == true).display')
# get the original window
FOCUS_WINDOW_ID=$(yabai -m query --windows | jq ".[] | select(.\"has-focus\"  == "true").id")

# toggle all fullscreened windows which are not the focused window to not full-screened 
for WINDOW_ID in $(yabai -m query --windows | jq ".[] | select(.display == $ACTIVE_DISPLAY_ID and .id != $FOCUS_WINDOW_ID and .\"has-fullscreen-zoom\"  == "true").id")
do
    yabai -m window --focus $WINDOW_ID
    yabai -m window --toggle zoom-fullscreen
done

## toggle the original focused window
yabai -m window --focus $FOCUS_WINDOW_ID
yabai -m window --toggle zoom-fullscreen