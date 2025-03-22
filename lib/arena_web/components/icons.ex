defmodule ArenaWeb.Components.Icons do
  use Phoenix.Component

  @moduledoc """
  A component that renders a microphone icon.
  """

  @doc """
  Renders the microphone icon.

  ## Options

    * `class` - Additional CSS classes to apply to the SVG element.

  ## Examples

      <ArenaWeb.Components.Icons.microphone class="text-red-500" />

  """
  attr :class, :string, default: "h-6 w-6 text-gray-500"

  def microphone(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class={@class}
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 18.75a6 6 0 006-6v-1.5m-6 7.5a6 6 0 01-6-6v-1.5m6 7.5v3.75m-3.75 0h7.5M12 15.75a3 3 0 01-3-3V4.5a3 3 0 116 0v8.25a3 3 0 01-3 3z"
      />
    </svg>
    """
  end
end
