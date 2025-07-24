defmodule Notifeye.Repo.Migrations.AddMetadataToAssignments do
  use Ecto.Migration

  def change do
    alter table(:alert_assignments) do
      add :metadata, :map
    end
  end
end
