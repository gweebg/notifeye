defmodule Notifeye.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :success, :boolean, null: false, default: true
      add :type, :string, null: false
      add :data, :map, default: %{}
      add :providers, {:array, :string}, default: []
      add :results, :map, default: %{}
      add :metadata, :map, default: %{}

      add :recipient_id, references(:users, type: :integer, on_delete: :nilify_all)
      add :oban_job_id, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:oban_job_id])
    create index(:notifications, [:recipient_id])
  end
end
