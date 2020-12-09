defmodule Mix.Tasks.Incident.Postgres.Init do
  @moduledoc """
  This task will generate some basic setup when using `PostgresAdapter`.

  When using this adapter you will need to have a table to store the events and aggregate locks.
  This task will generate an `Ecto` migration to create the `events` and `aggregate_locks` table
  with the needed columns and indexes. The task will respect your `Ecto` configuration for your
  `EventStoreRepo`.

  # Usage
  ```
  mix incident.postgres.init -r AppName.EventStoreRepo
  ```
  """

  use Mix.Task

  import Ecto.Migrator
  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.{Ecto, Generator}

  @shortdoc "Generates the initial setup for Incident with Postgres Adapter"
  @impl true
  def run(["-r", repo]) do
    no_umbrella!("incident.postgres.init")

    event_store_repo =
      [repo]
      |> Module.concat()
      |> ensure_repo([])

    # Generates the events table migration
    name = "create_events_table"
    path = Path.relative_to(migrations_path(event_store_repo), Mix.Project.app_path())
    file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")
    create_directory(path)

    content =
      [module_name: Module.concat([event_store_repo, Migrations, camelize(name)])]
      |> events_migration_template()
      |> Code.format_string!()

    create_file(file, content)

    # Generates the aggregate_locks table migration
    name = "create_aggregate_locks_table"
    path = Path.relative_to(migrations_path(event_store_repo), Mix.Project.app_path())
    file = Path.join(path, "#{timestamp()}_#{underscore(name)}.exs")

    content =
      [module_name: Module.concat([event_store_repo, Migrations, camelize(name)])]
      |> aggregate_locks_migration_template()
      |> Code.format_string!()

    create_file(file, content)
  end

  @impl true
  def run(_) do
    Mix.shell().error("""
    Error: you need to pass the Ecto Event Store Repo using the -r flag.
    Please notice that this task should run after you have your Ecto repos
    configuration all set in your application config files.

    # Usage
    ```
    mix incident.postgres.init -r AppName.EventStoreRepo
    ```
    """)
  end

  @spec timestamp :: String.t()
  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  @spec pad(integer) :: String.t()
  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:events_migration, """
    defmodule <%= inspect @module_name %> do
      use Ecto.Migration
      def change do
        create table(:events, primary_key: false) do
          add(:id, :bigserial, primary_key: true)
          add(:event_id, :binary_id, null: false)
          add(:aggregate_id, :string, null: false)
          add(:event_type, :string, null: false)
          add(:version, :integer, null: false)
          add(:event_date, :utc_datetime_usec, null: false)
          add(:event_data, :map, null: false)

          timestamps(type: :utc_datetime_usec, updated_at: false)
        end

        create(index(:events, [:aggregate_id]))
        create(index(:events, [:event_type]))
        create(index(:events, [:event_date]))
        create(index(:events, [:version]))
        create constraint(:events, :version_must_be_positive, check: "version > 0")
      end
    end
  """)

  embed_template(:aggregate_locks_migration, """
    defmodule <%= inspect @module_name %> do
      use Ecto.Migration
      def change do
        create table(:aggregate_locks, primary_key: false) do
          add(:id, :bigserial, primary_key: true)
          add(:aggregate_id, :string, null: false)
          add(:owner_id, :integer, null: false)
          add(:valid_until, :utc_datetime_usec, null: false)
        end

        create(index(:aggregate_locks, [:aggregate_id]))
        create(index(:aggregate_locks, [:aggregate_id, :owner_id]))
        create(index(:aggregate_locks, [:valid_until]))
      end
    end
  """)
end
