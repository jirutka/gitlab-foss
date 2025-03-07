<script>
import { GlTooltipDirective, GlButton, GlButtonGroup } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { __ } from '~/locale';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlButtonGroup,
  },
  mixins: [discussionNavigation],
  props: {
    blocksMerge: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters([
      'getNoteableData',
      'resolvableDiscussionsCount',
      'unresolvedDiscussionsCount',
      'allResolvableDiscussions',
    ]),
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    allExpanded() {
      return this.allResolvableDiscussions.every((discussion) => discussion.expanded);
    },
    toggleThreadsLabel() {
      return this.allExpanded ? __('Collapse all threads') : __('Expand all threads');
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
  },
  methods: {
    ...mapActions(['setExpandDiscussions']),
    handleExpandDiscussions() {
      this.setExpandDiscussions({
        discussionIds: this.allResolvableDiscussions.map((discussion) => discussion.id),
        expanded: !this.allExpanded,
      });
    },
  },
};
</script>

<template>
  <div
    v-if="resolvableDiscussionsCount > 0"
    ref="discussionCounter"
    class="gl-display-flex discussions-counter"
  >
    <div
      class="gl-display-flex gl-align-items-center gl-pl-4 gl-rounded-base gl-mr-3"
      :class="{
        'gl-bg-orange-50': blocksMerge && !allResolved,
        'gl-bg-gray-50': !blocksMerge || allResolved,
        'gl-pr-4': allResolved,
        'gl-pr-2': !allResolved,
      }"
      data-testid="discussions-counter-text"
    >
      <template v-if="allResolved">
        {{ __('All threads resolved!') }}
      </template>
      <template v-else>
        {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
        <gl-button-group class="gl-ml-3">
          <gl-button
            v-gl-tooltip.hover
            :title="__('Go to previous unresolved thread')"
            :aria-label="__('Go to previous unresolved thread')"
            class="discussion-previous-btn gl-rounded-base! gl-px-2!"
            data-track-action="click_button"
            data-track-label="mr_previous_unresolved_thread"
            data-track-property="click_previous_unresolved_thread_top"
            icon="chevron-lg-up"
            category="tertiary"
            @click="jumpToPreviousDiscussion"
          />
          <gl-button
            v-gl-tooltip.hover
            :title="__('Go to next unresolved thread')"
            :aria-label="__('Go to next unresolved thread')"
            class="discussion-next-btn gl-rounded-base! gl-px-2!"
            data-track-action="click_button"
            data-track-label="mr_next_unresolved_thread"
            data-track-property="click_next_unresolved_thread_top"
            icon="chevron-lg-down"
            category="tertiary"
            @click="jumpToNextDiscussion"
          />
        </gl-button-group>
      </template>
    </div>
    <gl-button-group>
      <gl-button
        v-gl-tooltip
        :title="toggleThreadsLabel"
        :aria-label="toggleThreadsLabel"
        class="toggle-all-discussions-btn"
        :icon="allExpanded ? 'collapse' : 'expand'"
        @click="handleExpandDiscussions"
      />
      <gl-button
        v-if="resolveAllDiscussionsIssuePath && !allResolved"
        v-gl-tooltip
        :href="resolveAllDiscussionsIssuePath"
        :title="__('Create issue to resolve all threads')"
        :aria-label="__('Create issue to resolve all threads')"
        class="new-issue-for-discussion discussion-create-issue-btn"
        icon="issue-new"
      />
    </gl-button-group>
  </div>
</template>
