defmodule Notifeye.Repo.Migrations.CreateNotificationGroups do
  use Ecto.Migration

  def change do
    # notification groups table with binary_id primary key
    create table(:notification_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    # join table for notification groups and users (many-to-many relationship)
    create table(:notification_group_users, primary_key: false) do
      add :notification_group_id,
          references(:notification_groups, type: :binary_id, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :integer, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # update alert_descriptions to include notification_group_id
    alter table(:alert_descriptions) do
      add :notification_group_id,
          references(:notification_groups, type: :binary_id, on_delete: :nilify_all)
    end

    create unique_index(:notification_groups, [:name])
    create index(:notification_group_users, [:notification_group_id])
    create index(:notification_group_users, [:user_id])
    create unique_index(:notification_group_users, [:notification_group_id, :user_id])
    create index(:alert_descriptions, [:notification_group_id])
  end
end
