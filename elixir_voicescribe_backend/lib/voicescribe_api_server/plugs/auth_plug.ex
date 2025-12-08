defmodule VoiceScribeAPIServer.AuthenticationPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- verify_token(token) do
      assign(conn, :current_user, claims["sub"])
    else
      _ ->
        conn
          |> put_status(:unauthorized)
          |> json(%{error: "Unauthorized"})
          |> halt()
    end
  end

  defp verify_token(_token) do
    # MOCK: In production, verify JWT signature from Cognito
    {:ok, %{"sub" => "mvp-test-user"}}
  end
end
