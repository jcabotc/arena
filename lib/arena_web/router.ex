defmodule ArenaWeb.Router do
  use ArenaWeb, :router

  import ArenaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ArenaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", ArenaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:arena, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ArenaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", ArenaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    scope "/users", Users do
      live_session :redirect_if_user_is_authenticated,
        on_mount: [{ArenaWeb.UserAuth, :redirect_if_user_is_authenticated}] do
        live "/register", UserRegistrationLive, :new
        live "/log_in", UserLoginLive, :new
        live "/reset_password", UserForgotPasswordLive, :new
        live "/reset_password/:token", UserResetPasswordLive, :edit
      end

      post "/log_in", UserSessionController, :create
    end
  end

  scope "/", ArenaWeb do
    pipe_through [:browser, :require_authenticated_user_without_warning]

    get "/", PageController, :home
  end

  scope "/", ArenaWeb do
    pipe_through [:browser, :require_authenticated_user]

    scope "/users", Users do
      live_session :require_authenticated_user,
        on_mount: [{ArenaWeb.UserAuth, :ensure_authenticated}] do
        live "/settings", UserSettingsLive, :edit
        live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
      end
    end
  end

  scope "/", ArenaWeb do
    pipe_through [:browser]

    scope "/users", Users do
      delete "/log_out", UserSessionController, :delete

      live_session :current_user,
        on_mount: [{ArenaWeb.UserAuth, :mount_current_user}] do
        live "/confirm/:token", UserConfirmationLive, :edit
        live "/confirm", UserConfirmationInstructionsLive, :new
      end
    end
  end
end
