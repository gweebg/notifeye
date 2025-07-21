defmodule Notifeye.Repo.Migrations.AddUserAliases do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :aliases, {:array, :string}
    end
  end
end
