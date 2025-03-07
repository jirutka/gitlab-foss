<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import userAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    userAvatarImage,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    participants: {
      type: Array,
      required: false,
      default: () => [],
    },
    numberOfLessParticipants: {
      type: Number,
      required: false,
      default: 7,
    },
    showParticipantLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
    lazy: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isShowingMoreParticipants: false,
    };
  },
  computed: {
    lessParticipants() {
      return this.participants.slice(0, this.numberOfLessParticipants);
    },
    visibleParticipants() {
      return this.isShowingMoreParticipants ? this.participants : this.lessParticipants;
    },
    hasMoreParticipants() {
      return this.participants.length > this.numberOfLessParticipants;
    },
    toggleLabel() {
      let label = '';
      if (this.isShowingMoreParticipants) {
        label = __('- show less');
      } else {
        label = sprintf(__('+ %{moreCount} more'), {
          moreCount: this.participants.length - this.numberOfLessParticipants,
        });
      }

      return label;
    },
    participantLabel() {
      return sprintf(
        n__('%{count} participant', '%{count} participants', this.participants.length),
        { count: this.loading ? '' : this.participantCount },
      );
    },
    participantCount() {
      return this.participants.length;
    },
  },
  methods: {
    toggleMoreParticipants() {
      this.isShowingMoreParticipants = !this.isShowingMoreParticipants;
    },
    onClickCollapsedIcon() {
      this.$emit('toggleSidebar');
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="showParticipantLabel"
      v-gl-tooltip.left.viewport
      :title="participantLabel"
      class="sidebar-collapsed-icon"
      @click="onClickCollapsedIcon"
    >
      <gl-icon name="users" />
      <gl-loading-icon v-if="loading" size="sm" />
      <span v-else data-testid="collapsed-count" class="gl-pt-2 gl-px-3 gl-font-sm">
        {{ participantCount }}
      </span>
    </div>
    <div
      v-if="showParticipantLabel"
      class="title hide-collapsed gl-mb-2! gl-line-height-20 gl-font-weight-bold"
    >
      <gl-loading-icon v-if="loading" size="sm" :inline="true" />
      {{ participantLabel }}
    </div>
    <div class="hide-collapsed gl-display-flex gl-flex-wrap">
      <div
        v-for="participant in visibleParticipants"
        :key="participant.id"
        class="participants-author gl-display-inline-block gl-pr-3 gl-pb-3"
      >
        <a :href="participant.web_url || participant.webUrl" class="author-link">
          <user-avatar-image
            :lazy="lazy"
            :img-src="participant.avatar_url || participant.avatarUrl"
            :size="24"
            :tooltip-text="participant.name"
            :img-alt="participant.name"
            css-classes="avatar-inline"
            tooltip-placement="bottom"
          />
        </a>
      </div>
    </div>
    <div v-if="hasMoreParticipants" class="participants-more hide-collapsed">
      <gl-button
        variant="link"
        button-text-classes="gl-text-secondary"
        data-testid="more-participants"
        @click="toggleMoreParticipants"
        >{{ toggleLabel }}</gl-button
      >
    </div>
  </div>
</template>
