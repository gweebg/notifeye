defmodule Notifeye.Repo.Migrations.UpdateAlertDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:alerts) do
      modify :alert_description, :text
    end
  end
end
