<script>
import { GlAlert } from '@gitlab/ui';
import { sortBy } from 'lodash';
import Draggable from 'vuedraggable';
import { mapState, mapGetters, mapActions } from 'vuex';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import { defaultSortableOptions } from '~/sortable/constants';
import { DraggableItemTypes } from '../constants';
import BoardColumn from './board_column.vue';

export default {
  draggableItemTypes: DraggableItemTypes,
  components: {
    BoardAddNewColumn,
    BoardColumn,
    BoardContentSidebar: () => import('~/boards/components/board_content_sidebar.vue'),
    EpicBoardContentSidebar: () =>
      import('ee_component/boards/components/epic_board_content_sidebar.vue'),
    EpicsSwimlanes: () => import('ee_component/boards/components/epics_swimlanes.vue'),
    GlAlert,
  },
  inject: ['canAdminList'],
  props: {
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['boardLists', 'error', 'addColumnForm']),
    ...mapGetters(['isSwimlanesOn', 'isEpicBoard', 'isIssueBoard']),
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    boardListsToUse() {
      return sortBy([...Object.values(this.boardLists)], 'position');
    },
    canDragColumns() {
      return this.canAdminList;
    },
    boardColumnWrapper() {
      return this.canDragColumns ? Draggable : 'div';
    },
    draggableOptions() {
      const options = {
        ...defaultSortableOptions,
        disabled: this.disabled,
        draggable: '.is-draggable',
        fallbackOnBody: false,
        group: 'boards-list',
        tag: 'div',
        value: this.boardListsToUse,
      };

      return this.canDragColumns ? options : {};
    },
  },
  methods: {
    ...mapActions(['moveList', 'unsetError']),
    afterFormEnters() {
      const el = this.canDragColumns ? this.$refs.list.$el : this.$refs.list;
      el.scrollTo({ left: el.scrollWidth, behavior: 'smooth' });
    },
  },
};
</script>

<template>
  <div v-cloak data-qa-selector="boards_list">
    <gl-alert v-if="error" variant="danger" :dismissible="true" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <component
      :is="boardColumnWrapper"
      v-if="!isSwimlanesOn"
      ref="list"
      v-bind="draggableOptions"
      class="boards-list gl-w-full gl-py-5 gl-pr-3 gl-white-space-nowrap"
      @end="moveList"
    >
      <board-column
        v-for="(list, index) in boardListsToUse"
        :key="index"
        ref="board"
        :list="list"
        :data-draggable-item-type="$options.draggableItemTypes.list"
        :disabled="disabled"
        :class="{ 'gl-xs-display-none!': addColumnFormVisible }"
      />

      <transition name="slide" @after-enter="afterFormEnters">
        <board-add-new-column v-if="addColumnFormVisible" class="gl-xs-w-full!" />
      </transition>
    </component>

    <epics-swimlanes
      v-else-if="boardListsToUse.length"
      ref="swimlanes"
      :lists="boardListsToUse"
      :can-admin-list="canAdminList"
      :disabled="disabled"
    />

    <board-content-sidebar v-if="isIssueBoard" data-testid="issue-boards-sidebar" />

    <epic-board-content-sidebar v-else-if="isEpicBoard" data-testid="epic-boards-sidebar" />
  </div>
</template>
