#!/bin/bash

#curl -D- -X GET "https://sigma-software.atlassian.net/rest/api/2/issue/BLOG-111/transitions" -u user:pass

if [ -z ${JIRA_URL} ] || [ -z ${JIRA_AUTH} ] || [ -z ${TC_AUTH} ]
then
    echo "Not enough params"
fi

JIRA_API_URL=${JIRA_URL}/rest/api/2
# +dictionary


IN_PROGRESS_ID=31
IN_REVIEW_ID=51
IN_TEST_ID=61

IN_PROGRESS_KEYWORD=start
IN_REVIEW_KEYWORD=review
IN_TEST_KEYWORD=close

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

get_issue_id_for_branch() {
    if is_feature_branch
    then
        echo ${BRANCH_NAME} | sed "s:.*feature/\([a-zA-Z0-9-]*\).*:\1:g"
    else
        echo ""
    fi
}

get_issue_id_for_commit() {
    COMMIT=$1

    ISSUE_ID=`echo -e "import re; t=re.search('\[([\d\w-]+)\]', '$1')\nif t:\n print(t.group(1))" | python`
    echo ${ISSUE_ID}
}

transit_issue() {
    ISSUE_ID=$1
    TRANSITION_ID=$2
    curl \
        -X POST "${JIRA_API_URL}/issue/${ISSUE_ID}/transitions" \
        -H "Content-Type: application/json" \
        -u ${JIRA_AUTH} \
        --data "{\"transition\": {\"id\": \"${TRANSITION_ID}\"}}"
}

get_transition_for_branch() {
    if is_pull_request
    then
        echo ${IN_REVIEW_KEYWORD}
        return
    elif is_feature_branch
    then
        echo ${IN_PROGRESS_KEYWORD}
        return
    fi
}

perform_transaction() {
    ISSUE_ID=$1
    TRANSACTION_ID=`map_transaction $2`
    if [ ! -z "${ISSUE_ID}" ] && [ ! -z "${TRANSACTION_ID}" ]
    then
        echo "->" ${ISSUE_ID} $2
        transit_issue ${ISSUE_ID} ${TRANSACTION_ID}
    fi
}


transit_blanch_based() {
    ISSUE_ID=`get_issue_id_for_branch`
    TRANSITION=`get_transition_for_branch`
    perform_transaction "${ISSUE_ID}" "${TRANSITION}"
}

map_transaction() {
    if [ "$1" = "${IN_TEST_KEYWORD}" ]
    then
        echo ${IN_TEST_ID}
    elif [ "$1" = "${IN_REVIEW_KEYWORD}" ]
    then
        echo ${IN_REVIEW_ID}
    elif [ "$1" = "${IN_PROGRESS_KEYWORD}" ]
    then
        echo ${IN_PROGRESS_ID}
    else
        echo ""
    fi
}

process_commit() {
    ISSUE_ID=`get_issue_id_for_commit "$1"`
    TRANSACTION=`echo -e "import re; t=re.search('#(\w+)', '$1')\nif t:\n print(t.group(1))" | python`
    perform_transaction ${ISSUE_ID} ${TRANSACTION}
}

process_commits() {
    curl -o ./lastBuild.tmp "%teamcity.serverUrl%/app/rest/buildTypes/id:%system.teamcity.buildType.id%/builds/status:SUCCESS" --user ${TC_AUTH}
    LAST_SUCCESS_COMMIT=`cat ./lastBuild.tmp | xpath '/build/revisions/revision/@version'| awk -F"\"" '{print $2}'`
    CURRENT_COMMIT=%build.vcs.number%

    if [ ${LAST_SUCCESS_COMMIT} = ${CURRENT_COMMIT} ]
    then
        ECHO ${LAST_SUCCESS_COMMIT}
        return
    fi

    git log --pretty=format:"%s" ${LAST_SUCCESS_COMMIT}..${CURRENT_COMMIT} > ./commits.tmp
    while read commit || [[ -n $commit ]]; do
        process_commit "$commit"
    done <./commits.tmp

    rm -f ./lastBuild.tmp
    rm -f ./commits.tmp
}

if is_feature_branch
then
    transit_blanch_based
    exit 0
else
    process_commits
fi
