<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { VALID_DATA_TRANSFER_TYPE, VALID_IMAGE_FILE_MIMETYPE } from './constants';
import { isValidImage } from './utils';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    displayAsCard: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableDragBehavior: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropToStartMessage: {
      type: String,
      required: false,
      default: __('Drop your files to start your upload.'),
    },
    isFileValid: {
      type: Function,
      required: false,
      default: isValidImage,
    },
    validFileMimetypes: {
      type: Array,
      required: false,
      default: () => [VALID_IMAGE_FILE_MIMETYPE.mimetype],
    },
    singleFileSelection: {
      type: Boolean,
      required: false,
      default: false,
    },
    inputFieldName: {
      type: String,
      required: false,
      default: 'upload_file',
    },
    shouldUpdateInputOnFileDrop: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dragCounter: 0,
      isDragDataValid: true,
    };
  },
  computed: {
    dragging() {
      return this.dragCounter !== 0;
    },
    iconStyles() {
      return {
        size: this.displayAsCard ? 24 : 16,
        class: this.displayAsCard ? 'gl-mb-2' : 'gl-mr-3 gl-text-gray-500',
      };
    },
    validMimeTypeString() {
      return this.validFileMimetypes.join();
    },
  },
  methods: {
    isValidUpload(files) {
      return files.every(this.isFileValid);
    },
    isValidDragDataType({ dataTransfer }) {
      return Boolean(
        dataTransfer && dataTransfer.types.some((t) => t === VALID_DATA_TRANSFER_TYPE),
      );
    },
    ondrop({ dataTransfer = {} }) {
      this.dragCounter = 0;
      // User already had feedback when dropzone was active, so bail here
      if (!this.isDragDataValid) {
        return;
      }

      const { files } = dataTransfer;
      if (!this.isValidUpload(Array.from(files))) {
        this.$emit('error');
        return;
      }

      // NOTE: This is a temporary solution to integrate dropzone into a Rails
      // form. On file drop if `shouldUpdateInputOnFileDrop` is true, the file
      // input value is updated. So that when the form is submitted — the file
      // value would be send together with the form data. This solution should
      // be removed when License file upload page is fully migrated:
      // https://gitlab.com/gitlab-org/gitlab/-/issues/352501
      // NOTE: as per https://caniuse.com/mdn-api_htmlinputelement_files, IE11
      // is not able to set input.files property, thought the user would still
      // be able to use the file picker dialogue option, by clicking the
      // "openFileUpload" button
      if (this.shouldUpdateInputOnFileDrop) {
        // Since FileList cannot be easily manipulated, to match requirement of
        // singleFileSelection, we're throwing an error if multiple files were
        // dropped on the dropzone
        // NOTE: we can drop this logic together with
        // `shouldUpdateInputOnFileDrop` flag
        if (this.singleFileSelection && files.length > 1) {
          this.$emit('error');
          return;
        }

        this.$refs.fileUpload.files = files;
      }

      this.$emit('change', this.singleFileSelection ? files[0] : files);
    },
    ondragenter(e) {
      this.dragCounter += 1;
      this.isDragDataValid = this.isValidDragDataType(e);
    },
    ondragleave() {
      this.dragCounter -= 1;
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onFileInputChange(e) {
      this.$emit('change', this.singleFileSelection ? e.target.files[0] : e.target.files);
    },
  },
};
</script>

<template>
  <div
    class="gl-w-full gl-relative"
    @dragstart.prevent.stop
    @dragend.prevent.stop
    @dragover.prevent.stop
    @dragenter.prevent.stop="ondragenter"
    @dragleave.prevent.stop="ondragleave"
    @drop.prevent.stop="ondrop"
  >
    <slot>
      <button
        class="card upload-dropzone-card upload-dropzone-border gl-w-full gl-h-full gl-align-items-center gl-justify-content-center gl-p-4"
        type="button"
        @click="openFileUpload"
      >
        <div
          :class="{ 'gl-flex-direction-column': displayAsCard }"
          class="gl-display-flex gl-align-items-center gl-justify-content-center gl-text-center"
          data-testid="dropzone-area"
        >
          <gl-icon name="upload" :size="iconStyles.size" :class="iconStyles.class" />
          <p class="gl-mb-0" data-testid="upload-text">
            <slot name="upload-text" :open-file-upload="openFileUpload">
              <gl-sprintf
                :message="
                  singleFileSelection
                    ? __('Drop or %{linkStart}upload%{linkEnd} file to attach')
                    : __('Drop or %{linkStart}upload%{linkEnd} files to attach')
                "
              >
                <template #link="{ content }">
                  <gl-link @click.stop="openFileUpload">
                    {{ content }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </slot>
          </p>
        </div>
      </button>

      <input
        ref="fileUpload"
        type="file"
        :name="inputFieldName"
        :accept="validFileMimetypes"
        class="hide"
        :multiple="!singleFileSelection"
        @change="onFileInputChange"
      />
    </slot>
    <transition name="upload-dropzone-fade">
      <div
        v-show="dragging && !enableDragBehavior"
        class="card upload-dropzone-border upload-dropzone-overlay gl-w-full gl-h-full gl-absolute gl-display-flex gl-align-items-center gl-justify-content-center gl-p-4"
      >
        <div v-show="!isDragDataValid" class="mw-50 gl-text-center">
          <slot name="invalid-drag-data-slot">
            <h3 :class="{ 'gl-font-base gl-display-inline': !displayAsCard }">
              {{ __('Oh no!') }}
            </h3>
            <span>{{
              __(
                'You are trying to upload something other than an image. Please upload a .png, .jpg, .jpeg, .gif, .bmp, .tiff or .ico.',
              )
            }}</span>
          </slot>
        </div>
        <div v-show="isDragDataValid" class="mw-50 gl-text-center">
          <slot name="valid-drag-data-slot">
            <h3 :class="{ 'gl-font-base gl-display-inline': !displayAsCard }">
              {{ __('Incoming!') }}
            </h3>
            <span>{{ dropToStartMessage }}</span>
          </slot>
        </div>
      </div>
    </transition>
  </div>
</template>
