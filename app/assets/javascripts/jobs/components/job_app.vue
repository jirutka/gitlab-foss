<script>
import { GlLoadingIcon, GlIcon, GlSafeHtmlDirective as SafeHtml, GlAlert } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { throttle, isEmpty } from 'lodash';
import { mapGetters, mapState, mapActions } from 'vuex';
import { isScrolledToBottom } from '~/lib/utils/scroll_utils';
import { __, sprintf } from '~/locale';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import delayedJobMixin from '../mixins/delayed_job_mixin';
import EmptyState from './empty_state.vue';
import EnvironmentsBlock from './environments_block.vue';
import ErasedBlock from './erased_block.vue';
import LogTopBar from './job_log_controllers.vue';
import Log from './log/log.vue';
import Sidebar from './sidebar.vue';
import StuckBlock from './stuck_block.vue';
import UnmetPrerequisitesBlock from './unmet_prerequisites_block.vue';

export default {
  name: 'JobPageApp',
  components: {
    CiHeader,
    EmptyState,
    EnvironmentsBlock,
    ErasedBlock,
    GlIcon,
    Log,
    LogTopBar,
    StuckBlock,
    UnmetPrerequisitesBlock,
    Sidebar,
    GlLoadingIcon,
    SharedRunner: () => import('ee_component/jobs/components/shared_runner_limit_block.vue'),
    GlAlert,
  },
  directives: {
    SafeHtml,
  },
  mixins: [delayedJobMixin],
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
    runnerSettingsUrl: {
      type: String,
      required: false,
      default: null,
    },
    deploymentHelpUrl: {
      type: String,
      required: false,
      default: null,
    },
    terminalPath: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
    subscriptionsMoreMinutesUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchResults: [],
    };
  },
  computed: {
    ...mapState([
      'isLoading',
      'job',
      'isSidebarOpen',
      'jobLog',
      'isJobLogComplete',
      'jobLogSize',
      'isJobLogSizeVisible',
      'isScrollBottomDisabled',
      'isScrollTopDisabled',
      'isScrolledToBottomBeforeReceivingJobLog',
      'hasError',
      'selectedStage',
    ]),
    ...mapGetters([
      'headerTime',
      'hasUnmetPrerequisitesFailure',
      'shouldRenderCalloutMessage',
      'shouldRenderTriggeredLabel',
      'hasEnvironment',
      'shouldRenderSharedRunnerLimitWarning',
      'hasJobLog',
      'emptyStateIllustration',
      'isScrollingDown',
      'emptyStateAction',
      'hasOfflineRunnersForProject',
    ]),

    shouldRenderContent() {
      return !this.isLoading && !this.hasError;
    },

    emptyStateTitle() {
      const { emptyStateIllustration, remainingTime } = this;
      const { title } = emptyStateIllustration;

      if (this.isDelayedJob) {
        return sprintf(title, { remainingTime });
      }

      return title;
    },

    shouldRenderHeaderCallout() {
      return this.shouldRenderCalloutMessage && !this.hasUnmetPrerequisitesFailure;
    },

    itemName() {
      return sprintf(__('Job %{jobName}'), { jobName: this.job.name });
    },
  },
  watch: {
    // Once the job log is loaded,
    // fetch the stages for the dropdown on the sidebar
    job(newVal, oldVal) {
      if (isEmpty(oldVal) && !isEmpty(newVal.pipeline)) {
        const stages = this.job.pipeline.details.stages || [];

        const defaultStage = stages.find((stage) => stage && stage.name === this.selectedStage);

        if (defaultStage) {
          this.fetchJobsForStage(defaultStage);
        }
      }
    },
  },
  created() {
    this.throttled = throttle(this.toggleScrollButtons, 100);

    window.addEventListener('resize', this.onResize);
    window.addEventListener('scroll', this.updateScroll);
  },
  mounted() {
    this.updateSidebar();
  },
  beforeDestroy() {
    this.stopPollingJobLog();
    this.stopPolling();
    window.removeEventListener('resize', this.onResize);
    window.removeEventListener('scroll', this.updateScroll);
  },
  methods: {
    ...mapActions([
      'fetchJobsForStage',
      'hideSidebar',
      'showSidebar',
      'toggleSidebar',
      'scrollBottom',
      'scrollTop',
      'stopPollingJobLog',
      'stopPolling',
      'toggleScrollButtons',
      'toggleScrollAnimation',
    ]),
    onResize() {
      this.updateSidebar();
      this.updateScroll();
    },
    updateSidebar() {
      const breakpoint = bp.getBreakpointSize();
      if (breakpoint === 'xs' || breakpoint === 'sm') {
        this.hideSidebar();
      } else if (!this.isSidebarOpen) {
        this.showSidebar();
      }
    },
    updateScroll() {
      if (!isScrolledToBottom()) {
        this.toggleScrollAnimation(false);
      } else if (this.isScrollingDown) {
        this.toggleScrollAnimation(true);
      }

      this.throttled();
    },
    setSearchResults(searchResults) {
      this.searchResults = searchResults;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="qa-loading-animation gl-mt-6" />

    <template v-else-if="shouldRenderContent">
      <div class="build-page" data-testid="job-content">
        <!-- Header Section -->
        <header>
          <div class="build-header top-area">
            <ci-header
              :status="job.status"
              :time="headerTime"
              :user="job.user"
              :has-sidebar-button="true"
              :should-render-triggered-label="shouldRenderTriggeredLabel"
              :item-name="itemName"
              @clickedSidebarButton="toggleSidebar"
            />
          </div>
          <gl-alert
            v-if="shouldRenderHeaderCallout"
            variant="danger"
            class="gl-mt-3"
            :dismissible="false"
          >
            <div v-safe-html="job.callout_message"></div>
          </gl-alert>
        </header>
        <!-- EO Header Section -->

        <!-- Body Section -->
        <stuck-block
          v-if="job.stuck"
          :has-offline-runners-for-project="hasOfflineRunnersForProject"
          :tags="job.tags"
          :runners-path="runnerSettingsUrl"
        />

        <unmet-prerequisites-block
          v-if="hasUnmetPrerequisitesFailure"
          :help-path="deploymentHelpUrl"
        />

        <shared-runner
          v-if="shouldRenderSharedRunnerLimitWarning"
          :quota-used="job.runners.quota.used"
          :quota-limit="job.runners.quota.limit"
          :project-path="projectPath"
          :subscriptions-more-minutes-url="subscriptionsMoreMinutesUrl"
        />

        <environments-block
          v-if="hasEnvironment"
          :deployment-status="job.deployment_status"
          :deployment-cluster="job.deployment_cluster"
          :icon-status="job.status"
        />

        <erased-block
          v-if="job.erased_at"
          data-testid="job-erased-block"
          :user="job.erased_by"
          :erased-at="job.erased_at"
        />

        <div
          v-if="job.archived"
          class="gl-mt-3 gl-py-2 gl-px-3 gl-align-items-center gl-z-index-1 gl-m-auto archived-job"
          :class="{ 'sticky-top gl-border-bottom-0': hasJobLog }"
          data-testid="archived-job"
        >
          <gl-icon name="lock" class="gl-vertical-align-bottom" />
          {{ __('This job is archived. Only the complete pipeline can be retried.') }}
        </div>
        <!-- job log -->
        <div
          v-if="hasJobLog"
          class="build-log-container gl-relative"
          :class="{ 'gl-mt-3': !job.archived }"
        >
          <log-top-bar
            :class="{
              'sidebar-expanded': isSidebarOpen,
              'sidebar-collapsed': !isSidebarOpen,
              'has-archived-block': job.archived,
            }"
            :size="jobLogSize"
            :raw-path="job.raw_path"
            :is-scroll-bottom-disabled="isScrollBottomDisabled"
            :is-scroll-top-disabled="isScrollTopDisabled"
            :is-job-log-size-visible="isJobLogSizeVisible"
            :is-scrolling-down="isScrollingDown"
            :is-complete="isJobLogComplete"
            :job-log="jobLog"
            @scrollJobLogTop="scrollTop"
            @scrollJobLogBottom="scrollBottom"
            @searchResults="setSearchResults"
          />
          <log :job-log="jobLog" :is-complete="isJobLogComplete" :search-results="searchResults" />
        </div>
        <!-- EO job log -->

        <!-- empty state -->
        <empty-state
          v-if="!hasJobLog"
          :illustration-path="emptyStateIllustration.image"
          :illustration-size-class="emptyStateIllustration.size"
          :title="emptyStateTitle"
          :content="emptyStateIllustration.content"
          :action="emptyStateAction"
          :playable="job.playable"
          :scheduled="job.scheduled"
        />
        <!-- EO empty state -->

        <!-- EO Body Section -->
      </div>
    </template>

    <sidebar
      v-if="shouldRenderContent"
      :class="{
        'right-sidebar-expanded': isSidebarOpen,
        'right-sidebar-collapsed': !isSidebarOpen,
      }"
      :erase-path="job.erase_path"
      :artifact-help-url="artifactHelpUrl"
      data-testid="job-sidebar"
    />
  </div>
</template>
