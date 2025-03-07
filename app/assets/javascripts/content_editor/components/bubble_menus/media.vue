<script>
import {
  GlLink,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLoadingIcon,
  GlButton,
  GlButtonGroup,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { BubbleMenu } from '@tiptap/vue-2';
import { __ } from '~/locale';
import Audio from '../../extensions/audio';
import Image from '../../extensions/image';
import Video from '../../extensions/video';
import EditorStateObserver from '../editor_state_observer.vue';
import { acceptedMimes } from '../../services/upload_helpers';

const MEDIA_TYPES = [Audio.name, Image.name, Video.name];

export default {
  i18n: {
    copySourceLabels: {
      [Audio.name]: __('Copy audio URL'),
      [Image.name]: __('Copy image URL'),
      [Video.name]: __('Copy video URL'),
    },
    editLabels: {
      [Audio.name]: __('Edit audio description'),
      [Image.name]: __('Edit image description'),
      [Video.name]: __('Edit video description'),
    },
    replaceLabels: {
      [Audio.name]: __('Replace audio'),
      [Image.name]: __('Replace image'),
      [Video.name]: __('Replace video'),
    },
    deleteLabels: {
      [Audio.name]: __('Delete audio'),
      [Image.name]: __('Delete image'),
      [Video.name]: __('Delete video'),
    },
  },
  components: {
    BubbleMenu,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    GlButton,
    GlButtonGroup,
    EditorStateObserver,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      mediaType: undefined,
      mediaSrc: undefined,
      mediaCanonicalSrc: undefined,
      mediaAlt: undefined,
      mediaTitle: undefined,

      isEditing: false,
      isUpdating: false,
      isUploading: false,
    };
  },
  computed: {
    copySourceLabel() {
      return this.$options.i18n.copySourceLabels[this.mediaType];
    },
    editLabel() {
      return this.$options.i18n.editLabels[this.mediaType];
    },
    replaceLabel() {
      return this.$options.i18n.replaceLabels[this.mediaType];
    },
    deleteLabel() {
      return this.$options.i18n.deleteLabels[this.mediaType];
    },
    showProgressIndicator() {
      return this.isUploading || this.isUpdating;
    },
  },
  methods: {
    shouldShow() {
      const shouldShow = MEDIA_TYPES.some((type) => this.tiptapEditor.isActive(type));

      if (!shouldShow) this.isEditing = false;

      return shouldShow;
    },

    startEditingMedia() {
      this.isEditing = true;
    },

    endEditingMedia() {
      this.isEditing = false;

      this.updateMediaInfoToState();
    },

    cancelEditingMedia() {
      this.endEditingMedia();
      this.updateMediaInfoToState();
    },

    async saveEditedMedia() {
      this.isUpdating = true;

      this.mediaSrc = await this.contentEditor.resolveUrl(this.mediaCanonicalSrc);

      const position = this.tiptapEditor.state.selection.from;

      this.tiptapEditor
        .chain()
        .focus()
        .updateAttributes(this.mediaType, {
          src: this.mediaSrc,
          alt: this.mediaAlt,
          canonicalSrc: this.mediaCanonicalSrc,
          title: this.mediaTitle,
        })
        .run();

      this.tiptapEditor.commands.setNodeSelection(position);

      this.endEditingMedia();

      this.isUpdating = false;
    },

    async updateMediaInfoToState() {
      this.mediaType = MEDIA_TYPES.find((type) => this.tiptapEditor.isActive(type));

      if (!this.mediaType) return;

      this.isUpdating = true;

      const { src, title, alt, canonicalSrc, uploading } = this.tiptapEditor.getAttributes(
        this.mediaType,
      );

      this.mediaTitle = title;
      this.mediaAlt = alt;
      this.mediaCanonicalSrc = canonicalSrc || src;
      this.isUploading = uploading;
      this.mediaSrc = await this.contentEditor.resolveUrl(this.mediaCanonicalSrc);

      this.isUpdating = false;
    },

    replaceMedia() {
      this.$refs.fileSelector.click();
    },

    onFileSelect(e) {
      this.tiptapEditor
        .chain()
        .focus()
        .deleteSelection()
        .uploadAttachment({
          file: e.target.files[0],
        })
        .run();

      this.$refs.fileSelector.value = '';
    },

    copyMediaSrc() {
      navigator.clipboard.writeText(this.mediaCanonicalSrc);
    },

    deleteMedia() {
      this.tiptapEditor.chain().focus().deleteSelection().run();
    },
  },

  acceptedMimes,
};
</script>
<template>
  <bubble-menu
    data-testid="media-bubble-menu"
    class="gl-shadow gl-rounded-base gl-bg-white"
    :editor="tiptapEditor"
    plugin-key="bubbleMenuMedia"
    :should-show="() => shouldShow()"
  >
    <editor-state-observer @transaction="updateMediaInfoToState">
      <gl-button-group v-if="!isEditing" class="gl-display-flex gl-align-items-center">
        <gl-loading-icon v-if="showProgressIndicator" class="gl-pl-4 gl-pr-3" />
        <input
          ref="fileSelector"
          type="file"
          name="content_editor_image"
          :accept="$options.acceptedMimes[mediaType]"
          class="gl-display-none"
          data-qa-selector="file_upload_field"
          @change="onFileSelect"
        />

        <gl-link
          v-if="!showProgressIndicator"
          v-gl-tooltip
          :href="mediaSrc"
          :aria-label="mediaCanonicalSrc"
          :title="mediaCanonicalSrc"
          target="_blank"
          class="gl-px-3 gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis"
        >
          {{ mediaCanonicalSrc }}
        </gl-link>
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="copy-media-src"
          :aria-label="copySourceLabel"
          :title="copySourceLabel"
          icon="copy-to-clipboard"
          @click="copyMediaSrc"
        />
        <gl-button
          v-if="!showProgressIndicator"
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="edit-media"
          :aria-label="editLabel"
          :title="editLabel"
          icon="pencil"
          @click="startEditingMedia"
        />
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="replace-media"
          :aria-label="replaceLabel"
          :title="replaceLabel"
          icon="upload"
          @click="replaceMedia"
        />
        <gl-button
          v-gl-tooltip
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="delete-media"
          :aria-label="deleteLabel"
          :title="deleteLabel"
          icon="remove"
          @click="deleteMedia"
        />
      </gl-button-group>
      <gl-form v-else class="bubble-menu-form gl-p-4 gl-w-100" @submit.prevent="saveEditedMedia">
        <gl-form-group :label="__('URL')" label-for="media-src">
          <gl-form-input id="media-src" v-model="mediaCanonicalSrc" data-testid="media-src" />
        </gl-form-group>
        <gl-form-group :label="__('Description (alt text)')" label-for="media-alt">
          <gl-form-input id="media-alt" v-model="mediaAlt" data-testid="media-alt" />
        </gl-form-group>
        <gl-form-group :label="__('Title')" label-for="media-title">
          <gl-form-input id="media-title" v-model="mediaTitle" data-testid="media-title" />
        </gl-form-group>
        <div class="gl-display-flex gl-justify-content-end">
          <gl-button
            class="gl-mr-3"
            data-testid="cancel-editing-media"
            @click="cancelEditingMedia"
            >{{ __('Cancel') }}</gl-button
          >
          <gl-button variant="confirm" type="submit">{{ __('Apply') }}</gl-button>
        </div>
      </gl-form>
    </editor-state-observer>
  </bubble-menu>
</template>
