<script>
import { parseDocument } from 'yaml';
import WizardWrapper from './components/wrapper.vue';

export default {
  name: 'PipelineWizard',
  components: {
    WizardWrapper,
  },
  props: {
    template: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    defaultFilename: {
      type: String,
      required: false,
      default: '.gitlab-ci.yml',
    },
  },
  computed: {
    parsedTemplate() {
      return this.template ? parseDocument(this.template) : null;
    },
    title() {
      return this.parsedTemplate?.get('title');
    },
    description() {
      return this.parsedTemplate?.get('description');
    },
    filename() {
      return this.parsedTemplate?.get('filename') || this.defaultFilename;
    },
    steps() {
      return this.parsedTemplate?.get('steps');
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-my-8">
      <h1 class="gl-mb-4" data-testid="title">{{ title }}</h1>
      <p class="text-tertiary gl-font-lg gl-max-w-80" data-testid="description">
        {{ description }}
      </p>
    </div>
    <wizard-wrapper
      v-if="steps"
      :default-branch="defaultBranch"
      :filename="filename"
      :project-path="projectPath"
      :steps="steps"
      @done="$emit('done')"
    />
  </div>
</template>
