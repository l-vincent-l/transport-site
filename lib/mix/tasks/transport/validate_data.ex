defmodule Mix.Tasks.Transport.ValidateData do
  @moduledoc """
  Queues all ok data to validation and appends the task id to the dataset.
  """

  use Mix.Task
  alias Transport.ReusableData
  alias Transport.DataValidator.Server

  def run(_) do
    Mix.Task.run("app.start", [])

    ReusableData.list_datasets
    |> Enum.each(fn(dataset) ->
      with {:ok, id} <- Server.validate_data(dataset.download_uri),
           :ok       <- ReusableData.update_dataset(dataset, %{"celery_task_id" => id}) do

        IO.puts("Queued task #{id} for #{dataset.download_uri}")
      else
        {:error, error} -> IO.puts(inspect error)
      end
    end)
  end
end