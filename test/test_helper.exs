{:ok, _apps} = Application.ensure_all_started(:incident)
ExUnit.start()
