import { GlLink, GlModal, GlSprintf, GlFormGroup, GlCollapse, GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import InviteMembersModal from '~/invite_members/components/invite_members_modal.vue';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import ModalConfetti from '~/invite_members/components/confetti.vue';
import MembersTokenSelect from '~/invite_members/components/members_token_select.vue';
import {
  INVITE_MEMBERS_FOR_TASK,
  MEMBERS_MODAL_CELEBRATE_INTRO,
  MEMBERS_MODAL_CELEBRATE_TITLE,
  MEMBERS_PLACEHOLDER,
  MEMBERS_PLACEHOLDER_DISABLED,
  MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT,
  LEARN_GITLAB,
  EXPANDED_ERRORS,
} from '~/invite_members/constants';
import eventHub from '~/invite_members/event_hub';
import ContentTransition from '~/vue_shared/components/content_transition.vue';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';
import { getParameterValues } from '~/lib/utils/url_utility';
import { GROUPS_INVITATIONS_PATH, invitationsApiResponse } from '../mock_data/api_responses';
import {
  propsData,
  inviteSource,
  newProjectPath,
  freeUsersLimit,
  membersCount,
  user1,
  user2,
  user3,
  user4,
  user5,
  user6,
  GlEmoji,
} from '../mock_data/member_modal';

jest.mock('~/experimentation/experiment_tracking');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterValues: jest.fn(() => []),
}));

