#!/usr/bin/env bash

#curl -D- -X GET "https://sigma-software.atlassian.net/rest/api/2/issue/BLOG-111/transitions" -u user:pass

# +dictionary

BASE_URL=https://sigma-software.atlassian.net/rest/api/2

IN_PROGRESS_ID=31
IN_REVIEW_ID=51
IN_TEST_ID=61

# -dictionary

BRANCH_NAME="%teamcity.build.branch%"

is_feature_branch() {
    if [[ ${BRANCH_NAME} =~ feature ]]
    then
        return 0
    else
        return 1
    fi
}

is_pull_request() {
    if [[ ${BRANCH_NAME} =~ pull ]]
    then
        return 0
    else
        return 1
    fi
}

get_issue_id() {
    if is_feature_branch
    then
        echo ${BRANCH_NAME} | sed "s:.*feature/\([a-zA-Z0-9-]*\).*:\1:g"
    else
        echo ""
    fi

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

process_commits() {
    return
}

get_transition_id() {
    if is_pull_request
    then
        echo ${IN_REVIEW_ID}
        return
    elif is_feature_branch
    then
        echo ${IN_PROGRESS_ID}
        return
    fi
}

ISSUE_ID=`get_issue_id`
TRANSITION_ID=`get_transition_id`

echo  ${ISSUE_ID} ${TRANSITION_ID}

if [ ! -z "${ISSUE_ID}" ] && [ ! -z "${TRANSITION_ID}" ]
then
    echo "single operation" ${ISSUE_ID} ${TRANSITION_ID}
#    transit_issue ${ISSUE_ID} ${TRANSITION_ID}
    exit 0
fi

get_commits() {
    curl -o ./lastBuild.tmp "%teamcity.serverUrl%/app/rest/buildTypes/id:%system.teamcity.buildType.id%/builds/status:SUCCESS" --user ${TC_AUTH}
    LAST_SUCCESS_COMMIT=`xpath ./lastBuild.tmp '/build/revisions/revision/@version'| awk -F"\"" '{print $2}'`
    rm -f ./lastBuild.tmp
    CURRENT_COMMIT=%build.vcs.number%

    if [ ${LAST_SUCCESS_COMMIT} = ${CURRENT_COMMIT} ]
    then
        ECHO ''
        return
    fi

    COMMITS=`ls -l`
    echo ${COMMITS}
}

get_commits