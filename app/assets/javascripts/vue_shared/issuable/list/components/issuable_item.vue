<script>
import { GlLink, GlIcon, GlLabel, GlFormCheckbox, GlSprintf, GlTooltipDirective } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isScopedLabel } from '~/lib/utils/common_utils';
import { differenceInSeconds, getTimeago, SECONDS_IN_DAY } from '~/lib/utils/datetime_utility';
import { isExternal, setUrlFragment } from '~/lib/utils/url_utility';
import { __, n__, sprintf } from '~/locale';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlLink,
    GlIcon,
    GlLabel,
    GlFormCheckbox,
    GlSprintf,
    IssuableAssignees,
    WorkItemTypeIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    hasScopedLabelsFeature: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableSymbol: {
      type: String,
      required: true,
    },
    issuable: {
      type: Object,
      required: true,
    },
    labelFilterParam: {
      type: String,
      required: false,
      default: 'label_name',
    },
    showCheckbox: {
      type: Boolean,
      required: true,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
    showWorkItemTypeIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    issuableId() {
      return getIdFromGraphQLId(this.issuable.id);
    },
    createdInPastDay() {
      const createdSecondsAgo = differenceInSeconds(new Date(this.issuable.createdAt), new Date());
      return createdSecondsAgo < SECONDS_IN_DAY;
    },
    author() {
      return this.issuable.author || {};
    },
    webUrl() {
      return this.issuable.gitlabWebUrl || this.issuable.webUrl;
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    isIssuableUrlExternal() {
      return isExternal(this.webUrl);
    },
    reference() {
      return this.issuable.reference || `${this.issuableSymbol}${this.issuable.iid}`;
    },
    labels() {
      return this.issuable.labels?.nodes || this.issuable.labels || [];
    },
    labelIdsString() {
      return JSON.stringify(this.labels.map((label) => getIdFromGraphQLId(label.id)));
    },
    assignees() {
      return this.issuable.assignees?.nodes || this.issuable.assignees || [];
    },
    createdAt() {
      return getTimeago().format(this.issuable.createdAt);
    },
    timestamp() {
      if (this.issuable.state === 'closed' && this.issuable.closedAt) {
        return this.issuable.closedAt;
      }
      return this.issuable.updatedAt;
    },
    formattedTimestamp() {
      if (this.issuable.state === 'closed' && this.issuable.closedAt) {
        return sprintf(__('closed %{timeago}'), {
          timeago: getTimeago().format(this.issuable.closedAt),
        });
      }
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.issuable.updatedAt),
      });
    },
    issuableTitleProps() {
      if (this.isIssuableUrlExternal) {
        return {
          target: '_blank',
        };
      }
      return {};
    },
    taskStatus() {
      const { completedCount, count } = this.issuable.taskCompletionStatus || {};
      if (!count) {
        return undefined;
      }

      return sprintf(
        n__(
          '%{completedCount} of %{count} checklist item completed',
          '%{completedCount} of %{count} checklist items completed',
          count,
        ),
        { completedCount, count },
      );
    },
    notesCount() {
      return this.issuable.userDiscussionsCount ?? this.issuable.userNotesCount;
    },
    showDiscussions() {
      return typeof this.notesCount === 'number';
    },
    showIssuableMeta() {
      return Boolean(
        this.hasSlotContents('status') ||
          this.hasSlotContents('statistics') ||
          this.showDiscussions ||
          this.issuable.assignees,
      );
    },
    issuableNotesLink() {
      return setUrlFragment(this.webUrl, 'notes');
    },
  },
  methods: {
    hasSlotContents(slotName) {
      // eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots
      return Boolean(this.$slots[slotName]);
    },
    scopedLabel(label) {
      return this.hasScopedLabelsFeature && isScopedLabel(label);
    },
    labelTitle(label) {
      return label.title || label.name;
    },
    labelTarget(label) {
      const value = encodeURIComponent(this.labelTitle(label));
      return `?${this.labelFilterParam}[]=${value}`;
    },
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
  },
};
</script>

