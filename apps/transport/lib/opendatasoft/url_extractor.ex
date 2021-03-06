defmodule Opendatasoft.UrlExtractor do
  @moduledoc """
    Opendatasoft publishes a CSV file with an url to the GTFS

    This module extracts the actual url
  """
  require Logger

  @separators [?;, ?,]
  @csv_headers ["Download", "file", "Fichier", "fichier à télécharger"]

  def get_csv_resources(resources) do
    csv_resources = filter_csv(resources)

    with {:ok, bodys} <- download_csv_list(csv_resources),
         {:ok, urls} <- get_url_from_csv(bodys) do
      Enum.map(urls, fn u -> %{"url" => u.url, "format" => "csv", "title" => u.title} end)
    else
      {:error, error} ->
        Logger.warn(" <message>  #{inspect error}")
        Enum.each(resources, fn resource ->
          Logger.warn(" <resource> #{resource["url"]}")
        end)

        []
    end
  end

  @doc """
  filter csv http response

  ## Examples
      iex> {:ok, %{headers: [{"Content-Type", "text/csv"}]}}
      ...> |> ImportData.has_csv?
      true

      iex> {:ok, %{headers: [{"Content-Type", "application/zip"}]}}
      ...> |> ImportData.has_csv?
      false

      iex> {:error, "pouet"}
      ...> |> ImportData.has_csv?
      false

  """
  def has_csv?({:ok, %{headers: headers}}) do
    Enum.any?(headers, fn {k, v} ->
      k == "Content-Type" && String.contains?(v, "csv")
    end)
 end

 def has_csv?(_), do: false

 defp download_csv_list(resources) when is_list(resources) do
   resources
   |> Enum.map(&download_csv/1)
   |> Enum.filter(&has_csv?/1)
   |> case do
     bodys = [_ | _] -> {:ok, Enum.map(bodys, fn {_, v} -> v.body end)}
     [] -> {:error, "No csv found"}
   end
 end

 defp download_csv(%{"url" => url}) do
   case HTTPoison.get(url) do
     {:ok, response = %{status_code: 200}} ->
       {:ok, response}
     {:ok, response} ->
       {:error, "Bad status code, needs 200, wants #{response.status_code}"}
     {:error, error} ->
       {:error, error}
   end
 end

 @doc """
 Get a download from a CSVs if it exists

 ## Examples
     iex> ["name,file\\ntoulouse,http", "stop,lon,lat\\n1,48.8,2.3"]
     ...> |> ImportData.get_url_from_csv()
     "http"

     iex> |> ImportData.get_url_from_csv()
     {:error, "No column file"}

 """
 def get_url_from_csv(bodies) when is_list(bodies) do
   bodies
   |> Enum.map(&get_url_from_csv/1)
   |> Enum.filter(fn {status, _} -> status == :ok end)
   |> case do
     urls = [_ | _] -> {:ok, Enum.map(urls, fn {_, v} -> v end)}
     [] -> {:error, "No url found"}
   end
 end

 @doc """
 Get a download from a CSV if it exists

 ## Examples
     iex> "name,file\\ntoulouse,http"
     ...> |> ImportData.get_url_from_csv()
     {:ok, {url: "http", title: "http"}}

     iex> "stop,lon,lat\\n1,48.8,2.3"
     ...> |> ImportData.get_url_from_csv()
     {:error, "No column file"}

     iex> "Donnees;format;Download\\r\\nHoraires des lignes TER;GTFS;https\\r\\n"
     ...> |> ImportData.get_url_from_csv()
     {:ok, {url: "https", title: "https"}}

 """
 def get_url_from_csv(body) do
   @separators
   |> Enum.map(&(get_url_from_csv(&1, body)))
   |> Enum.filter(&(&1 != nil))
   |> case do
     [url | _] -> {:ok, %{url: url, title: get_filename(url)}}
     _ -> {:error, "No column file"}
   end
 end

 def get_url_from_csv(separator, body) do
   case StringIO.open(body) do
     {:ok, out} ->
       out
       |> IO.binstream(:line)
       |> CSV.decode(headers: true, separator: separator)
       |> Enum.take(1)
       |> case do
         [ok: line] -> get_url_from_csv_line(line)
         [error: error] ->
           Logger.error(error)
           nil
         _ -> nil
       end
   end
 end

 defp get_url_from_csv_line(line) do
   @csv_headers
   |> Enum.map(&(Map.get(line, &1)))
   |> Enum.filter(&(&1 != nil))
   |> case do
     [] -> nil
     [head | _] -> head
   end
 end

  @doc """
  filter dataset with csv resources

  ## Examples
      iex> [%{"mime" => "text/csv", "format" => nil}]
      ...> |> ImportData.filter_csv
      [%{"mime" => "text/csv", "format" => "csv"}]

      iex> [%{"mime" => nil, "format" => "csv"}]
      ...> |> ImportData.filter_csv
      [%{"mime" => "text/csv", "format" => "csv"}]

      iex> [%{"mime" => nil, "format" => "CSV"}]
      ...> |> ImportData.filter_csv
      [%{"mime" => "text/csv", "format" => "csv"}]

      iex> [%{"mime" => "text/cv", "format" => nil}]
      ...> |> ImportData.filter_csv
      []

      iex> [%{"mime" => "text/csv", "format" => nil}, %{"mime" => "application/neptune", "format" => nil}]
      ...> |> ImportData.filter_csv
      [%{"mime" => "text/csv", "format" => "csv"}]

  """
  def filter_csv(resources) do
    for resource <- resources, "#{resource["mime"]}#{resource["format"]}" =~ ~r/csv/i do
      %{resource | "mime" => "text/csv", "format" => "csv"}
    end
  end

  defp get_filename(url) do
    with {:ok, %HTTPoison.Response{headers: headers}} <- HTTPoison.head(url),
         {_, content} <- Enum.find(headers, fn {h, _} -> h == "Content-Disposition" end),
         %{"filename" => filename} <- Regex.named_captures(~r/filename="(?<filename>.*)"/, content) do
      filename
    else
      _ -> url
    end
  end

end
