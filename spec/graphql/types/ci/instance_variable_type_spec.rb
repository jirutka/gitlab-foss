# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CiInstanceVariable'] do
  specify { expect(described_class.interfaces).to contain_exactly(Types::Ci::VariableInterface) }

  specify { expect(described_class).to have_graphql_fields(:masked, :protected).at_least }
end
