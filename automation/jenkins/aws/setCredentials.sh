#!/usr/bin/env bash

# Set up the access
#
# This script is designed to be sourced into other scripts
#
# $1 = account to be accessed

CRED_ACCOUNT="${1^^}"

[[ -n "${AUTOMATION_DEBUG}" ]] && set ${AUTOMATION_DEBUG}

case "${ACCOUNT_PROVIDER}" in
    aws)

        # Clear any previous results
        unset AWS_CRED_AWS_ACCESS_KEY_ID_VAR
        unset AWS_CRED_AWS_SECRET_ACCESS_KEY_VAR
        unset AWS_CRED_TEMP_AWS_ACCESS_KEY_ID
        unset AWS_CRED_TEMP_AWS_SECRET_ACCESS_KEY
        unset AWS_CRED_TEMP_AWS_SESSION_TOKEN

        # Determine default maximum validity period - align to role default
        AUTOMATION_ROLE_VALIDITY="${AUTOMATION_ROLE_VALIDITY:-3600}"

        # First check for account specific credentials
        AWS_CRED_OVERRIDE_AWS_ACCESS_KEY_ID_VAR="${CRED_ACCOUNT}_AWS_ACCESS_KEY_ID"
        AWS_CRED_OVERRIDE_AWS_SECRET_ACCESS_KEY_VAR="${CRED_ACCOUNT}_AWS_SECRET_ACCESS_KEY"
        if [[ (-n "${!AWS_CRED_OVERRIDE_AWS_ACCESS_KEY_ID_VAR}") && (-n "${!AWS_CRED_OVERRIDE_AWS_SECRET_ACCESS_KEY_VAR}") ]]; then
            AWS_CRED_AWS_ACCESS_KEY_ID_VAR="${AWS_CRED_OVERRIDE_AWS_ACCESS_KEY_ID_VAR}"
            AWS_CRED_AWS_SECRET_ACCESS_KEY_VAR="${AWS_CRED_OVERRIDE_AWS_SECRET_ACCESS_KEY_VAR})"
        else
            # Check for a global automation user/role
            AWS_CRED_AWS_ACCOUNT_ID_VAR="${CRED_ACCOUNT}_AWS_ACCOUNT_ID"
            AWS_CRED_AUTOMATION_USER_VAR="${CRED_ACCOUNT}_AUTOMATION_USER"
            if [[ -z "${!AWS_CRED_AUTOMATION_USER_VAR}" ]]; then AWS_CRED_AUTOMATION_USER_VAR="AWS_AUTOMATION_USER"; fi
            AWS_CRED_AUTOMATION_ROLE_VAR="${CRED_ACCOUNT}_AUTOMATION_ROLE"
            if [[ -z "${!AWS_CRED_AUTOMATION_ROLE_VAR}" ]]; then AWS_CRED_AUTOMATION_ROLE_VAR="AWS_AUTOMATION_ROLE"; fi
            AWS_CRED_AUTOMATION_ROLE="${!AWS_CRED_AUTOMATION_ROLE_VAR:-codeontap-automation}"

            if [[ (-n ${!AWS_CRED_AWS_ACCOUNT_ID_VAR}) && (-n ${!AWS_CRED_AUTOMATION_USER_VAR}) ]]; then
                # Assume automation role either
                # - using the role we are current running under, or
                # - using credentails associated with the automation user
                # Note that the value for the user is just a way to obtain the access credentials
                # and doesn't have to be the same as the IAM user associated with the credentials
                if [[ "${!AWS_CRED_AUTOMATION_USER_VAR^^}" == "ROLE" ]]; then
                    # Clear any use of previously obtained credentials
                    unset AWS_ACCESS_KEY_ID
                    unset AWS_SECRET_ACCESS_KEY
                else
                    # Not using current role so determine the credentials
                    AWS_CRED_AWS_ACCESS_KEY_ID_VAR="${!AWS_CRED_AUTOMATION_USER_VAR^^}_AWS_ACCESS_KEY_ID"
                    AWS_CRED_AWS_SECRET_ACCESS_KEY_VAR="${!AWS_CRED_AUTOMATION_USER_VAR^^}_AWS_SECRET_ACCESS_KEY"
                    AWS_CRED_AWS_ACCESS_KEY_ID="${!AWS_CRED_AWS_ACCESS_KEY_ID_VAR}"
                    AWS_CRED_AWS_SECRET_ACCESS_KEY="${!AWS_CRED_AWS_SECRET_ACCESS_KEY_VAR}"

                    if [[ (-n ${AWS_CRED_AWS_ACCESS_KEY_ID}) && (-n ${AWS_CRED_AWS_SECRET_ACCESS_KEY}) ]]; then
                        export AWS_ACCESS_KEY_ID="${AWS_CRED_AWS_ACCESS_KEY_ID}"
                        export AWS_SECRET_ACCESS_KEY="${AWS_CRED_AWS_SECRET_ACCESS_KEY}"
                    fi
                fi

                if [[ ("${!AWS_CRED_AUTOMATION_USER_VAR^^}" == "ROLE") ||
                    ((-n ${AWS_CRED_AWS_ACCESS_KEY_ID}) && (-n ${AWS_CRED_AWS_SECRET_ACCESS_KEY})) ]]; then
                    TEMP_CREDENTIAL_FILE="${AUTOMATION_DATA_DIR}/temp_aws_credentials.json"
                    unset AWS_SESSION_TOKEN

                    aws sts assume-role \
                        --role-arn arn:aws:iam::${!AWS_CRED_AWS_ACCOUNT_ID_VAR}:role/${AWS_CRED_AUTOMATION_ROLE} \
                        --role-session-name "$(echo $GIT_USER | tr -cd '[[:alnum:]]' )" \
                        --duration-seconds "${AUTOMATION_ROLE_VALIDITY}" \
                        --output json > ${TEMP_CREDENTIAL_FILE} ||
                        aws sts assume-role \
                            --role-arn arn:aws:iam::${!AWS_CRED_AWS_ACCOUNT_ID_VAR}:role/${AWS_CRED_AUTOMATION_ROLE} \
                            --role-session-name "$(echo $GIT_USER | tr -cd '[[:alnum:]]' )" \
                            --output json > ${TEMP_CREDENTIAL_FILE}
                    unset AWS_ACCESS_KEY_ID
                    unset AWS_SECRET_ACCESS_KEY
                    AWS_CRED_TEMP_AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' < ${TEMP_CREDENTIAL_FILE})
                    AWS_CRED_TEMP_AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' < ${TEMP_CREDENTIAL_FILE})
                    AWS_CRED_TEMP_AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' < ${TEMP_CREDENTIAL_FILE})
                    rm ${TEMP_CREDENTIAL_FILE}
                fi
            fi
        fi
        ;;

    azure)

        az_login_args=()

        # -- Only show output unless debugging --
        if willLog "${LOG_LEVEL_DEBUG}"  ]]; then
            az_login_args+=("--output" "json" )
        else
            az_login_args+=("--output" "none" )
        fi

        # find the method - default to prompt based login
        AZ_AUTOMATION_AUTH_METHOD_VAR="${CRED_ACCOUNT}_AZ_AUTH_METHOD"
        if [[ -z "${!AZ_AUTOMATION_AUTH_METHOD_VAR}" ]]; then AZ_AUTOMATION_AUTH_METHOD_VAR="AZ_AUTH_METHOD"; fi
        AZ_AUTH_METHOD="${!AZ_AUTOMATION_AUTH_METHOD_VAR:-interactive}"

        # lookup the AZ Account
        AZ_ACCOUNT_ID_VAR="${CRED_ACCOUNT}_AZ_ACCOUNT_ID"
        if [[ -n "${!AZ_ACCOUNT_ID_VAR}" ]]; then
            AZ_ACCOUNT_ID="${!AZ_ACCOUNT_ID_VAR}"
        fi

        # Set the tenant if required - By defeault it uses the Tenant Id
        AZ_ACCOUNT_TENANT_OVERRIDE_VAR="${CRED_ACCOUNT}_AZ_TENANT_ID"
        if [[ -n "${!AZ_ACCOUNT_TENANT_OVERRIDE_VAR}" ]]; then
            AZ_TENANT_ID="${!AZ_ACCOUNT_TENANT_OVERRIDE_VAR}"
        fi

        if [[ -n "${AZ_TENANT_ID}" ]]; then
            az_login_args+=("--tenant" "${AZ_TENANT_ID}")
        fi

        case "${AZ_AUTH_METHOD}" in
            service)

                #Account specific creds
                AZ_CRED_OVERRIDE_USERNAME_VAR="${CRED_ACCOUNT}_AZ_USERNAME"
                AZ_CRED_OVERRIDE_PASS_VAR="${CRED_ACCOUNT}_AZ_PASS"

                if [[ ( -n "${!AZ_CRED_OVERRIDE_USERNAME_VAR}") ]]; then
                    AZ_CRED_USERNAME="${!AZ_CRED_OVERRIDE_USERNAME_VAR}"
                    AZ_CRED_PASS="${!AZ_CRED_OVERRIDE_PASS_VAR}"
                else
                    # Tenant wide credentials
                    AZ_CRED_AUTOMATION_USERNAME_VAR="AZ_USERNAME"
                    AZ_CRED_AUTOTMATION_PASS_VAR="AZ_PASS"
                    if [[ -n "${!AZ_CRED_AUTOMATION_USERNAME_VAR}" ]]; then
                        AZ_CRED_USERNAME="${!AZ_CRED_AUTOMATION_USERNAME_VAR}"
                        AZ_CRED_PASS="${!AZ_CRED_AUTOTMATION_PASS_VAR}"
                    fi
                fi

                if [[ (-z "${AZ_CRED_USERNAME}") || ( -z "${AZ_CRED_PASS}") || ( -z "${AZ_TENANT_ID}") ]]; then
                    fatal "Azure Service prinicpal login missing information - requires environment - AZ_USERNAME | AZ_PASS | AZ_TENANT_ID"
                    exit 255
                fi

                az login --service-principal --username "${AZ_CRED_USERNAME}" --password "${AZ_CRED_PASS}" ${az_login_args[@]}
                ;;

            managed)
                az login --identity "${az_login_args[@]}"
                ;;

            interactive)
                az login "${az_login_args[@]}"
                ;;

            none)
                info "Skipping Login to Azure - AZ_AUTH_METHOD = ${AZ_AUTH_METHOD}"
                ;;
        esac
        ;;
esac
