<script>
import { __ } from '~/locale';

export default {
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: __('Add a title...'),
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    handleBlur({ target }) {
      this.$emit('title-changed', target.innerText);
    },
    handleInput({ target }) {
      this.$emit('title-input', target.innerText);
    },
    handleSubmit() {
      this.$refs.titleEl.blur();
    },
  },
};
</script>

<template>
  <h2
    class="gl-font-weight-normal gl-sm-font-weight-bold gl-mb-5 gl-mt-0 gl-w-full"
    :class="{ 'gl-cursor-text': disabled }"
    aria-labelledby="item-title"
  >
    <div
      id="item-title"
      ref="titleEl"
      role="textbox"
      :aria-label="__('Title')"
      :data-placeholder="placeholder"
      :contenteditable="!disabled"
      class="gl-px-4 gl-py-3 gl-ml-n4 gl-border gl-border-white gl-rounded-base"
      :class="{ 'gl-hover-border-gray-200 gl-pseudo-placeholder': !disabled }"
      @blur="handleBlur"
      @keyup="handleInput"
      @keydown.enter.exact="handleSubmit"
      @keydown.ctrl.u.prevent
      @keydown.meta.u.prevent
      @keydown.ctrl.b.prevent
      @keydown.meta.b.prevent
    >
      {{ title }}
    </div>
  </h2>
</template>