<template>
  <li
    :id="`issuable_${issuableId}`"
    class="issue gl-display-flex! gl-px-5!"
    :class="{ closed: issuable.closedAt, today: createdInPastDay }"
    :data-labels="labelIdsString"
    :data-qa-issue-id="issuableId"
  >
    <gl-form-checkbox
      v-if="showCheckbox"
      class="issue-check gl-mr-0"
      :checked="checked"
      :data-id="issuableId"
      @input="$emit('checked-input', $event)"
    >
      <span class="gl-sr-only">{{ issuable.title }}</span>
    </gl-form-checkbox>
    <div class="issuable-main-info">
      <div data-testid="issuable-title" class="issue-title title">
        <gl-icon
          v-if="issuable.confidential"
          v-gl-tooltip
          name="eye-slash"
          :title="__('Confidential')"
          :aria-label="__('Confidential')"
        />
        <gl-icon
          v-if="issuable.hidden"
          v-gl-tooltip
          name="spam"
          :title="__('This issue is hidden because its author has been banned')"
          :aria-label="__('Hidden')"
        />
        <gl-link
          class="issue-title-text"
          dir="auto"
          :href="webUrl"
          data-qa-selector="issuable_title_link"
          v-bind="issuableTitleProps"
        >
          {{ issuable.title }}
          <gl-icon v-if="isIssuableUrlExternal" name="external-link" class="gl-ml-2" />
        </gl-link>
        <span
          v-if="taskStatus"
          class="task-status gl-display-none gl-sm-display-inline-block! gl-ml-3"
          data-testid="task-status"
        >
          {{ taskStatus }}
        </span>
      </div>
      <div class="issuable-info">
        <work-item-type-icon v-if="showWorkItemTypeIcon" :work-item-type="issuable.type" />
        <slot v-if="hasSlotContents('reference')" name="reference"></slot>
        <span v-else data-testid="issuable-reference" class="issuable-reference">
          {{ reference }}
        </span>
        <span class="gl-display-none gl-sm-display-inline">
          <span aria-hidden="true">&middot;</span>
          <span class="issuable-authored gl-mr-3">
            <gl-sprintf v-if="author.name" :message="__('created %{timeAgo} by %{author}')">
              <template #timeAgo>
                <span
                  v-gl-tooltip.bottom
                  :title="tooltipTitle(issuable.createdAt)"
                  data-testid="issuable-created-at"
                >
                  {{ createdAt }}
                </span>
              </template>
              <template #author>
                <slot v-if="hasSlotContents('author')" name="author"></slot>
                <gl-link
                  v-else
                  :data-user-id="authorId"
                  :data-username="author.username"
                  :data-name="author.name"
                  :data-avatar-url="author.avatarUrl"
                  :href="author.webUrl"
                  data-testid="issuable-author"
                  class="author-link js-user-link"
                >
                  <span class="author">{{ author.name }}</span>
                </gl-link>
              </template>
            </gl-sprintf>
            <gl-sprintf v-else :message="__('created %{timeAgo}')">
              <template #timeAgo>
                <span
                  v-gl-tooltip.bottom
                  :title="tooltipTitle(issuable.createdAt)"
                  data-testid="issuable-created-at"
                >
                  {{ createdAt }}
                </span>
              </template>
            </gl-sprintf>
          </span>
          <slot name="timeframe"></slot>
        </span>
        &nbsp;
        <span v-if="labels.length" role="group" :aria-label="__('Labels')">
          <gl-label
            v-for="(label, index) in labels"
            :key="index"
            :background-color="label.color"
            :title="labelTitle(label)"
            :description="label.description"
            :scoped="scopedLabel(label)"
            :target="labelTarget(label)"
            :class="{ 'gl-ml-2': index }"
            size="sm"
          />
        </span>
      </div>
    </div>
    <div class="issuable-meta">
      <ul v-if="showIssuableMeta" class="controls">
        <li v-if="hasSlotContents('status')" class="issuable-status">
          <slot name="status"></slot>
        </li>
        <li v-if="assignees.length">
          <issuable-assignees
            :assignees="assignees"
            :icon-size="16"
            :max-visible="4"
            img-css-classes="gl-mr-2!"
            class="gl-align-items-center gl-display-flex gl-ml-3"
          />
        </li>
        <slot name="statistics"></slot>
        <li
          v-if="showDiscussions"
          data-testid="issuable-discussions"
          class="issuable-comments gl-display-none gl-sm-display-block"
        >
          <gl-link
            v-gl-tooltip.top
            :title="__('Comments')"
            :href="issuableNotesLink"
            :class="{ 'no-comments': !notesCount }"
            class="gl-reset-color!"
          >
            <gl-icon name="comments" />
            {{ notesCount }}
          </gl-link>
        </li>
      </ul>
      <div
        v-gl-tooltip.bottom
        class="gl-text-gray-500 gl-display-none gl-sm-display-inline-block"
        :title="tooltipTitle(timestamp)"
        data-testid="issuable-timestamp"
      >
        {{ formattedTimestamp }}
      </div>
    </div>
  </li>
</template>
