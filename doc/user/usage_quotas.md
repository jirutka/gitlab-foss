---
type: howto
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Storage usage quota **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/13294) in GitLab 12.0.
> - Moved to GitLab Free.

## Namespace storage limit

Namespaces on GitLab SaaS have a storage limit. For more information, see our [pricing page](https://about.gitlab.com/pricing/).
This limit is not visible on the Usage quotas page, but will be prior to [enforcement](#namespace-storage-limit-enforcement-schedule). Self-managed deployments are not affected.

Storage types that add to the total namespace storage are:

- Git repository
- Git LFS
- Artifacts
- Container registry
- Package registry
- Dependency proxy
- Wiki
- Snippets

If your total namespace storage exceeds the available namespace storage quota, all projects under the namespace are locked. A locked project will not be able to push to the repository, run pipelines and jobs, or build and push packages.

To prevent exceeding the namespace storage quota, you can:

1. Reduce storage consumption by following the suggestions in the [Manage Your Storage Usage](#manage-your-storage-usage) section of this page.
1. Apply for [GitLab for Education](https://about.gitlab.com/solutions/education/join/), [GitLab for Open Source](https://about.gitlab.com/solutions/open-source/join/), or [GitLab for Startups](https://about.gitlab.com/solutions/startups/) if you meet the eligibility requirements.
1. Consider using a [self-managed instance](../subscriptions/self_managed/) of GitLab which does not have these limits on the free tier.
1. [Purchase additional storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer) units at $60/year for 10GB of storage.
1. [Start a trial](https://about.gitlab.com/free-trial/) or [upgrade to GitLab Premium or Ultimate](https://about.gitlab.com/pricing) which include higher limits and features that enable growing teams to ship faster without sacrificing on quality.
1. [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) to learn more about your options and ask questions.

### Namespace storage limit enforcement schedule

Storage limits for GitLab SaaS Free tier namespaces will not be enforced prior to 2022-10-19. Storage limits for GitLab SaaS Paid tier namespaces will not be enforced for prior to 2023-02-15. 

Impacted users are notified via email and in-app notifications at least 60 days prior to enforcement. 

### Project storage limit

Namespaces on a GitLab SaaS **paid** tier (Premium and Ultimate) have a storage limit on their project repositories.
A project's repository has a storage quota of 10 GB. A namespace has either a namespace-level storage limit or a project-level storage limit, but not both.

- Paid tier namespaces have project-level storage limits enforced.
- Free tier namespaces have namespace-level storage limits.

When a project's repository reaches the quota, the project is locked. You cannot push changes to a locked project. To monitor the size of each
repository in a namespace, including a breakdown for each project, you can
[view storage usage](#view-storage-usage). To allow a project's repository to exceed the free quota
you must purchase additional storage. For more details, see [Excess storage usage](#excess-storage-usage).

## View storage usage

You can view storage usage for your project or [namespace](../user/namespace/index.md).

1. Go to your project or namespace:
   - For a project, on the top bar, select **Menu > Projects** and find your project.
   - For a namespace, enter the URL in your browser's toolbar.
1. From the left sidebar, select **Settings > Usage Quotas**.
1. Select the **Storage** tab.

The statistics are displayed. Select any title to view details. The information on this page
is updated every 90 minutes.

If your namespace shows `'Not applicable.'`, push a commit to any project in the
namespace to recalculate the storage.

## Storage usage statistics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68898) project-level graph in GitLab 14.4 [with a flag](../administration/feature_flags.md) named `project_storage_ui`. Disabled by default.
> - Enabled on GitLab.com in GitLab 14.4.
> - Enabled on self-managed in GitLab 14.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71270) in GitLab 14.5.

The following storage usage statistics are available to a maintainer:

- Total namespace storage used: Total amount of storage used across projects in this namespace.
- Total excess storage used: Total amount of storage used that exceeds their allocated storage.
- Purchased storage available: Total storage that has been purchased but is not yet used.

## Manage your storage usage

You can use several methods to manage and reduce your usage for some storage types.

For more information, see the following pages:

- [Reduce package registry storage](packages/package_registry/reduce_package_registry_storage.md)
- [Reduce dependency proxy storage](packages/dependency_proxy/reduce_dependency_proxy_storage.md)
- [Reduce repository size](project/repository/reducing_the_repo_size_using_git.md)
- [Reduce container registry storage](packages/container_registry/reduce_container_registry_storage.md)
- [Reduce container registry data transfers](packages/container_registry/reduce_container_registry_data_transfer.md)
- [Reduce wiki repository size](../administration/wikis/index.md#reduce-wiki-repository-size)

## Excess storage usage

Excess storage usage is the amount that a project's repository exceeds the free storage quota. If no
purchased storage is available the project is locked. You cannot push changes to a locked project.
To unlock a project you must [purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer)
for the namespace. When the purchase is completed, locked projects are automatically unlocked. The
amount of purchased storage available must always be greater than zero.

The **Storage** tab of the **Usage Quotas** page warns you of the following:

- Purchased storage available is running low.
- Projects that are at risk of being locked if purchased storage available is zero.
- Projects that are locked because purchased storage available is zero. Locked projects are
  marked with an information icon (**{information-o}**) beside their name.

### Excess storage example

The following example describes an excess storage scenario for namespace _Example Company_:

| Repository | Storage used | Excess storage | Quota  | Status            |
|------------|--------------|----------------|--------|-------------------|
| Red        | 10 GB        | 0 GB           | 10 GB  | Locked **{lock}** |
| Blue       | 8 GB         | 0 GB           | 10 GB  | Not locked        |
| Green      | 10 GB        | 0 GB           | 10 GB  | Locked **{lock}** |
| Yellow     | 2 GB         | 0 GB           | 10 GB  | Not locked        |
| **Totals** | **30 GB**    | **0 GB**       | -      | -                 |

The Red and Green projects are locked because their repositories have reached the quota. In this
example, no additional storage has yet been purchased.

To unlock the Red and Green projects, 50 GB additional storage is purchased.

Assuming the Green and Red projects' repositories grow past the 10 GB quota, the purchased storage
available decreases. All projects remain unlocked because 40 GB purchased storage is available:
50 GB (purchased storage) - 10 GB (total excess storage used).

| Repository | Storage used | Excess storage | Quota   | Status            |
|------------|--------------|----------------|---------|-------------------|
| Red        | 15 GB        | 5 GB           | 10 GB   | Not locked        |
| Blue       | 14 GB        | 4 GB           | 10 GB   | Not locked        |
| Green      | 11 GB        | 1 GB           | 10 GB   | Not locked        |
| Yellow     | 5 GB         | 0 GB           | 10 GB   | Not locked        |
| **Totals** | **45 GB**    | **10 GB**      | -       | -                 |
