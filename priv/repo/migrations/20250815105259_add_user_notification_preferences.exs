defmodule Notifeye.Repo.Migrations.AddUserNotificationPreferences do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :notification_preferences, :map, null: %{}
    end
  end
end
