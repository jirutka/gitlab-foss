<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import JobStatusToken from './tokens/job_status_token.vue';

export default {
  tokenTypes: {
    status: 'status',
  },
  components: {
    GlFilteredSearch,
  },
  computed: {
    tokens() {
      return [
        {
          type: this.$options.tokenTypes.status,
          icon: 'status',
          title: s__('Jobs|Status'),
          unique: true,
          token: JobStatusToken,
          operators: OPERATOR_IS_ONLY,
        },
      ];
    },
  },
  methods: {
    onSubmit(filters) {
      this.$emit('filterJobsBySearch', filters);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    :placeholder="s__('Jobs|Filter jobs')"
    :available-tokens="tokens"
    @submit="onSubmit"
  />
</template>
