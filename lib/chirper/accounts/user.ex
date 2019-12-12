defmodule Chirper.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Chirper.Accounts.{User, Encryption,Relationship}
  alias Chirper.Blog.Post

  schema "users" do
    field :encrypted_password, :string
    field :username, :string

    has_many :posts, Post
    has_many(:active_relationships, Relationship, foreign_key: :follower_id)
    has_many(:passive_relationships, Relationship, foreign_key: :followed_id)
    has_many(:following, through: [:active_relationships, :followed])
    has_many(:followers, through: [:passive_relationships, :follower])

    # VIRTUAL FIELDS
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username])
    |> validate_length(:password, min: 5)
    |> validate_confirmation(:password)
    |> unique_constraint(:username)
    |> downcase_username
    |> encrypt_password
  end

  defp encrypt_password(changeset) do
    password = get_change(changeset, :password)
    if password do
      encrypted_password = Encryption.hash_password(password)
      put_change(changeset, :encrypted_password, encrypted_password)
    else
      changeset
    end
  end

  defp downcase_username(changeset) do
    update_change(changeset, :username, &String.downcase/1)
  end
end
