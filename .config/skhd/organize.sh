#  get number of spaces
MIN_SPACES=4
CURRENT_SPACES=$(yabai -m query --spaces | jq '. | length')
echo $CURRENT_SPACES

# create spaces until we reached the minimum
while [ $CURRENT_SPACES -lt $MIN_SPACES ]
do
    yabai -m space --create
    # add one to CURRENT_SPACES
    CURRENT_SPACES=$((CURRENT_SPACES+1))
done

yabai -m query --windows | jq -c '.[]' | while read -r window; do
    # Extract app and id properties using jq
    APP=$(jq -r '.app' <<< "$window")
    ID=$(jq -r '.id' <<< "$window")
    CURRENT_SPACE=$(jq -r '.space' <<< "$window")
    HAS_FOCUS=$(jq -r '."has-focus"' <<< "$window")

    # switch statement in bash 
    case $APP in
        "Code")
            SPACE=1
            ;;
        "Arc")
            SPACE=2
            ;;
        "Alacritty")
            SPACE=3
            ;;
        "Slack")
            SPACE=4
            ;;
        *)
            SPACE=""
            ;;
    esac

    if [[ $SPACE != "" && $SPACE != $CURRENT_SPACE ]]
    then
        if [[ $HAS_FOCUS == "false" ]]
        then
            yabai -m window --focus $ID
        fi
        yabai -m window --space $SPACE
    fi
done

yabai -m space --focus 1
