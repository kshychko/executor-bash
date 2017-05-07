[#ftl]
[#assign resourceCount = 0]
[#list tiers as tier]
    [#assign tierId = tier.Id]
    [#assign tierName = tier.Name]
    [#if tier.Components??]
        [#list tier.Components?values as component]
            [#if deploymentRequired(component, deploymentUnit)]
                [#assign componentId = getComponentId(component)]
                [#assign componentName = getComponentName(component)]
                [#assign componentType = getComponentType(component)]
                [#assign componentIdStem = formatComponentId(tier, component)]
                [#assign componentNameStem = formatComponentName(tier, component)]
                [#assign componentFullNameStem = formatComponentFullName(tier, component)]
                [#assign multiAZ = component.MultiAZ!solnMultiAZ]
                [#include compositeList]
            [/#if]
        [/#list]
    [/#if]
[/#list]
