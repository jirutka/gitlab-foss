<script>
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetClosed',
  components: {
    MrWidgetAuthorTime,
    statusIcon,
  },
  props: {
    /* TODO: This is providing all store and service down when it
      only needs metrics and targetBranch */
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="warning" />
    <div class="media-body">
      <mr-widget-author-time
        :action-text="s__('mrWidget|Closed by')"
        :author="mr.metrics.closedBy"
        :date-title="mr.metrics.closedAt"
        :date-readable="mr.metrics.readableClosedAt"
      />
    </div>
  </div>
</template>
