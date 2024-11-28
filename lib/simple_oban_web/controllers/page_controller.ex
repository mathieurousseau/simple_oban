defmodule SimpleObanWeb.PageController do
  use SimpleObanWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    entries =
      :ets.all()
      |> Enum.filter(fn r -> :ets.info(r) |> Keyword.get(:name) == SimpleOban.Repo end)
      |> hd()
      |> :ets.tab2list()

    render(conn, :home, layout: false, entries: entries)
  end
end
