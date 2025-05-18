defmodule Notifeye.Repo.Migrations.CreateAlertDescriptions do
  use Ecto.Migration

  def change do
    create table(:alert_descriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :enabled, :boolean, default: false, null: false
      add :pattern, :string
      add :verified, :boolean, default: false, null: false
      add :edited_by, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:alert_descriptions, [:edited_by])
  end
end
