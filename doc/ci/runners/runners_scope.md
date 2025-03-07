---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# The scope of runners **(FREE)**

Runners are available based on who you want to have access:

- [Shared runners](#shared-runners) are available to all groups and projects in a GitLab instance.
- [Group runners](#group-runners) are available to all projects and subgroups in a group.
- [Specific runners](#specific-runners) are associated with specific projects.
  Typically, specific runners are used for one project at a time.

## Shared runners

*Shared runners* are available to every project in a GitLab instance.

Use shared runners when you have multiple jobs with similar requirements. Rather than
having multiple runners idling for many projects, you can have a few runners that handle
multiple projects.

If you are using a self-managed instance of GitLab:

- Your administrator can install and register shared runners by
  going to your project's **Settings > CI/CD**, expanding **Runners**,
  and selecting **Show runner installation instructions**.
  These instructions are also available [in the documentation](https://docs.gitlab.com/runner/install/index.html).
- The administrator can also configure a maximum number of shared runner 
  [CI/CD minutes for each group](../pipelines/cicd_minutes.md#set-the-quota-of-cicd-minutes-for-a-specific-namespace).

If you are using GitLab.com:

- You can select from a list of [shared runners that GitLab maintains](index.md).
- The shared runners consume the [CI/CD minutes](../pipelines/cicd_minutes.md)
  included with your account.

### Enable shared runners for a project

On GitLab.com, [shared runners](index.md) are enabled in all projects by
default.

On self-managed instances of GitLab, an administrator can
[enable them for all new projects](../../user/admin_area/settings/continuous_integration.md#enable-shared-runners-for-new-projects).

For existing projects, an administrator must
[install](https://docs.gitlab.com/runner/install/index.html) and
[register](https://docs.gitlab.com/runner/register/index.html) them.

To enable shared runners for a project:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn on the **Enable shared runners for this project** toggle.

### Enable shared runners for a group

To enable shared runners for a group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn on the **Enable shared runners for this group** toggle.

### Disable shared runners for a project

You can disable shared runners for individual projects or for groups.
You must have the Owner role for the project
or group.

To disable shared runners for a project:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Shared runners** area, turn off the **Enable shared runners for this project** toggle.

Shared runners are automatically disabled for a project:

- If the shared runners setting for the parent group is disabled, and
- If overriding this setting is not permitted at the project level.

### Disable shared runners for a group

To disable shared runners for a group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn off the **Enable shared runners for this group** toggle.
1. Optional. To allow shared runners to be enabled for individual projects or subgroups,
   select **Allow projects and subgroups to override the group setting**.

NOTE:
To re-enable the shared runners for a group, turn on the
**Enable shared runners for this group** toggle.
Then, a user with the Owner or Maintainer role must explicitly change this setting
for each project subgroup or project.

### How shared runners pick jobs

Shared runners process jobs by using a fair usage queue. This queue prevents
projects from creating hundreds of jobs and using all available
shared runner resources.

The fair usage queue algorithm assigns jobs based on the projects that have the
fewest number of jobs already running on shared runners.

**Example 1**

If these jobs are in the queue:

- Job 1 for Project 1
- Job 2 for Project 1
- Job 3 for Project 1
- Job 4 for Project 2
- Job 5 for Project 2
- Job 6 for Project 3

The fair usage algorithm assigns jobs in this order:

1. Job 1 is first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. Job 4 is next, because 4 is now the lowest job number from projects with no running jobs (Project 1 has a job running).
1. Job 6 is next, because 6 is now the lowest job number from projects with no running jobs (Projects 1 and 2 have jobs running).
1. Job 2 is next, because, of projects with the lowest number of jobs running (each has 1), it is the lowest job number.
1. Job 5 is next, because Project 1 now has 2 jobs running and Job 5 is the lowest remaining job number between Projects 2 and 3.
1. Finally is Job 3... because it's the only job left.

---

**Example 2**

If these jobs are in the queue:

- Job 1 for Project 1
- Job 2 for Project 1
- Job 3 for Project 1
- Job 4 for Project 2
- Job 5 for Project 2
- Job 6 for Project 3

The fair usage algorithm assigns jobs in this order:

1. Job 1 is chosen first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. We finish Job 1.
1. Job 2 is next, because, having finished Job 1, all projects have 0 jobs running again, and 2 is the lowest available job number.
1. Job 4 is next, because with Project 1 running a Job, 4 is the lowest number from projects running no jobs (Projects 2 and 3).
1. We finish Job 4.
1. Job 5 is next, because having finished Job 4, Project 2 has no jobs running again.
1. Job 6 is next, because Project 3 is the only project left with no running jobs.
1. Lastly we choose Job 3... because, again, it's the only job left.

## Group runners

Use _group runners_ when you want all projects in a group
to have access to a set of runners.

Group runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

### Create a group runner

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19819) in GitLab 14.10, path changed from **Settings > CI/CD > Runners**.

You can create a group runner for your self-managed GitLab instance or for GitLab.com.
You must have the Owner role for the group.

To create a group runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **CI/CD > Runners**.
1. Note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

### View and manage group runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/37366/) in GitLab 13.2.

You can view and manage all runners for a group, its subgroups, and projects.
You can do this for your self-managed GitLab instance or for GitLab.com.
You must have the Owner role for the group.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **CI/CD > Runners**.

From this page, you can edit, pause, and remove runners from the group, its subgroups, and projects.

### Pause or remove a group runner

You can pause or remove a group runner for your self-managed GitLab instance or for GitLab.com.
You must have the Owner role for the group.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **Pause** or **Remove runner**.
   - If you pause a group runner that is used by multiple projects, the runner pauses for all projects.
   - From the group view, you cannot remove a runner that is assigned to more than one project.
     You must remove it from each project first.
1. On the confirmation dialog, select **OK**.

## Specific runners

Use _specific runners_ when you want to use runners for specific projects. For example,
when you have:

- Jobs with specific requirements, like a deploy job that requires credentials.
- Projects with a lot of CI activity that can benefit from being separate from other runners.

You can set up a specific runner to be used by multiple projects. Specific runners
must be enabled for each project explicitly.

Specific runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

NOTE:
Specific runners do not get shared with forked projects automatically.
A fork *does* copy the CI/CD settings of the cloned repository.

### Create a specific runner

You can create a specific runner for your self-managed GitLab instance or for GitLab.com.

Prerequisite:

- You must have at least the Maintainer role for the project.

To create a specific runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. On the top bar, select **Menu > Projects** and find the project where you want to use the runner.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Specific runners** section, note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

The runner is now enabled for the project.

### Enable a specific runner for a different project

After a specific runner is created, you can enable it for other projects.

Prerequisites:
You must have at least the Maintainer role for:

- The project where the runner is already enabled.
- The project where you want to enable the runner.
- The specific runner must not be [locked](#prevent-a-specific-runner-from-being-enabled-for-other-projects).

To enable a specific runner for a project:

1. On the top bar, select **Menu > Projects** and find the project where you want to enable the runner.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Specific runners** area, by the runner you want, select **Enable for this project**.

You can edit a specific runner from any of the projects it's enabled for.
The modifications, which include unlocking and editing tags and the description,
affect all projects that use the runner.

An administrator can [enable the runner for multiple projects](../../user/admin_area/settings/continuous_integration.md#enable-a-specific-runner-for-multiple-projects).

### Prevent a specific runner from being enabled for other projects

You can configure a specific runner so it is "locked" and cannot be enabled for other projects.
This setting can be enabled when you first [register a runner](https://docs.gitlab.com/runner/register/),
but can also be changed later.

To lock or unlock a specific runner:

1. On the top bar, select **Menu > Projects** and find the project where you want to enable the runner.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Runners**.
1. Find the specific runner you want to lock or unlock. Make sure it's enabled. You cannot lock shared or group runners.
1. Select **Edit** (**{pencil}**).
1. Select the **Lock to current projects** checkbox.
1. Select **Save changes**.
