defmodule Rumbl.Presence do
  use Phoenix.Presence, otp_app: :rumbl,
                        pubsub_server: Rumbl.PubSub
end