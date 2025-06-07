defmodule Notifeye.Repo.Migrations.CreateAlertAssignments do
  use Ecto.Migration

  def change do
    create table(:alert_assignments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :match, :string
      add :status, :string, null: false

      add :user_id, references(:users, on_delete: :nothing)

      add :alert_description_id,
          references(:alert_descriptions, on_delete: :nilify_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:alert_assignments, [:user_id])
    create index(:alert_assignments, [:alert_description_id])
  end
end
