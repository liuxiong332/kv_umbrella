defmodule KVServer do
  use Application

  @listen_port 5678
  @task_supervisor_name KVServer.Echo

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(KVServer.Worker, [arg1, arg2, arg3]),
      worker(Task, [KVServer, :accept]),
      supervisor(Task.Supervisor, [[name: @task_supervisor_name]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KVServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def accept do
    {:ok, socket} = :gen_tcp.listen(@listen_port, [:binary, active: false, packet: :line])
    accept_loop(socket)
  end

  def accept_loop(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    {:ok, task_id} = Task.Supervisor.start_child(@task_supervisor_name, fn -> serve(client_socket))
    :gen_tcp.controlling_process(client_socket, task_id)
    accept_loop(socket)
  end

  def serve(socket) do
    {:ok, packet} = :gen_tcp.recv(socket, 0)
    :gen_tcp.send(socket, packet)
    serve(socket)
  end
end
