[#-- DNS --]

[#-- Resources --]

[#function formatDomainId ids...]
    [#return formatResourceId(
                "domain",
                ids)]
[/#function]

[#function formatDependentDomainId resourceId extensions...]
    [#return formatDependentResourceId(
                "domain",
                resourceId,
                extensions)]
[/#function]

[#function formatSegmentDomainId extensions...]
    [#return formatSegmentResourceId(
                "domain",
                extensions)]
[/#function]

[#function formatComponentDomainId tier component extensions...]
    [#return formatComponentResourceId(
                "domain",
                tier,
                component,
                extensions)]
[/#function]

[#function formatAccountDomainId extensions...]
    [#return formatAccountResourceId(
                "domain",
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatDomainQualifierId ids...]
    [#return formatQualifierAttributeId(
                formatDomainId(ids))]
[/#function]

[#function formatDomainCertificateId ids...]
    [#return formatCertificateAttributeId(
                formatDomainId(ids))]
[/#function]

[#function formatDependentDomainQualifierId resourceId extensions...]
    [#return formatQualifierAttributeId(
                formatDependentDomainId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatDependentDomainCertificateId resourceId extensions...]
    [#return formatCertificateAttributeId(
                formatDependentDomainId(
                    resourceId,
                    extensions))]
[/#function]

[#function formatSegmentDomainQualifierId extensions...]
    [#return formatQualifierAttributeId(
                formatSegmentDomainId(extensions))]
[/#function]

[#function formatSegmentDomainCertificateId extensions...]
    [#return formatCertificateAttributeId(
                formatSegmentDomainId(extensions))]
[/#function]

[#function formatComponentDomainQualifierId tier component extensions...]
    [#return formatQualifierAttributeId(
                formatComponentDomainId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatComponentDomainCertificateId tier component extensions...]
    [#return formatCertificateAttributeId(
                formatComponentDomainId(
                    tier,
                    component,
                    extensions))]
[/#function]

[#function formatAccountDomainQualifierId extensions...]
    [#return formatQualifierAttributeId(
                formatAccountDomainId(extensions))]
[/#function]

[#function formatAccountDomainCertificateId extensions...]
    [#return formatCertificateAttributeId(
                formatAccountDomainId(extensions))]
[/#function]
