import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlDatepicker } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimelineEventsForm from '~/issues/show/components/incidents/timeline_events_form.vue';
import { createAlert } from '~/flash';
import { useFakeDate } from 'helpers/fake_date';

Vue.use(VueApollo);

jest.mock('~/flash');

const fakeDate = '2020-07-08T00:00:00.000Z';

describe('Timeline events form', () => {
  // July 8 2020
  useFakeDate(fakeDate);
  let wrapper;

  const mountComponent = ({ mountMethod = shallowMountExtended }) => {
    wrapper = mountMethod(TimelineEventsForm, {
      propsData: {
        hasTimelineEvents: true,
        isEventProcessed: false,
      },
    });
  };

  afterEach(() => {
    createAlert.mockReset();
    wrapper.destroy();
  });

  const findSubmitButton = () => wrapper.findByText('Save');
  const findSubmitAndAddButton = () => wrapper.findByText('Save and add another event');
  const findCancelButton = () => wrapper.findByText('Cancel');
  const findDatePicker = () => wrapper.findComponent(GlDatepicker);
  const findDatePickerInput = () => wrapper.findByTestId('input-datepicker');
  const findHourInput = () => wrapper.findByTestId('input-hours');
  const findMinuteInput = () => wrapper.findByTestId('input-minutes');
  const setDatetime = () => {
    findDatePicker().vm.$emit('input', new Date('2021-08-12'));
    findHourInput().vm.$emit('input', 5);
    findMinuteInput().vm.$emit('input', 45);
  };

  const submitForm = async () => {
    findSubmitButton().trigger('click');
    await waitForPromises();
  };
  const submitFormAndAddAnother = async () => {
    findSubmitAndAddButton().trigger('click');
    await waitForPromises();
  };
  const cancelForm = async () => {
    findCancelButton().trigger('click');
    await waitForPromises();
  };

  describe('form button behaviour', () => {
    beforeEach(() => {
      mountComponent({ mountMethod: mountExtended });
    });

    it('should save event on submit', async () => {
      await submitForm();

      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate }, false]],
      });
    });

    it('should save event on "submit and add another"', async () => {
      await submitFormAndAddAnother();
      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate }, true]],
      });
    });

    it('should emit cancel on cancel', async () => {
      await cancelForm();
      expect(wrapper.emitted()).toEqual({ cancel: [[]] });
    });

    it('should clear the form', async () => {
      setDatetime();
      await nextTick();

      expect(findDatePickerInput().element.value).toBe('2021-08-12');
      expect(findHourInput().element.value).toBe('5');
      expect(findMinuteInput().element.value).toBe('45');

      wrapper.vm.clear();
      await nextTick();

      expect(findDatePickerInput().element.value).toBe('2020-07-08');
      expect(findHourInput().element.value).toBe('0');
      expect(findMinuteInput().element.value).toBe('0');
    });
  });
});
