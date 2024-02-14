# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsDataStructureHashTest < Minitest::Test
  # PersonParams1 = contract.with(
  #   type: Hash,
  #   schema: {
  #     name: { type: String },
  #     age: { type: Integer },
  #     address: {
  #       type: Hash,
  #       schema: {
  #         street: { type: String },
  #         number: { type: Integer },
  #         city: { type: String },
  #         state: { type: String },
  #         country: { type: String }
  #       }
  #     },
  #     phone_numbers: { type: Array, schema: { type: String } }
  #   }
  # )

  # PeopleParams3 = contract.with(
  #   type: Array,
  #   schema: {
  #     type: Hash,
  #     schema: {
  #       name: { type: String },
  #       age: { type: Integer },
  #       address: {
  #         type: Hash,
  #         schema: {
  #           street: { type: String },
  #           number: { type: Integer },
  #           city: { type: String },
  #           state: { type: String },
  #           country: { type: String }
  #         }
  #       },
  #       phone_numbers: { type: Array, schema: { type: String } }
  #     }
  #   }
  # )
end
