defmodule Notifeye.AlertDescriptions do
  @moduledoc """
  The AlertDescriptions context.
  """

  import Ecto.Query, warn: false
  alias Notifeye.Repo

  alias Notifeye.AlertDescriptions.AlertDescription

  @doc """
  Returns the list of alert_descriptions.

  ## Examples

      iex> list_alert_descriptions()
      [%AlertDescription{}, ...]

  """
  def list_alert_descriptions do
    Repo.all(AlertDescription)
  end

  @doc """
  Gets a single alert_description.

  Raises `Ecto.NoResultsError` if the Alert description does not exist.

  ## Examples

      iex> get_alert_description!(123)
      %AlertDescription{}

      iex> get_alert_description!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert_description!(id), do: Repo.get!(AlertDescription, id)

  @doc """
  Gets a single alert_description.

  Returns `nil` if the Alert description does not exist.

  ## Examples

      iex> get_alert_description(123)
      %AlertDescription{}

      iex> get_alert_description(456)
      nil

  """
  def get_alert_description(id), do: Repo.get(AlertDescription, id)

  @doc """
  Creates a alert_description.

  ## Examples

      iex> create_alert_description(%{field: value})
      {:ok, %AlertDescription{}}

      iex> create_alert_description(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert_description(attrs) do
    %AlertDescription{}
    |> AlertDescription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a alert_description.

  ## Examples

      iex> update_alert_description(alert_description, %{field: new_value})
      {:ok, %AlertDescription{}}

      iex> update_alert_description(alert_description, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert_description(%AlertDescription{} = alert_description, attrs) do
    alert_description
    |> AlertDescription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a alert_description.

  ## Examples

      iex> delete_alert_description(alert_description)
      {:ok, %AlertDescription{}}

      iex> delete_alert_description(alert_description)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert_description(%AlertDescription{} = alert_description) do
    Repo.delete(alert_description)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert_description changes.

  ## Examples

      iex> change_alert_description(alert_description)
      %Ecto.Changeset{data: %AlertDescription{}}

  """
  def change_alert_description(%AlertDescription{} = alert_description, attrs \\ %{}) do
    AlertDescription.changeset(alert_description, attrs)
  end

  @doc """
  Matches the Regex pattern in `pattern` agains the alert event samples of an alert.

  ## Returns
    - ["match1", "match2", ...] if the pattern matches any part of the alert event samples.
    - [] if the pattern does not match any part of the alert event samples.
    - {:error, reason} if the pattern is not a valid Regex.
  """
  def match_against(%AlertDescription{} = description, alert_event_samples) do
  end
end
