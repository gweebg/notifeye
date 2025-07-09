defmodule Notifeye.Accounts.User do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Notifeye.Accounts

  @roles ~w(user admin lead)a

  schema "users" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    field :standing, :integer, default: 10
    field :role, Ecto.Enum, values: @roles, default: :user
    field :aliases, {:array, :string}, default: []

    belongs_to :lead, __MODULE__

    has_many :alert_assignments, Notifeye.AlertAssignments.AlertAssignment, on_replace: :delete

    has_many :alert_descriptions, Notifeye.AlertDescriptions.AlertDescription,
      foreign_key: :edited_by

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_email` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :username])
    |> validate_email(opts)
    |> maybe_put_username()
  end

  defp maybe_put_username(changeset) do
    case {get_field(changeset, :username), get_field(changeset, :email)} do
      {nil, email} when is_binary(email) ->
        username = infer_name_from_email(email)
        put_change(changeset, :username, username)

      _ ->
        changeset
    end
  end

  def infer_name_from_email(email) do
    email
    |> String.split("@")
    |> hd()
    |> String.split(".")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Notifeye.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  A user changeset for creating an admin user.
  """
  def admin_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :role, :username])
    |> validate_email(opts)
    |> validate_required([:email, :role, :username])
    |> validate_inclusion(:role, [:admin])
    |> unique_constraint(:email)
  end

  @doc """
  A user changeset for changing the password.

  It is important to validate the length of the password, as long passwords may
  be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Notifeye.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  A user changeset for creating or updating a user.
  """
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
  end

  @doc """
  A user changeset for changing the lead.
  This changeset is used to assign a lead to a user.
  """
  def lead_changeset(user, attrs) do
    user
    |> cast(attrs, [:lead_id])
    |> validate_required([:lead_id])
    |> validate_lead_id()
    |> foreign_key_constraint(:lead_id)
  end

  defp validate_lead_id(changeset) do
    lead_id = get_field(changeset, :lead_id)

    if lead_id && !lead_user?(lead_id) do
      add_error(changeset, :lead_id, "must be a valid lead user")
    else
      changeset
    end
  end

  defp lead_user?(user_id) do
    user = Accounts.get_user!(user_id)
    user.role == :lead
  end
end
