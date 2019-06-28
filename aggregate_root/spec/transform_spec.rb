# frozen_string_literal: true

require 'spec_helper'

module AggregateRoot
  RSpec.describe Transform do
    specify { expect(Transform.to_snake_case("OrderSubmitted")).to eq("order_submitted") }
    specify { expect(Transform.to_snake_case("SHA1ChecksumComputed")).to eq("sha1_checksum_computed") }
    specify { expect(Transform.to_snake_case("OKROfPSAInQ1Reached")).to eq("okr_of_psa_in_q1_reached") }
    specify { expect(Transform.to_snake_case("EncryptedWithRot13")).to eq("encrypted_with_rot13") }
  end
end
