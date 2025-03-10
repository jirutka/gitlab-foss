---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Scanning Analyzers **(ULTIMATE)**

Dependency Scanning relies on underlying third-party tools that are wrapped into
what we call "Analyzers". An analyzer is a
[dedicated project](https://gitlab.com/gitlab-org/security-products/analyzers)
that wraps a particular tool to:

- Expose its detection logic.
- Handle its execution.
- Convert its output to the common format.

This is achieved by implementing the [common API](https://gitlab.com/gitlab-org/security-products/analyzers/common).

Dependency Scanning supports the following official analyzers:

- [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)
- [`gemnasium-maven`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-maven)
- [`gemnasium-python`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python)

The analyzers are published as Docker images, which Dependency Scanning uses
to launch dedicated containers for each analysis.

The Dependency Scanning analyzers' current major version number is 2.

Dependency Scanning is pre-configured with a set of **default images** that are
maintained by GitLab, but users can also integrate their own **custom images**.

<!--- start_remove The following content will be removed on remove_date: '2022-08-22' -->

The [`bundler-audit`](https://gitlab.com/gitlab-org/gitlab/-/issues/289832) and [`retire.js`](https://gitlab.com/gitlab-org/gitlab/-/issues/350510) analyzers were deprecated
in GitLab 14.8 and [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86704) in 15.0.
Use Gemnasium instead.

<!--- end_remove -->

## Official default analyzers

Any custom change to the official analyzers can be achieved by using a
[CI/CD variable in your `.gitlab-ci.yml`](index.md#customizing-the-dependency-scanning-settings).

### Using a custom Docker mirror

You can switch to a custom Docker registry that provides the official analyzer
images under a different prefix. For instance, the following instructs Dependency
Scanning to pull `my-docker-registry/gl-images/gemnasium`
instead of `registry.gitlab.com/security-products/gemnasium`.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: my-docker-registry/gl-images
```

This configuration requires that your custom registry provides images for all
the official analyzers.

### Disable specific analyzers

You can select the official analyzers you don't want to run. Here's how to disable
the `gemnasium` analyzer.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  DS_EXCLUDED_ANALYZERS: "gemnasium"
```

### Disabling default analyzers

Setting `DS_EXCLUDED_ANALYZERS` to a list of the official analyzers disables them.
In `.gitlab-ci.yml` define:

```yaml
include:
  template: Security/Dependency-Scanning.gitlab-ci.yml

variables:
  DS_EXCLUDED_ANALYZERS: "gemnasium, gemnasium-maven, gemnasium-python"
```

This is used when one totally relies on [custom analyzers](#custom-analyzers).

## Custom analyzers

You can provide your own analyzers by
defining CI jobs in your CI configuration. For consistency, you should suffix your custom Dependency
Scanning jobs with `-dependency_scanning`. Here's how to add a scanning job that's based on the
Docker image `my-docker-registry/analyzers/nuget` and generates a Dependency Scanning report
`gl-dependency-scanning-report.json` when `/analyzer run` is executed. Define the following in
`.gitlab-ci.yml`:

```yaml
nuget-dependency_scanning:
  image:
    name: "my-docker-registry/analyzers/nuget"
  script:
    - /analyzer run
  artifacts:
    reports:
      dependency_scanning: gl-dependency-scanning-report.json
```

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate custom security scanners into GitLab.

## Analyzers data

The following table lists the data available for the Gemnasium analyzer.

| Property \ Tool                       |      Gemnasium     |
|---------------------------------------|:------------------:|
| Severity                              | 𐄂                  |
| Title                                 | ✓                  |
| File                                  | ✓                  |
| Start line                            | 𐄂                  |
| End line                              | 𐄂                  |
| External ID (for example, CVE)        | ✓                  |
| URLs                                  | ✓                  |
| Internal doc/explanation              | ✓                  |
| Solution                              | ✓                  |
| Confidence                            | 𐄂                  |
| Affected item (for example, class or package) | ✓                  |
| Source code extract                   | 𐄂                  |
| Internal ID                           | ✓                  |
| Date                                  | ✓                  |
| Credits                               | ✓                  |

- ✓ => we have that data
- ⚠ => we have that data, but it's partially reliable, or we need to extract that data from unstructured content
- 𐄂 => we don't have that data, or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous, so they are sometimes
normalized into common values (for example, `severity`, `confidence`, etc).