describe('InviteMembersModal', () => {
  let wrapper;
  let mock;

  const createComponent = (props = {}, stubs = {}) => {
    wrapper = shallowMountExtended(InviteMembersModal, {
      provide: {
        newProjectPath,
      },
      propsData: {
        usersLimitDataset: {},
        ...propsData,
        ...props,
      },
      stubs: {
        InviteModalBase,
        ContentTransition,
        GlSprintf,
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlEmoji,
        ...stubs,
      },
    });
  };

  const createInviteMembersToProjectWrapper = (usersLimitDataset = {}, stubs = {}) => {
    createComponent({ usersLimitDataset, isProject: true }, stubs);
  };

  const createInviteMembersToGroupWrapper = (usersLimitDataset = {}, stubs = {}) => {
    createComponent({ usersLimitDataset, isProject: false }, stubs);
  };

  beforeEach(() => {
    gon.api_version = 'v4';
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findBase = () => wrapper.findComponent(InviteModalBase);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findMemberErrorAlert = () => wrapper.findByTestId('alert-member-error');
  const findMoreInviteErrorsButton = () => wrapper.findByTestId('accordion-button');
  const findAccordion = () => wrapper.findComponent(GlCollapse);
  const findErrorsIcon = () => wrapper.findComponent(GlIcon);
  const findMemberErrorMessage = (element) =>
    `${Object.keys(invitationsApiResponse.EXPANDED_RESTRICTED.message)[element]}: ${
      Object.values(invitationsApiResponse.EXPANDED_RESTRICTED.message)[element]
    }`;
  const emitEventFromModal = (eventName) => () =>
    findModal().vm.$emit(eventName, { preventDefault: jest.fn() });
  const clickInviteButton = emitEventFromModal('primary');
  const clickCancelButton = emitEventFromModal('cancel');
  const findMembersFormGroup = () => wrapper.findByTestId('members-form-group');
  const membersFormGroupInvalidFeedback = () =>
    findMembersFormGroup().attributes('invalid-feedback');
  const membersFormGroupText = () => findMembersFormGroup().text();
  const findMembersSelect = () => wrapper.findComponent(MembersTokenSelect);
  const findTasksToBeDone = () => wrapper.findByTestId('invite-members-modal-tasks-to-be-done');
  const findTasks = () => wrapper.findByTestId('invite-members-modal-tasks');
  const findProjectSelect = () => wrapper.findByTestId('invite-members-modal-project-select');
  const findNoProjectsAlert = () => wrapper.findByTestId('invite-members-modal-no-projects-alert');
  const findCelebrationEmoji = () => wrapper.findComponent(GlEmoji);
  const triggerOpenModal = async ({ mode = 'default', source }) => {
    eventHub.$emit('openModal', { mode, source });
    await nextTick();
  };
  const triggerMembersTokenSelect = async (val) => {
    findMembersSelect().vm.$emit('input', val);
    await nextTick();
  };
  const triggerTasks = async (val) => {
    findTasks().vm.$emit('input', val);
    await nextTick();
  };
  const triggerAccessLevel = async (val) => {
    findBase().vm.$emit('access-level', val);
    await nextTick();
  };
  const removeMembersToken = async (val) => {
    findMembersSelect().vm.$emit('token-remove', val);
    await nextTick();
  };

  describe('rendering the tasks to be done', () => {
    const setupComponent = async (props = {}, urlParameter = ['invite_members_for_task']) => {
      getParameterValues.mockImplementation(() => urlParameter);
      createComponent(props);

      await triggerAccessLevel(30);
    };

    const setupComponentWithTasks = async (...args) => {
      await setupComponent(...args);
      await triggerTasks(['ci', 'code']);
    };

    afterAll(() => {
      getParameterValues.mockImplementation(() => []);
    });

    it('renders the tasks to be done', async () => {
      await setupComponent();

      expect(findTasksToBeDone().exists()).toBe(true);
    });

    describe('when the selected access level is lower than 30', () => {
      it('does not render the tasks to be done', async () => {
        await setupComponent();
        await triggerAccessLevel(20);

        expect(findTasksToBeDone().exists()).toBe(false);
      });
    });

    describe('when the url does not contain the parameter `open_modal=invite_members_for_task`', () => {
      it('does not render the tasks to be done', async () => {
        await setupComponent({}, []);

        expect(findTasksToBeDone().exists()).toBe(false);
      });

      describe('when opened from the Learn GitLab page', () => {
        it('does render the tasks to be done', async () => {
          await setupComponent({}, []);
          await triggerOpenModal({ source: LEARN_GITLAB });

          expect(findTasksToBeDone().exists()).toBe(true);
        });
      });
    });

    describe('rendering the tasks', () => {
      it('renders the tasks', async () => {
        await setupComponent();

        expect(findTasks().exists()).toBe(true);
      });

      it('does not render an alert', async () => {
        await setupComponent();

        expect(findNoProjectsAlert().exists()).toBe(false);
      });

      describe('when there are no projects passed in the data', () => {
        it('does not render the tasks', async () => {
          await setupComponent({ projects: [] });

          expect(findTasks().exists()).toBe(false);
        });

        it('renders an alert with a link to the new projects path', async () => {
          await setupComponent({ projects: [] });

          expect(findNoProjectsAlert().exists()).toBe(true);
          expect(findNoProjectsAlert().findComponent(GlLink).attributes('href')).toBe(
            newProjectPath,
          );
        });
      });
    });

    describe('rendering the project dropdown', () => {
      it('renders the project select', async () => {
        await setupComponentWithTasks();

        expect(findProjectSelect().exists()).toBe(true);
      });

      describe('when the modal is shown for a project', () => {
        it('does not render the project select', async () => {
          await setupComponentWithTasks({ isProject: true });

          expect(findProjectSelect().exists()).toBe(false);
        });
      });

      describe('when no tasks are selected', () => {
        it('does not render the project select', async () => {
          await setupComponent();

          expect(findProjectSelect().exists()).toBe(false);
        });
      });
    });

    describe('tracking events', () => {
      it('tracks the view for invite_members_for_task', async () => {
        await setupComponentWithTasks();

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name);
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          INVITE_MEMBERS_FOR_TASK.view,
        );
      });

      it('tracks the submit for invite_members_for_task', async () => {
        await setupComponentWithTasks();
        clickInviteButton();

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name, {
          label: 'selected_tasks_to_be_done',
          property: 'ci,code',
        });
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(
          INVITE_MEMBERS_FOR_TASK.submit,
        );
      });
    });
  });

  describe('displaying the correct introText and form group description', () => {
    describe('when inviting to a project', () => {
      describe('when inviting members', () => {
        beforeEach(() => {
          createInviteMembersToProjectWrapper();
        });

        it('renders the modal without confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(false);
        });

        it('includes the correct invitee', () => {
          expect(findIntroText()).toBe("You're inviting members to the test name project.");
          expect(findCelebrationEmoji().exists()).toBe(false);
        });

        describe('members form group description', () => {
          it('renders correct description', () => {
            createInviteMembersToProjectWrapper({ freeUsersLimit, membersCount }, { GlFormGroup });
            expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER);
          });

          describe('when reached user limit', () => {
            it('renders correct description', () => {
              createInviteMembersToProjectWrapper(
                { freeUsersLimit, membersCount: 5 },
                { GlFormGroup },
              );

              expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER_DISABLED);
            });
          });
        });
      });

      describe('when inviting members with celebration', () => {
        beforeEach(async () => {
          createInviteMembersToProjectWrapper();
          await triggerOpenModal({ mode: 'celebrate' });
        });

        it('renders the modal with confetti', () => {
          expect(wrapper.findComponent(ModalConfetti).exists()).toBe(true);
        });

        it('renders the modal with the correct title', () => {
          expect(findModal().props('title')).toBe(MEMBERS_MODAL_CELEBRATE_TITLE);
        });

        it('includes the correct celebration text and emoji', () => {
          expect(findIntroText()).toBe(
            `${MEMBERS_TO_PROJECT_CELEBRATE_INTRO_TEXT}  ${MEMBERS_MODAL_CELEBRATE_INTRO}`,
          );
          expect(findCelebrationEmoji().exists()).toBe(true);
        });

        describe('members form group description', () => {
          it('renders correct description', async () => {
            createInviteMembersToProjectWrapper({ freeUsersLimit, membersCount }, { GlFormGroup });
            await triggerOpenModal({ mode: 'celebrate' });

            expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER);
          });

          describe('when reached user limit', () => {
            it('renders correct description', async () => {
              createInviteMembersToProjectWrapper(
                { freeUsersLimit, membersCount: 5 },
                { GlFormGroup },
              );

              await triggerOpenModal({ mode: 'celebrate' });

              expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER_DISABLED);
            });
          });
        });
      });
    });

    describe('when inviting to a group', () => {
      it('includes the correct invitee, type, and formatted name', () => {
        createInviteMembersToGroupWrapper();

        expect(findIntroText()).toBe("You're inviting members to the test name group.");
      });

      describe('members form group description', () => {
        it('renders correct description', () => {
          createInviteMembersToGroupWrapper({ freeUsersLimit, membersCount }, { GlFormGroup });
          expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER);
        });

        describe('when reached user limit', () => {
          it('renders correct description', () => {
            createInviteMembersToGroupWrapper({ freeUsersLimit, membersCount: 5 }, { GlFormGroup });
            expect(membersFormGroupText()).toContain(MEMBERS_PLACEHOLDER_DISABLED);
          });
        });
      });
    });
  });

  describe('submitting the invite form', () => {
    const mockInvitationsApi = (code, data) => {
      mock.onPost(GROUPS_INVITATIONS_PATH).reply(code, data);
    };

    const expectedEmailRestrictedError =
      "The member's email address is not allowed for this project. Go to the Admin area > Sign-up restrictions, and check Allowed domains for sign-ups.";
    const expectedSyntaxError = 'email contains an invalid email address';

    describe('when inviting an existing user to group by user ID', () => {
      const postData = {
        user_id: '1,2',
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
        tasks_to_be_done: [],
        tasks_project_id: '',
      };

      describe('when member is added successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user2]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });

        describe('when opened from a Learn GitLab page', () => {
          it('emits the `showSuccessfulInvitationsAlert` event', async () => {
            await triggerOpenModal({ source: LEARN_GITLAB });

            jest.spyOn(eventHub, '$emit').mockImplementation();

            clickInviteButton();

            await waitForPromises();

            expect(eventHub.$emit).toHaveBeenCalledWith('showSuccessfulInvitationsAlert');
          });
        });
      });

      describe('when member is not added successfully', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user1]);
        });

        describe('clearing the invalid state and message', () => {
          beforeEach(async () => {
            mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_TAKEN);

            clickInviteButton();

            await waitForPromises();
          });

          it('clears the error when the list of members to invite is cleared', async () => {
            expect(findMemberErrorAlert().exists()).toBe(true);
            expect(findMemberErrorAlert().text()).toContain(
              Object.values(invitationsApiResponse.EMAIL_TAKEN.message)[0],
            );
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);

            findMembersSelect().vm.$emit('clear');

            await nextTick();

            expect(findMemberErrorAlert().exists()).toBe(false);
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('clears the error when the cancel button is clicked', async () => {
            clickCancelButton();

            await nextTick();

            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });

          it('clears the error when the modal is hidden', async () => {
            findModal().vm.$emit('hidden');

            await nextTick();

            expect(findMemberErrorAlert().exists()).toBe(false);
            expect(membersFormGroupInvalidFeedback()).toBe('');
            expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          });
        });

        it('displays the generic error for http server error', async () => {
          mockInvitationsApi(
            httpStatus.INTERNAL_SERVER_ERROR,
            'Request failed with status code 500',
          );

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe('Something went wrong');
          expect(findMembersSelect().props('exceptionState')).toBe(false);
        });

        it('displays the restricted user api message for response with bad request', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(expectedEmailRestrictedError);
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });

        it('displays all errors when there are multiple existing users that are restricted by email', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.MULTIPLE_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[0],
          );
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[1],
          );
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[2],
          );
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });
      });
    });

    describe('when inviting a new user by email address', () => {
      const postData = {
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        email: 'email@example.com',
        invite_source: inviteSource,
        tasks_to_be_done: [],
        tasks_project_id: '',
        format: 'json',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user3]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });
      });

      describe('when invites are not sent successfully', () => {
        beforeEach(async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3]);
        });

        it('displays the api error for invalid email syntax', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('exceptionState')).toBe(false);
          expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        });

        it('clears the error when the modal is hidden', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('exceptionState')).toBe(false);
          expect(findModal().props('actionPrimary').attributes.loading).toBe(false);

          findModal().vm.$emit('hidden');

          await nextTick();

          expect(findMemberErrorAlert().exists()).toBe(false);
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });

        it('displays the restricted email error when restricted email is invited', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EMAIL_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(expectedEmailRestrictedError);
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
          expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
        });

        it('displays all errors when there are multiple emails that return a restricted error message', async () => {
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.MULTIPLE_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[0],
          );
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[1],
          );
          expect(findMemberErrorAlert().text()).toContain(
            Object.values(invitationsApiResponse.MULTIPLE_RESTRICTED.message)[2],
          );
          expect(membersFormGroupInvalidFeedback()).toBe('');
          expect(findMembersSelect().props('exceptionState')).not.toBe(false);
        });

        it('displays the invalid syntax error for bad request', async () => {
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.ERROR_EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('exceptionState')).toBe(false);
        });
      });

      describe('when multiple emails are invited at the same time', () => {
        it('displays the invalid syntax error if one of the emails is invalid', async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3, user4]);
          mockInvitationsApi(httpStatus.BAD_REQUEST, invitationsApiResponse.ERROR_EMAIL_INVALID);

          clickInviteButton();

          await waitForPromises();

          expect(membersFormGroupInvalidFeedback()).toBe(expectedSyntaxError);
          expect(findMembersSelect().props('exceptionState')).toBe(false);
        });

        it('displays errors for multiple and allows clearing', async () => {
          createInviteMembersToGroupWrapper();

          await triggerMembersTokenSelect([user3, user4, user5, user6]);
          mockInvitationsApi(httpStatus.CREATED, invitationsApiResponse.EXPANDED_RESTRICTED);

          clickInviteButton();

          await waitForPromises();

          expect(findMemberErrorAlert().exists()).toBe(true);
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 4 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(0));
          expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(1));
          expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(2));
          expect(findMemberErrorAlert().text()).toContain(findMemberErrorMessage(3));
          expect(findAccordion().exists()).toBe(true);
          expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
          expect(findErrorsIcon().attributes('class')).not.toContain('gl-rotate-180');
          expect(findAccordion().attributes('visible')).toBeUndefined();

          await findMoreInviteErrorsButton().vm.$emit('click');

          expect(findMoreInviteErrorsButton().text()).toContain(EXPANDED_ERRORS);
          expect(findErrorsIcon().attributes('class')).toContain('gl-rotate-180');
          expect(findAccordion().attributes('visible')).toBeDefined();

          await findMoreInviteErrorsButton().vm.$emit('click');

          expect(findMoreInviteErrorsButton().text()).toContain('Show more (2)');
          expect(findAccordion().attributes('visible')).toBeUndefined();

          await removeMembersToken(user3);

          expect(findMoreInviteErrorsButton().text()).toContain('Show more (1)');
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 3 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(findMemberErrorMessage(0));

          await removeMembersToken(user6);

          expect(findMoreInviteErrorsButton().exists()).toBe(false);
          expect(findMemberErrorAlert().props('title')).toContain(
            "The following 2 members couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(findMemberErrorMessage(2));

          await removeMembersToken(user4);

          expect(findMemberErrorAlert().props('title')).toContain(
            "The following member couldn't be invited",
          );
          expect(findMemberErrorAlert().text()).not.toContain(findMemberErrorMessage(1));

          await removeMembersToken(user5);

          expect(findMemberErrorAlert().exists()).toBe(false);
        });
      });
    });

    describe('when inviting members and non-members in same click', () => {
      const postData = {
        access_level: propsData.defaultAccessLevel,
        expires_at: undefined,
        invite_source: inviteSource,
        format: 'json',
        tasks_to_be_done: [],
        tasks_project_id: '',
        user_id: '1',
        email: 'email@example.com',
      };

      describe('when invites are sent successfully', () => {
        beforeEach(async () => {
          createComponent();
          await triggerMembersTokenSelect([user1, user3]);

          wrapper.vm.$toast = { show: jest.fn() };
          jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({ data: postData });
        });

        describe('when triggered from regular mounting', () => {
          beforeEach(() => {
            clickInviteButton();
          });

          it('calls Api inviteGroupMembers with the correct params', () => {
            expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, postData);
          });

          it('displays the successful toastMessage', () => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Members were successfully added');
          });
        });

        it('calls Apis with the invite source passed through to openModal', async () => {
          await triggerOpenModal({ source: '_invite_source_' });

          clickInviteButton();

          expect(Api.inviteGroupMembers).toHaveBeenCalledWith(propsData.id, {
            ...postData,
            invite_source: '_invite_source_',
          });
        });
      });
    });

    describe('tracking', () => {
      beforeEach(async () => {
        createComponent();
        await triggerMembersTokenSelect([user3]);

        wrapper.vm.$toast = { show: jest.fn() };
        jest.spyOn(Api, 'inviteGroupMembers').mockResolvedValue({});
      });

      it('tracks the view for learn_gitlab source', () => {
        eventHub.$emit('openModal', { source: LEARN_GITLAB });

        expect(ExperimentTracking).toHaveBeenCalledWith(INVITE_MEMBERS_FOR_TASK.name);
        expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith(LEARN_GITLAB);
      });
    });
  });
});
