<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    timeAgoTooltip,
  },
  props: {
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedByName: {
      type: String,
      required: false,
      default: '',
    },
    updatedByPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasUpdatedBy() {
      return this.updatedByName && this.updatedByPath;
    },
  },
};
</script>

<template>
  <small class="edited-text js-issue-widgets">
    Edited
    <time-ago-tooltip v-if="updatedAt" :time="updatedAt" tooltip-placement="bottom" />
    <span v-if="hasUpdatedBy">
      by
      <a :href="updatedByPath" class="author-link">
        <span>{{ updatedByName }}</span>
      </a>
    </span>
  </small>
</template>
