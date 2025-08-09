defmodule Notifeye.Repo.Migrations.CreateDescriptionRules do
  use Ecto.Migration

  def change do
    create table(:alert_description_rules) do
      add :name, :string, null: false
      add :active, :boolean, null: false
      add :count, :integer, null: false
      add :action, :string, null: false
      add :action_value, :text
      add :rule_blocks, :map, null: false

      add :alert_description_id, references(:alert_descriptions, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:alert_description_rules, [:alert_description_id])
    create index(:alert_description_rules, [:action])
  end
end
