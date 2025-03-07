<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlTab } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { fetchPolicies } from '~/lib/graphql';
import getTimelineEvents from './graphql/queries/get_timeline_events.query.graphql';
import { displayAndLogError } from './utils';
import { timelineTabI18n } from './constants';

import CreateTimelineEvent from './create_timeline_event.vue';
import IncidentTimelineEventsList from './timeline_events_list.vue';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLoadingIcon,
    GlTab,
    CreateTimelineEvent,
    IncidentTimelineEventsList,
  },
  i18n: timelineTabI18n,
  inject: ['canUpdate', 'fullPath', 'issuableId'],
  data() {
    return {
      isEventFormVisible: false,
      timelineEvents: [],
    };
  },
  apollo: {
    timelineEvents: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query: getTimelineEvents,
      variables() {
        return {
          fullPath: this.fullPath,
          incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
        };
      },
      update(data) {
        return data.project.incidentManagementTimelineEvents.nodes;
      },
      error(error) {
        displayAndLogError(error);
      },
    },
  },
  computed: {
    timelineEventLoading() {
      return this.$apollo.queries.timelineEvents.loading;
    },
    hasTimelineEvents() {
      return Boolean(this.timelineEvents.length);
    },
    showEmptyState() {
      return !this.timelineEventLoading && !this.hasTimelineEvents;
    },
  },
  methods: {
    hideEventForm() {
      this.isEventFormVisible = false;
    },
    async showEventForm() {
      this.$refs.createEventForm.clearForm();
      this.isEventFormVisible = true;
      await this.$nextTick();
      this.$refs.createEventForm.focusDate();
    },
  },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <gl-loading-icon v-if="timelineEventLoading" size="lg" color="dark" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="showEmptyState"
      :compact="true"
      :description="$options.i18n.emptyDescription"
    />
    <incident-timeline-events-list
      v-if="hasTimelineEvents"
      :timeline-event-loading="timelineEventLoading"
      :timeline-events="timelineEvents"
      @hide-new-timeline-events-form="hideEventForm"
    />
    <create-timeline-event
      v-show="isEventFormVisible"
      ref="createEventForm"
      :has-timeline-events="hasTimelineEvents"
      class="timeline-event-note timeline-event-note-form"
      :class="{ 'gl-pl-0': !hasTimelineEvents }"
      @hide-new-timeline-events-form="hideEventForm"
    />
    <gl-button v-if="canUpdate" variant="default" class="gl-mb-3 gl-mt-7" @click="showEventForm">
      {{ $options.i18n.addEventButton }}
    </gl-button>
  </gl-tab>
</template>
