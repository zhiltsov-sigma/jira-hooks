#!/usr/bin/env bash

#curl -D- -X GET "https://sigma-software.atlassian.net/rest/api/2/issue/BLOG-111/transitions" -u user:pass

# +dictionary

BASE_URL=https://sigma-software.atlassian.net/rest/api/2
AUTH=${JIRA_AUTH}

BACKLOG_ID=11
IN_PROGRESS_ID=31
DEVELOPMENT_DONE_ID=41

# -dictionary

# branch %teamcity.build.vcs.branch.ProWebsite_ProWebsite%


get_issue_id() {
    echo "BLOG-116"
}

transit_issue() {
    ISSUE_ID=$1
    TRANSITION_ID=$2
    curl \
        -X POST "${BASE_URL}/issue/${ISSUE_ID}/transitions" \
        -H "Content-Type: application/json" \
        -u ${JIRA_AUTH} \
        --data "{\"transition\": {\"id\": \"${TRANSITION_ID}\"}}"
}

get_transition_id() {
    echo ${BACKLOG_ID}
    echo ${IN_PROGRESS_ID}
    echo ${DEVELOPMENT_DONE_ID}
}

ISSUE_ID=`get_issue_id`
TRANSITION_ID=`get_transition_id`

if [ -z "${ISSUE_ID}" ] || [ -z "${TRANSITION_ID}" ]
then
    echo "transaction not found"
    exit 0
fi

transit_issue ${ISSUE_ID} ${TRANSITION_ID}
