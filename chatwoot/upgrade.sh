#!/bin/bash

if [ -e .env ]
then
    set -a
    export $(sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g" .env) set
    set +a
else
    echo "env vars need to be configured before running this script."
    exit 1
fi

DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

VERSION_PREV=$(node --eval="process.stdout.write(require($PACKAGE_JSON_PATH).version)")

cd "$DIR/chatwoot/chatwoot"
COMMIT_PREV=$(git log --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %s %Cgreen(%cr) %Creset' --abbrev-commit -n 1)
cd "$DIR"

cwctl --upgrade
cwctl --restart

VERSION=$(node --eval="process.stdout.write(require($PACKAGE_JSON_PATH).version)")

cd "$DIR/chatwoot/chatwoot"
COMMIT=$(git log --pretty=format:'%Cred%h%Creset%C(yellow)%d%Creset %s %Cgreen(%cr) %Creset' --abbrev-commit -n 1)
cd "$DIR"

eval SLACK_CHANNEL_ID=${SLACK_CHANNEL_ID}
eval SLACK_TOKEN=${SLACK_TOKEN}

generate_post_data()
{
    cat <<EOF
{
    "channel": "$SLACK_CHANNEL_ID",
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "Chatwoot has been automatically upgraded at \`$HOSTNAME\`."
            }
        },
        {
                        "type": "section",
                        "text": {
                                "type": "mrkdwn",
                                "text": "*Previous version:* \`$(echo $VERSION_PREV)\` \n \`\`\`$(echo $COMMIT_PREV)\`\`\`"
                        }
                },
                {
                        "type": "section",
                        "text": {
                                "type": "mrkdwn",
                                "text": "*Current version:* \`$(echo $VERSION)\` \n \`\`\`$(echo $COMMIT)\`\`\`"
                        }
                }
    ]
}
EOF
}

curl -H "Content-type: application/json" \
    --data "$(generate_post_data)" \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -X POST https://slack.com/api/chat.postMessage