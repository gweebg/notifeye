defmodule Notifeye.Repo.Migrations.AddAlertIdToAlertAssignments do
  use Ecto.Migration

  def change do
    alter table(:alert_assignments) do
      add :alert_id, references(:alerts, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:alert_assignments, [:alert_id])
  end
end
