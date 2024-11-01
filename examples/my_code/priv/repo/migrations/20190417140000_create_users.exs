defmodule MyRepo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    create table("users") do
      add :first_name,    :string, size: 40
      add :last_name,    :string, size: 40

      timestamps()
    end
  end

  def down do
    drop table("weather")
  end
end
