defmodule Notifeye.Repo.Migrations.AddNameToDescription do
  use Ecto.Migration

  def change do
    alter table(:alert_descriptions) do
      add :name, :string
    end
  end
end
