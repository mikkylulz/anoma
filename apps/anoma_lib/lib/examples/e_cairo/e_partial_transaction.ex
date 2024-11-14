defmodule Examples.ECairo.EPartialTransaction do
  alias Anoma.CairoResource.PartialTransaction
  alias Examples.ECairo.EProofRecord
  alias Examples.ECairo.EResourceLogic

  use TestHelper.TestMacro

  @spec a_partial_transaction() :: PartialTransaction.t()
  def a_partial_transaction do
    proof = EProofRecord.a_compliance_proof()
    input_resource_logic = EResourceLogic.a_input_resource_logic()
    output_resource_logic = EResourceLogic.a_output_resource_logic()

    ptx = %PartialTransaction{
      logic_proofs: [input_resource_logic, output_resource_logic],
      compliance_proofs: [proof]
    }

    assert PartialTransaction.verify(ptx)

    ptx
  end
end