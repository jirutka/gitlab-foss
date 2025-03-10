<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_ORGANIZATION, TYPE_GROUP } from '~/graphql_shared/constants';
import OrganizationForm from '../../components/form.vue';
import getGroupOrganizationsQuery from './graphql/get_group_organizations.query.graphql';
import createOrganizationMutation from './graphql/create_organization.mutation.graphql';
import updateOrganizationMutation from './graphql/update_organization.mutation.graphql';

export default {
  components: {
    OrganizationForm,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    organizationGraphQLId() {
      if (!this.isEditMode) return null;

      return convertToGraphQLId(TYPE_CRM_ORGANIZATION, this.$route.params.id);
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPE_GROUP, this.groupId);
    },
    mutation() {
      if (this.isEditMode) return updateOrganizationMutation;

      return createOrganizationMutation;
    },
    getQuery() {
      return {
        query: getGroupOrganizationsQuery,
        variables: { groupFullPath: this.groupFullPath },
      };
    },
    title() {
      if (this.isEditMode) return s__('Crm|Edit organization');

      return s__('Crm|New organization');
    },
    successMessage() {
      if (this.isEditMode) return s__('Crm|Organization has been updated.');

      return s__('Crm|Organization has been added.');
    },
    additionalCreateParams() {
      return { groupId: this.groupGraphQLId };
    },
    fields() {
      const fields = [
        { name: 'name', label: __('Name'), required: true },
        {
          name: 'defaultRate',
          label: s__('Crm|Default rate'),
          input: { type: 'number', step: '0.01' },
        },
        { name: 'description', label: __('Description') },
      ];

      if (this.isEditMode)
        fields.push({ name: 'active', label: s__('Crm|Active'), required: true, bool: true });

      return fields;
    },
  },
};
</script>

<template>
  <organization-form
    :drawer-open="true"
    :get-query="getQuery"
    get-query-node-path="group.organizations"
    :mutation="mutation"
    :additional-create-params="additionalCreateParams"
    :existing-id="organizationGraphQLId"
    :fields="fields"
    :title="title"
    :success-message="successMessage"
  />
</template>
