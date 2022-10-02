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

VERSION_PREV=$(node --eval="process.stdout.write(require($PACKAGE_JSON_PATH).version)")

cwctl --upgrade
cwctl --restart

VERSION=$(node --eval="process.stdout.write(require($PACKAGE_JSON_PATH).version)")

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
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": "*Previous version:* \`$VERSION_PREV\`"
                },
                {
                    "type": "mrkdwn",
                    "text": "*Current version:* \`$VERSION\`"
                }
            ]
        }
    ]
}
EOF
}

echo $(generate_post_data)

curl -H "Content-type: application/json" \
    --data "$(generate_post_data)" \
    -H "Authorization: Bearer $SLACK_TOKEN" \
    -X POST https://slack.com/api/chat.postMessage