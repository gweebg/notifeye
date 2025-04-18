defmodule Notifeye.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :alert_id, :string
      add :title, :string
      add :description, :text
      add :definition_id, :string
      add :severity, :string
      add :tags, :string
      add :samples, :text

      timestamps(type: :utc_datetime)
    end
  end
end
