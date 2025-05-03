defmodule Notifeye.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :logz_id, :string
      add :alert_title, :string
      add :alert_description, :string
      add :alert_severity, :string
      add :alert_event_samples, :string
      add :alert_tags, {:array, :string}
      add :start, :utc_datetime
      add :end, :utc_datetime
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:alerts, [:user_id])
  end
end
