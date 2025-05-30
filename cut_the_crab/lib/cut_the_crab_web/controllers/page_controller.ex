defmodule CutTheCrabWeb.PageController do
  use CutTheCrabWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def redirect_to_upload(conn, _params) do
    conn
    |> redirect(to: "/upload")
  end
end
