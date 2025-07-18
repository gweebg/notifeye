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

  def list_alert_descriptions(), do: AlertDescription |> Repo.all()

  def list_alert_descriptions(preloads) when is_list(preloads) do
    AlertDescription
    |> Repo.all()
    |> Repo.preload(preloads)
  end

  def list_alert_descriptions(flop, preloads \\ []) do
    AlertDescription
    |> Flop.validate_and_run(flop, for: AlertDescription)
    |> case do
      {:ok, {posts, meta}} ->
        {:ok, {posts |> Repo.preload(preloads), meta}}

      error ->
        error
    end
  end

  @doc """
  Returns the list of alert_descriptions in a paginated way.

  ## Examples
  """
  def list_alert_descriptions_paginated(flop, page_size \\ 10, preloads \\ []) do
    flop =
      flop
      |> Map.put("page_size", page_size)

    AlertDescription
    |> Flop.validate_and_run(flop, for: AlertDescription)
    |> case do
      {:ok, {posts, meta}} ->
        {:ok, {posts |> Repo.preload(preloads), meta}}

      error ->
        error
    end
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
    |> broadcast(:new_description)
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
    alert_description
    |> Repo.delete()
    |> broadcast(:deleted_description)
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
  Tries to match the regular expression pattern defined in the alert description
  agains the alert event samples of an alert.

  The regular expression pattern is expected to be a valid Regex with at least
  one named capture group named `user`, which in combination with `named_captures/2`
  will extract the possible username (or email, depending on the pattern) from
  the alert samples.

  ## Parameters
    - `description`: The `%AlertDescription{}` for the alert.
    - `alert_event_samples`: The string samples from the alert event to match against the pattern.

  ## Returns
    - `[match1, match2, ..., matchN]` if the pattern matches any part of the alert event samples.
    - `nil` if the pattern does not match any part of the alert event samples.
    - `{:error, reason}` if the pattern is not a valid Regex.
  """
  def maybe_match_samples(pattern, alert_event_samples) do
    with {:ok, regex} <- Regex.compile(pattern),
         captures <- all_named_captures(regex, alert_event_samples, "user") do
      captures
    else
      {:error, _reason} = error -> error
    end
  end

  defp all_named_captures(regex, string, group_name) do
    regex
    |> Regex.scan(string, capture: [group_name])
    |> List.flatten()
    |> Enum.filter(&(&1 != ""))
    |> case do
      [] -> nil
      captures -> captures
    end
  end

  @doc """
  Subscribes to alert description events.
  """
  def subscribe(topic) when topic in ["new_description", "deleted_description"] do
    Phoenix.PubSub.subscribe(Notifeye.PubSub, topic)
  end

  @doc """
  Broadcasts an event to the pubsub.

  ## Examples

      iex> broadcast(:new_description, alert_description)
      {:ok, %AlertDescription{}}

      iex> broadcast(:deleted_enrollment, nil)
      {:ok, nil}
  """
  def broadcast({:error, _reason} = error, _event), do: error

  def broadcast({:ok, %AlertDescription{} = alert_description}, event)
      when event in [:new_description] do
    Phoenix.PubSub.broadcast!(Notifeye.PubSub, "new_description", {event, alert_description})
    {:ok, alert_description}
  end

  def broadcast({:ok, %AlertDescription{} = alert_description}, event)
      when event in [:deleted_description] do
    Phoenix.PubSub.broadcast!(Notifeye.PubSub, "deleted_description", {event, alert_description})
    {:ok, alert_description}
  end
end
