<script>
export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    widgets() {
      return [].filter((w) => w);
    },
  },
};
</script>

<template>
  <section role="region" :aria-label="__('Merge request reports')" data-testid="mr-widget-app">
    <component
      :is="widget"
      v-for="(widget, index) in widgets"
      :key="widget.name || index"
      :mr="mr"
      :class="{ 'mr-widget-border-top': index === 0 }"
    />
  </section>
</template>
