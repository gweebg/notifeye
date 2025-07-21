defmodule Notifeye.Repo.Migrations.UpdateAlertEventSamples do
  use Ecto.Migration

  def change do
    alter table(:alerts) do
      modify :alert_event_samples, :text
    end
  end
end
