<script>
import { GlButton, GlEmptyState, GlLoadingIcon, GlModal, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getParameterByName } from '~/lib/utils/url_utility';
import PipelinesTableComponent from '~/pipelines/components/pipelines_list/pipelines_table.vue';
import { PipelineKeyOptions } from '~/pipelines/constants';
import eventHub from '~/pipelines/event_hub';
import PipelinesMixin from '~/pipelines/mixins/pipelines_mixin';
import PipelinesService from '~/pipelines/services/pipelines_service';
import PipelineStore from '~/pipelines/stores/pipelines_store';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';

export default {
  PipelineKeyOptions,
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    PipelinesTableComponent,
    TablePagination,
  },
  mixins: [PipelinesMixin, glFeatureFlagMixin()],
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    errorStateSvgPath: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
      required: false,
      default: 'child',
    },
    canCreatePipelineInTargetProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    sourceProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    targetProjectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestId: {
      type: Number,
      required: false,
      default: 0,
    },
  },

  data() {
    const store = new PipelineStore();

    return {
      store,
      state: store.state,
      page: getParameterByName('page') || '1',
      requestData: {},
      modalId: 'create-pipeline-for-fork-merge-request-modal',
    };
  },

  computed: {
    shouldRenderTable() {
      return !this.isLoading && this.state.pipelines.length > 0 && !this.hasError;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderEmptyState() {
      return this.state.pipelines.length === 0 && !this.shouldRenderErrorState;
    },
    /**
     * The "Run pipeline" button can only be rendered when:
     * - In MR view -  we use `canCreatePipelineInTargetProject` for that purpose
     * - If the latest pipeline has the `detached_merge_request_pipeline` flag
     *
     * @returns {Boolean}
     */
    canRenderPipelineButton() {
      return this.latestPipelineDetachedFlag;
    },
    isForkMergeRequest() {
      return this.sourceProjectFullPath !== this.targetProjectFullPath;
    },
    isLatestPipelineCreatedInTargetProject() {
      const latest = this.state.pipelines[0];

      return latest?.project?.full_path === `/${this.targetProjectFullPath}`;
    },
    shouldShowSecurityWarning() {
      return (
        this.canCreatePipelineInTargetProject &&
        this.isForkMergeRequest &&
        !this.isLatestPipelineCreatedInTargetProject
      );
    },
    /**
     * Checks if either `detached_merge_request_pipeline` or
     * `merge_request_pipeline` are tru in the first
     * object in the pipelines array.
     *
     * @returns {Boolean}
     */
    latestPipelineDetachedFlag() {
      const latest = this.state.pipelines[0];
      return (
        latest &&
        latest.flags &&
        (latest.flags.detached_merge_request_pipeline || latest.flags.merge_request_pipeline)
      );
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page };
  },
  methods: {
    successCallback(resp) {
      // depending of the endpoint the response can either bring a `pipelines` key or not.
      const pipelines = resp.data.pipelines || resp.data;

      this.store.storePagination(resp.headers);
      this.setCommonData(pipelines);

      if (resp.headers?.['x-total']) {
        const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
          detail: { pipelineCount: resp.headers['x-total'] },
        });

        // notifiy to update the count in tabs
        if (this.$el.parentElement) {
          this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
        }
      }
    },
    /**
     * When the user clicks on the "Run pipeline" button
     * we need to make a post request and
     * to update the table content once the request is finished.
     *
     * We are emitting an event through the eventHub using the old pattern
     * to make use of the code in mixins/pipelines.js that handles all the
     * table events
     *
     */
    onClickRunPipeline() {
      eventHub.$emit('runMergeRequestPipeline', {
        projectId: this.projectId,
        mergeRequestId: this.mergeRequestId,
      });
    },
    tryRunPipeline() {
      if (!this.shouldShowSecurityWarning) {
        this.onClickRunPipeline();
      } else {
        this.$refs.modal.show();
      }
    },
  },
  modal: {
    actionPrimary: {
      text: s__('Pipeline|Run pipeline'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  i18n: {
    runPipelinePopoverTitle: s__('Pipeline|Run merge request pipeline'),
    runPipelinePopoverDescription: s__(
      'Pipeline|To run a merge request pipeline, the jobs in the CI/CD configuration file %{linkStart}must be configured%{linkEnd} to run in merge request pipelines.',
    ),
    runPipelineText: s__('Pipeline|Run pipeline'),
    emptyStateTitle: s__('Pipelines|There are currently no pipelines.'),
  },
  mrPipelinesDocsPath: helpPagePath('ci/pipelines/merge_request_pipelines.md', {
    anchor: 'prerequisites',
  }),
};
</script>
<template>
  <div class="content-list pipelines">
    <gl-loading-icon
      v-if="isLoading"
      :label="s__('Pipelines|Loading pipelines')"
      size="lg"
      class="prepend-top-20"
    />

    <gl-empty-state
      v-else-if="shouldRenderErrorState"
      :svg-path="errorStateSvgPath"
      :title="
        s__(`Pipelines|There was an error fetching the pipelines.
        Try again in a few moments or contact your support team.`)
      "
      data-testid="pipeline-error-empty-state"
    />
    <template v-else-if="shouldRenderEmptyState">
      <gl-empty-state
        :svg-path="emptyStateSvgPath"
        :title="$options.i18n.emptyStateTitle"
        data-testid="pipeline-empty-state"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.runPipelinePopoverDescription">
            <template #link="{ content }">
              <gl-link
                :href="$options.mrPipelinesDocsPath"
                target="_blank"
                data-testid="mr-pipelines-docs-link"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </template>

        <template #actions>
          <div class="gl-vertical-align-middle">
            <gl-button
              variant="confirm"
              :loading="state.isRunningMergeRequestPipeline"
              data-testid="run_pipeline_button"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </gl-empty-state>
    </template>

    <div v-else-if="shouldRenderTable">
      <gl-button
        v-if="canRenderPipelineButton"
        block
        class="gl-mt-3 gl-mb-3 gl-lg-display-none"
        variant="confirm"
        data-testid="run_pipeline_button_mobile"
        :loading="state.isRunningMergeRequestPipeline"
        @click="tryRunPipeline"
      >
        {{ $options.i18n.runPipelineText }}
      </gl-button>

      <pipelines-table-component
        :pipelines="state.pipelines"
        :update-graph-dropdown="updateGraphDropdown"
        :view-type="viewType"
        :pipeline-key-option="$options.PipelineKeyOptions[0]"
      >
        <template #table-header-actions>
          <div v-if="canRenderPipelineButton" class="gl-text-right">
            <gl-button
              data-testid="run_pipeline_button"
              :loading="state.isRunningMergeRequestPipeline"
              @click="tryRunPipeline"
            >
              {{ $options.i18n.runPipelineText }}
            </gl-button>
          </div>
        </template>
      </pipelines-table-component>
    </div>

    <gl-modal
      v-if="canRenderPipelineButton"
      :id="modalId"
      ref="modal"
      :modal-id="modalId"
      :title="s__('Pipelines|Are you sure you want to run this pipeline?')"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="onClickRunPipeline"
    >
      <p>
        {{
          s__(
            'Pipelines|This pipeline will run code originating from a forked project merge request. This means that the code can potentially have security considerations like exposing CI variables.',
          )
        }}
      </p>
      <p>
        {{
          s__(
            "Pipelines|It is recommended the code is reviewed thoroughly before running this pipeline with the parent project's CI resource.",
          )
        }}
      </p>
      <p>
        {{
          s__('Pipelines|If you are unsure, please ask a project maintainer to review it for you.')
        }}
      </p>
      <gl-link
        href="/help/ci/pipelines/merge_request_pipelines.html#run-pipelines-in-the-parent-project-for-merge-requests-from-a-forked-project"
        target="_blank"
      >
        {{ s__('Pipelines|More Information') }}
      </gl-link>
    </gl-modal>

    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="state.pageInfo"
    />
  </div>
</template>
