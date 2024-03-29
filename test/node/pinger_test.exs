defmodule AnomaTest.Node.Pinger do
  use ExUnit.Case, async: true

  alias Anoma.Node.{Mempool, Router}
  alias Anoma.Storage
  alias Anoma.Node.Storage.Ordering
  import TestHelper.Nock

  setup_all do
    storage = %Anoma.Storage{
      qualified: AnomaTest.Pinger.Qualified,
      order: AnomaTest.Pinger.Order
    }

    name = :pinger
    snapshot_path = [:my_special_nock_snaphsot | 0]

    {:ok, nodes} =
      Anoma.Node.start_link(
        name: name,
        snapshot_path: snapshot_path,
        storage: storage,
        block_storage: :pinger_blocks,
        ping_time: 1
      )

    node = Anoma.Node.state(nodes)

    [node: node]
  end

  test "Execution is done automatically", %{node: node} do
    key = 555
    storage = Ordering.get_storage(node.ordering)
    increment = increment_counter_val(key)
    zero = zero_counter(key)

    ex_id = node.executor_topic.id
    mem_t = node.mempool_topic

    :ok =
      Router.call(
        node.router,
        {:subscribe_topic, ex_id, :local}
      )

    Mempool.hard_reset(node.mempool)

    :ok = Router.call(node.router, {:subscribe_topic, mem_t, :local})

    pid_zero = Mempool.tx(node.mempool, {:kv, zero}).pid

    assert_receive {:"$gen_cast", {_, {:submitted, _}}}

    pid_one = Mempool.tx(node.mempool, {:kv, increment}).pid
    pid_two = Mempool.tx(node.mempool, {:kv, increment}).pid

    assert_receive {:"$gen_cast", {_, {:process_done, ^pid_zero}}}
    assert_receive {:"$gen_cast", {_, {:process_done, ^pid_one}}}
    assert_receive {:"$gen_cast", {_, {:process_done, ^pid_two}}}

    assert {:ok, 2} = Storage.get(storage, key)

    :ok =
      Router.call(
        node.router,
        {:unsubscribe_topic, ex_id, :local}
      )

    :ok =
      Router.call(
        node.router,
        {:unsubscribe_topic, mem_t, :local}
      )

    Anoma.Node.Pinger.set_timer(node.pinger, :no_timer)
  end
end