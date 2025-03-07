<script>
import { GlProgressBar } from '@gitlab/ui';
import { Document } from 'yaml';
import { uniqueId } from 'lodash';
import { merge } from '~/lib/utils/yaml';
import { __ } from '~/locale';
import { isValidStepSeq } from '~/pipeline_wizard/validators';
import YamlEditor from './editor.vue';
import WizardStep from './step.vue';
import CommitStep from './commit.vue';

export const i18n = {
  stepNofN: __('Step %{currentStep} of %{stepCount}'),
  draft: __('Draft: %{filename}'),
  overlayMessage: __(`Start inputting changes and we will generate a
    YAML-file for you to add to your repository`),
};

export default {
  name: 'PipelineWizardWrapper',
  i18n,
  components: {
    GlProgressBar,
    YamlEditor,
    WizardStep,
    CommitStep,
  },
  props: {
    steps: {
      type: Object,
      required: true,
      validator: isValidStepSeq,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    filename: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      highlightPath: null,
      currentStepIndex: 0,
      // TODO: In order to support updating existing pipelines, the below
      // should contain a parsed version of an existing .gitlab-ci.yml.
      // See https://gitlab.com/gitlab-org/gitlab/-/issues/355306
      compiled: new Document({}),
      showPlaceholder: true,
      pipelineBlob: null,
      placeholder: this.getPlaceholder(),
    };
  },
  computed: {
    currentStep() {
      return this.currentStepIndex + 1;
    },
    stepCount() {
      return this.steps.items.length + 1;
    },
    progress() {
      return Math.ceil((this.currentStep / (this.stepCount + 1)) * 100);
    },
    isLastStep() {
      return this.currentStep === this.stepCount;
    },
    stepList() {
      return this.steps.items.map((_, i) => ({
        id: uniqueId(),
        inputs: this.steps.get(i).get('inputs').toJSON(),
        template: this.steps.get(i).get('template', true),
      }));
    },
  },
  watch: {
    isLastStep(value) {
      if (value) this.resetHighlight();
    },
  },
  methods: {
    getStep(index) {
      return this.steps.get(index);
    },
    resetHighlight() {
      this.highlightPath = null;
    },
    onUpdate() {
      this.showPlaceholder = false;
    },
    onEditorUpdate(blob) {
      // TODO: In a later iteration, we could add a loopback allowing for
      //  changes from the editor to flow back into the model
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/355312
      this.pipelineBlob = blob;
    },
    getPlaceholder() {
      const doc = new Document({});
      this.steps.items.forEach((tpl) => {
        merge(doc, tpl.get('template').clone());
      });
      return doc;
    },
  },
};
</script>

<template>
  <div class="row gl-mt-8">
    <main class="col-md-6 gl-pr-8">
      <header class="gl-mb-5">
        <h3 class="text-secondary gl-mt-0" data-testid="step-count">
          {{ sprintf($options.i18n.stepNofN, { currentStep, stepCount }) }}
        </h3>
        <gl-progress-bar :value="progress" variant="success" />
      </header>
      <section class="gl-mb-4">
        <commit-step
          v-show="isLastStep"
          data-testid="step"
          :default-branch="defaultBranch"
          :file-content="pipelineBlob"
          :filename="filename"
          :project-path="projectPath"
          @back="currentStepIndex--"
          @done="$emit('done')"
        />
        <wizard-step
          v-for="(step, i) in stepList"
          v-show="i === currentStepIndex"
          :key="step.id"
          data-testid="step"
          :compiled.sync="compiled"
          :has-next-step="i < steps.items.length"
          :has-previous-step="i > 0"
          :highlight.sync="highlightPath"
          :inputs="step.inputs"
          :template="step.template"
          @back="currentStepIndex--"
          @next="currentStepIndex++"
          @update:compiled="onUpdate"
        />
      </section>
    </main>
    <aside class="col-md-6 gl-pt-3">
      <div
        class="gl-border-1 gl-border-gray-100 gl-border-solid border-radius-default gl-bg-gray-10"
      >
        <h6 class="gl-p-2 gl-px-4 text-secondary" data-testid="editor-header">
          {{ sprintf($options.i18n.draft, { filename }) }}
        </h6>
        <div class="gl-relative gl-overflow-hidden">
          <yaml-editor
            :aria-hidden="showPlaceholder"
            :doc="showPlaceholder ? placeholder : compiled"
            :filename="filename"
            :highlight="highlightPath"
            class="gl-w-full"
            @update:yaml="onEditorUpdate"
          />
          <div
            v-if="showPlaceholder"
            class="gl-absolute gl-top-0 gl-right-0 gl-bottom-0 gl-left-0 gl-filter-blur-1"
            data-testid="placeholder-overlay"
          >
            <div
              class="gl-absolute gl-top-0 gl-right-0 gl-bottom-0 gl-left-0 bg-white gl-opacity-5 gl-z-index-2"
            ></div>
            <div
              class="gl-relative gl-h-full gl-display-flex gl-align-items-center gl-justify-content-center gl-z-index-3"
            >
              <div class="gl-max-w-34">
                <h4 data-testid="filename">{{ filename }}</h4>
                <p data-testid="description">
                  {{ $options.i18n.overlayMessage }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>
  </div>
</template>
