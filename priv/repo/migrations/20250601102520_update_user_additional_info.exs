defmodule Notifeye.Repo.Migrations.UpdateUserAdditionalInfo do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :standing, :integer, default: 10, null: false
      add :role, :string, null: false
      add :lead_id, references(:users, on_delete: :nilify_all)
    end

    create index(:users, [:lead_id])
  end
end
