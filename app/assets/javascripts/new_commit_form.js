/* eslint-disable no-var, no-return-assign */
export default class NewCommitForm {
  constructor(form) {
    this.form = form;
    this.renderDestination = this.renderDestination.bind(this);
    this.branchName = form.find('.js-branch-name');
    this.originalBranch = form.find('.js-original-branch');
    this.createMergeRequest = form.find('.js-create-merge-request');
    this.createMergeRequestContainer = form.find('.js-create-merge-request-container');
    this.filenameInput = form.find('.js-file-path-name-input');
    this.commitMessage = form.find('js-commit-message');
    this.commitMessageEdited = false;
    this.branchName.keyup(this.renderDestination);
    this.renderDestination();
    this.listenForFilenameInput();
    this.listenForCommitMessageInput();
  }
  renderDestination() {
    var different;
    different = this.branchName.val() !== this.originalBranch.val();
    if (different) {
      this.createMergeRequestContainer.show();
      if (!this.wasDifferent) {
        this.createMergeRequest.prop('checked', true);
      }
    } else {
      this.createMergeRequestContainer.hide();
      this.createMergeRequest.prop('checked', false);
    }
    return (this.wasDifferent = different);
  }

  listenForFilenameInput() {
    this.filenameInput.on('keyup blur', () => {
      if (!this.commitMessageEdited) {
        this.updateCommitMessage();
      }
    });
  }

  listenForCommitMessageInput() {
    this.commitMessage.on('keyup blur', () => {
      this.commitMessageEdited = true;
    });
  }

  updateCommitMessage() {
    const msgPrefix = this.commitMessage.text().split(' ')[0];

    if (msgPrefix === 'Add' || msgPrefix === 'Update') {
      this.commitMessage.text(`${msgPrefix} ${this.filenameInput}`);
    }
  }
}
