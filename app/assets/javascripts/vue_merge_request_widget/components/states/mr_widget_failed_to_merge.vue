<script>
import { GlButton } from '@gitlab/ui';
import { stripHtml } from '~/lib/utils/text_utility';
import { sprintf, s__, n__ } from '~/locale';
import eventHub from '../../event_hub';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetFailedToMerge',

  components: {
    GlButton,
    statusIcon,
  },

  props: {
    mr: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      timer: 10,
      isRefreshing: false,
      intervalId: null,
    };
  },

  computed: {
    mergeError() {
      const mergeError = this.prepareMergeError(this.mr.mergeError);

      return sprintf(
        s__('mrWidget|%{mergeError}.'),
        {
          mergeError,
        },
        false,
      );
    },
    timerText() {
      return n__(
        'Refreshing in a second to show the updated status...',
        'Refreshing in %d seconds to show the updated status...',
        this.timer,
      );
    },
  },

  mounted() {
    this.intervalId = setInterval(this.updateTimer, 1000);
  },

  created() {
    eventHub.$emit('DisablePolling');
  },

  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  },

  methods: {
    refresh() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested');
      eventHub.$emit('EnablePolling');
    },
    updateTimer() {
      this.timer -= 1;

      if (this.timer === 0) {
        this.refresh();
      }
    },
    prepareMergeError(mergeError) {
      return mergeError
        ? stripHtml(mergeError, ' ')
            .replace(/(\.$|\s+)/g, ' ')
            .trim()
        : '';
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <template v-if="isRefreshing">
      <status-icon status="loading" />
      <span class="media-body bold js-refresh-label"> {{ s__('mrWidget|Refreshing now') }} </span>
    </template>
    <template v-else>
      <status-icon :show-disabled-button="true" status="warning" />
      <div class="media-body space-children">
        <span class="bold">
          <span v-if="mr.mergeError" class="has-error-message" data-testid="merge-error">
            {{ mergeError }}
          </span>
          <span v-else> {{ s__('mrWidget|Merge failed.') }} </span>
          <span :class="{ 'has-custom-error': mr.mergeError }"> {{ timerText }} </span>
        </span>
        <gl-button
          size="small"
          data-testid="merge-request-failed-refresh-button"
          data-qa-selector="merge_request_error_content"
          @click="refresh"
        >
          {{ s__('mrWidget|Refresh now') }}
        </gl-button>
      </div>
    </template>
  </div>
</template>
