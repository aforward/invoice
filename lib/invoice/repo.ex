defmodule Invoice.Repo do
  use Ecto.Repo, otp_app: :invoice
  use FnExpr

  def init(_, config) do
    config
    |> DeferredConfig.transform_cfg
    |> invoke({:ok, &1})
  end
end
