[#ftl]

[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

[#function getBaselineComponentIds links ]
    [#local ids = {}]
    [#list links as linkName, linkTarget ]
        [#if !linkTarget?has_content]
            [@precondition
                function="getBaselineComponentIds"
                context=links
                detail="Link " + linkName + " has no target"
            /]
            [#continue]
        [/#if]
        [#local linkTargetCore = linkTarget.Core ]
        [#local linkTargetSolution = linkTarget.Configuration.Solution ]
        [#local linkTargetResources = linkTarget.State.Resources ]

        [#switch linkTargetCore.Type]
            [#case BASELINE_DATA_COMPONENT_TYPE ]
                [#local ids += { linkName, linkTargetResources["bucket"].Id }]
                [#break]

            [#case BASELINE_KEY_COMPONENT_TYPE ]
                [#switch linkTargetSolution.Engine ]
                    [#case "cmk" ]
                        [#local ids += { linkName, linkTargetResources["cmk"].Id }]
                        [#break]
                    [#case "ssh" ]
                        [#local ids += { linkName, linkTargetResources["ec2KeyPair"].Id }]
                        [#break]
                    [#case "oai"]
                        [#local ids += { linkName, linkTargetResources["originAccessId"].Id }]
                        [#break]
                [/#switch]
                [#break]

            [#default]
                [@fatal
                    message="Unknown baseline subcomponent when looking up component id"
                    context=linkTarget
                /]
        [/#switch]
    [/#list]
    [#return ids ]
[/#function]

[#function getBaselineLinks occurrence baselineComponentNames activeOnly=true activeRequired=true  ]
    [#local baselineProfile = baselineProfiles[occurrence.Configuration.Solution.Profiles.Baseline] ]

    [#local baselineLinkTargets = {} ]

    [#list baselineProfile as key,value ]
        [#if baselineComponentNames?seq_contains(key)]
            [#switch key?lower_case ]
                [#case "opsdata" ]
                [#case "appdata" ]
                    [#local subComponentType = "DataBucket" ]
                    [#break]

                [#case "encryption" ]
                [#case "sshkey" ]
                [#case "cdnoriginkey" ]
                    [#local subComponentType = "Key" ]
                    [#break]

                [#default]
                    [@fatal
                        message="Unknown baseline subcomponent"
                        context=key
                    /]
            [/#switch]

            [#local baselineLink =
                {
                    "Tier" : "mgmt",
                    "Component" : "baseline",
                    "Instance" : "",
                    "Version" : "",
                    subComponentType : value
                }
            ]
            [#local baselineLinkTarget = getLinkTarget( {}, baselineLink, activeOnly, activeRequired )]

            [#-- Skip missing targets --]
            [#if baselineLinkTarget?has_content]
                [#local baselineLinkTargets += {
                        key : baselineLinkTarget
                    } ]
            [/#if]
        [/#if]
    [/#list]

    [#return baselineLinkTargets ]
[/#function]

[@addComponent
    type=BASELINE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A set of resources required for every segment deployment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Active",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Seed",
                "Children" : [
                    {
                        "Names" : "Length",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=BASELINE_DATA_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A segment shared data store"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Role",
                "Type" : STRING_TYPE,
                "Values" : [ "appdata", "operations" ],
                "Mandatory" : true
            },
            {
                "Names" : "Lifecycles",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Prefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix to apply the lifecycle to"
                    }
                    {
                        "Names" : "Expiration",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    },
                    {
                        "Names" : "Offline",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    }
                ]
            },
            {
                "Names" : "Versioning",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Notifications",
                "Subobjects" : true,
                "Children" : s3NotificationChildConfiguration
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="DataBuckets"
    linkAttributes="DataBucket"
/]

[@addChildComponent
    type=BASELINE_KEY_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Shared security keys for a segment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : [ "cmk", "ssh", "oai" ],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="Keys"
    linkAttributes="Key"
/]
