defmodule Notifeye.Repo.Migrations.ChangeDescriptionEnabledField do
  use Ecto.Migration

  def change do
    alter table(:alert_descriptions) do
      remove :enabled
      add :state, :string, null: false, default: "disabled"
    end
  end
end
