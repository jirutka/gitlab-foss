<script>
import { GlDatepicker, GlFormInput, GlFormGroup, GlButton, GlIcon } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { timelineFormI18n } from './constants';
import { getUtcShiftedDateNow } from './utils';

export default {
  name: 'TimelineEventsForm',
  restrictedToolBarItems: [
    'quote',
    'strikethrough',
    'bullet-list',
    'numbered-list',
    'task-list',
    'collapsible-section',
    'table',
    'full-screen',
  ],
  components: {
    MarkdownField,
    GlDatepicker,
    GlFormInput,
    GlFormGroup,
    GlButton,
    GlIcon,
  },
  i18n: timelineFormI18n,
  directives: {
    autofocusonshow,
  },
  props: {
    hasTimelineEvents: {
      type: Boolean,
      required: true,
    },
    isEventProcessed: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    // if occurredAt is undefined, returns "now" in UTC
    const placeholderDate = getUtcShiftedDateNow();

    return {
      timelineText: '',
      placeholderDate,
      hourPickerInput: placeholderDate.getHours(),
      minutePickerInput: placeholderDate.getMinutes(),
      datepickerTextInput: null,
    };
  },
  computed: {
    occurredAt() {
      const [years, months, days] = this.datepickerTextInput.split('-');
      const utcDate = new Date(
        Date.UTC(years, months - 1, days, this.hourPickerInput, this.minutePickerInput),
      );

      return utcDate.toISOString();
    },
  },
  methods: {
    clear() {
      const utcShiftedDateNow = getUtcShiftedDateNow();
      this.placeholderDate = utcShiftedDateNow;
      this.hourPickerInput = utcShiftedDateNow.getHours();
      this.minutePickerInput = utcShiftedDateNow.getMinutes();
      this.timelineText = '';
    },
    focusDate() {
      this.$refs.datepicker.$el.focus();
    },
    handleSave(addAnotherEvent) {
      const eventDetails = {
        note: this.timelineText,
        occurredAt: this.occurredAt,
      };
      this.$emit('save-event', eventDetails, addAnotherEvent);
    },
  },
};
</script>

<template>
  <div
    class="gl-relative gl-display-flex gl-align-items-center"
    :class="{ 'timeline-entry-vertical-line': hasTimelineEvents }"
  >
    <div
      v-if="hasTimelineEvents"
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-align-self-start gl-bg-white gl-text-gray-200 gl-border-gray-100 gl-border-1 gl-border-solid gl-rounded-full gl-mt-2 gl-mr-3 gl-w-8 gl-h-8 gl-z-index-1"
    >
      <gl-icon name="comment" class="note-icon" />
    </div>
    <form class="gl-flex-grow-1 gl-border-gray-50" :class="{ 'gl-border-t': hasTimelineEvents }">
      <div
        class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row datetime-picker"
      >
        <gl-form-group :label="__('Date')" class="gl-mt-5 gl-mr-5">
          <gl-datepicker id="incident-date" #default="{ formattedDate }" v-model="placeholderDate">
            <gl-form-input
              id="incident-date"
              ref="datepicker"
              v-model="datepickerTextInput"
              data-testid="input-datepicker"
              class="gl-datepicker-input gl-pr-7!"
              :value="formattedDate"
              :placeholder="__('YYYY-MM-DD')"
              @keydown.enter="onKeydown"
            />
          </gl-datepicker>
        </gl-form-group>
        <div class="gl-display-flex gl-mt-5">
          <gl-form-group :label="__('Time')">
            <div class="gl-display-flex">
              <label label-for="timeline-input-hours" class="sr-only"></label>
              <gl-form-input
                id="timeline-input-hours"
                v-model="hourPickerInput"
                data-testid="input-hours"
                size="xs"
                type="number"
                min="00"
                max="23"
              />
              <label label-for="timeline-input-minutes" class="sr-only"></label>
              <gl-form-input
                id="timeline-input-minutes"
                v-model="minutePickerInput"
                class="gl-ml-3"
                data-testid="input-minutes"
                size="xs"
                type="number"
                min="00"
                max="59"
              />
            </div>
          </gl-form-group>
          <p class="gl-ml-3 gl-align-self-end gl-line-height-32">{{ __('UTC') }}</p>
        </div>
      </div>
      <div class="common-note-form">
        <gl-form-group class="gl-mb-3" :label="$options.i18n.areaLabel">
          <markdown-field
            :can-attach-file="false"
            :add-spacing-classes="false"
            :show-comment-tool-bar="false"
            :textarea-value="timelineText"
            :restricted-tool-bar-items="$options.restrictedToolBarItems"
            markdown-docs-path=""
            :enable-preview="false"
            class="bordered-box gl-mt-0"
          >
            <template #textarea>
              <textarea
                v-model="timelineText"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                data-testid="input-note"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="$options.i18n.description"
                :placeholder="$options.i18n.areaPlaceholder"
              >
              </textarea>
            </template>
          </markdown-field>
        </gl-form-group>
      </div>
      <gl-form-group class="gl-mb-0">
        <gl-button
          variant="confirm"
          category="primary"
          class="gl-mr-3"
          :loading="isEventProcessed"
          @click="handleSave(false)"
        >
          {{ $options.i18n.save }}
        </gl-button>
        <gl-button
          variant="confirm"
          category="secondary"
          class="gl-mr-3 gl-ml-n2"
          :loading="isEventProcessed"
          @click="handleSave(true)"
        >
          {{ $options.i18n.saveAndAdd }}
        </gl-button>
        <gl-button class="gl-ml-n2" :disabled="isEventProcessed" @click="$emit('cancel')">
          {{ $options.i18n.cancel }}
        </gl-button>
        <div class="gl-border-b gl-pt-5"></div>
      </gl-form-group>
    </form>
  </div>
</template>
