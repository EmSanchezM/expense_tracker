defmodule ExpenseTrackerApi.SeedData.ExpenseFactory do
  @moduledoc """
  Factory module for generating test expenses for seeding the database.

  This module provides functions to create realistic expense data with proper
  category and temporal distribution for testing purposes.
  """

  @doc """
  Creates 10 expenses for a given user_id with realistic distribution.

  The expenses are distributed as follows:
  - Categories: 3 groceries, 2 utilities, 2 leisure, 1 health, 1 electronics, 1 clothing
  - Temporal: 2 last week, 4 last month, 7 last 3 months, 10 last 6 months

  ## Parameters

    * `user_id` - The ID of the user to create expenses for

  ## Examples

      iex> ExpenseTrackerApi.SeedData.ExpenseFactory.create_expenses_for_user(1)
      [%{amount: Decimal.new("45.50"), description: "Compra semanal...", ...}, ...]
  """
  def create_expenses_for_user(user_id) do
    # Define category distribution (total: 10 expenses)
    categories = [
      :groceries, :groceries, :groceries,  # 3 groceries
      :utilities, :utilities,              # 2 utilities
      :leisure, :leisure,                  # 2 leisure
      :health,                             # 1 health
      :electronics,                        # 1 electronics
      :clothing                            # 1 clothing
    ]

    # Define temporal distribution (last 6 months)
    date_ranges = generate_date_ranges()

    # Distribute expenses across time periods
    # 2 last week, 2 more last month (4 total), 3 more last 3 months (7 total), 3 more last 6 months (10 total)
    temporal_distribution = [
      :last_week, :last_week,                                    # 2 in last week
      :last_month, :last_month,                                  # 2 more in last month (4 total)
      :last_3_months, :last_3_months, :last_3_months,          # 3 more in last 3 months (7 total)
      :last_6_months, :last_6_months, :last_6_months           # 3 more in last 6 months (10 total)
    ]

    # Shuffle to avoid predictable patterns
    shuffled_categories = Enum.shuffle(categories)
    shuffled_temporal = Enum.shuffle(temporal_distribution)

    # Generate expenses
    Enum.zip(shuffled_categories, shuffled_temporal)
    |> Enum.map(fn {category, time_period} ->
      date = random_date_in_period(date_ranges[time_period])

      %{
        amount: random_amount_for_category(category),
        description: random_description_for_category(category),
        category: category,
        date: date,
        user_id: user_id
      }
    end)
  end

  @doc """
  Generates a random amount for the given category within realistic ranges.

  ## Amount Ranges by Category
  - Groceries: $20 - $150
  - Utilities: $50 - $300
  - Leisure: $15 - $200
  - Electronics: $100 - $800
  - Clothing: $25 - $250
  - Health: $30 - $400
  - Others: $10 - $100

  ## Examples

      iex> ExpenseTrackerApi.SeedData.ExpenseFactory.random_amount_for_category(:groceries)
      Decimal.new("67.45")
  """
  def random_amount_for_category(category) do
    {min, max} = case category do
      :groceries -> {20, 150}
      :utilities -> {50, 300}
      :leisure -> {15, 200}
      :electronics -> {100, 800}
      :clothing -> {25, 250}
      :health -> {30, 400}
      :others -> {10, 100}
    end

    # Generate random amount with cents
    dollars = Enum.random(min..max)
    cents = Enum.random(0..99)

    Decimal.new("#{dollars}.#{String.pad_leading(Integer.to_string(cents), 2, "0")}")
  end

  @doc """
  Generates a realistic Spanish description for the given category.

  ## Examples

      iex> ExpenseTrackerApi.SeedData.ExpenseFactory.random_description_for_category(:groceries)
      "Compra semanal en supermercado"
  """
  def random_description_for_category(category) do
    descriptions = case category do
      :groceries -> [
        "Compra semanal en supermercado",
        "Frutas y verduras del mercado",
        "Despensa mensual",
        "Productos de limpieza y comida",
        "Compra en tienda de barrio"
      ]
      :utilities -> [
        "Factura de electricidad",
        "Pago de agua y alcantarillado",
        "Servicio de gas natural",
        "Internet y telefonía",
        "Factura de servicios públicos"
      ]
      :leisure -> [
        "Cena en restaurante",
        "Entradas de cine",
        "Concierto de música",
        "Salida con amigos",
        "Actividad de fin de semana"
      ]
      :health -> [
        "Consulta médica",
        "Medicamentos recetados",
        "Exámenes de laboratorio",
        "Tratamiento dental",
        "Vitaminas y suplementos"
      ]
      :electronics -> [
        "Nuevo smartphone",
        "Auriculares inalámbricos",
        "Cargador para laptop",
        "Accesorios tecnológicos",
        "Reparación de dispositivo"
      ]
      :clothing -> [
        "Ropa de temporada",
        "Zapatos nuevos",
        "Chaqueta de invierno",
        "Ropa deportiva",
        "Accesorios de vestir"
      ]
      :others -> [
        "Gasto varios",
        "Compra miscelánea",
        "Artículos del hogar",
        "Herramientas básicas",
        "Productos de cuidado personal"
      ]
    end

    Enum.random(descriptions)
  end

  # Private helper functions

  defp generate_date_ranges do
    today = Date.utc_today()

    %{
      last_week: {Date.add(today, -7), today},
      last_month: {Date.add(today, -30), Date.add(today, -8)},
      last_3_months: {Date.add(today, -90), Date.add(today, -31)},
      last_6_months: {Date.add(today, -180), Date.add(today, -91)}
    }
  end

  defp random_date_in_period({start_date, end_date}) do
    days_diff = Date.diff(end_date, start_date)
    random_days = Enum.random(0..days_diff)
    Date.add(start_date, random_days)
  end
end
