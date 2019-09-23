[#-- API Gateway --]
[#if commandLineOptions.Deployment.Unit.Name?contains("apigateway") || (allDeploymentUnits!false) ]
    [#assign cloudWatchRoleId = formatAccountRoleId("cloudwatch")]
    [#if deploymentSubsetRequired("genplan", false)]
        [@addDefaultGenerationPlan subsets="template" /]
    [/#if]

    [#if deploymentSubsetRequired("iam", true) && isPartOfCurrentDeploymentUnit(cloudWatchRoleId)]
        [@createRole
            id=cloudWatchRoleId
            trustedServices=["apigateway.amazonaws.com"]
            managedArns=["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
        /]
    [/#if]

    [#if deploymentSubsetRequired("apigateway", true)]
        [#assign apiAccountId = formatAccountResourceId("apiAccount","cloudwatch")]

        [@cfResource
            id=apiAccountId
            type="AWS::ApiGateway::Account"
            properties=
                {
                    "CloudWatchRoleArn" : getReference(cloudWatchRoleId, ARN_ATTRIBUTE_TYPE)
                }
            outputs={}
        /]
    [/#if]
[/#if]

