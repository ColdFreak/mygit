defmodule Mygit do
  require Logger
  def main(args) do
    args |> parse_args |> process
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args, switches: [repo: :string, configure: :boolean ])
    # options is a Keyword list
    options
  end

  def process([]) do
    IO.puts "No arguments given"
  end
  
  # ./mygit --repo=hello
  # helloというレポジトリが作成される
  def process([{:repo , name} | _T]) do
    home = System.user_home
    conf_file = Path.join([home, ".mygit.conf"])
    case File.exists?(conf_file) do
      true -> 
        token = get_token(conf_file)
      false -> IO.puts "failed"
    end
  
  
    url = Application.get_env(:mygit, :post_url)
    headers = [{"Authorization", "token #{token}"}]
    json_data = %{name: name, auto_init: true, private: false, gitignore_template: "nanoc"} |> Poison.encode!
    response = HTTPoison.post!(url, json_data, headers)
  end

  def process([{:configure, true} | _T]) do
    input = IO.gets "Please input your token: "
    input_token = input |> String.strip

    home = System.user_home
    conf_file = Path.join([home, ".mygit.conf"])
    {:ok, file} = File.open conf_file, [:write]
    IO.binwrite file, "token=#{input_token}"
    File.close file
  end
  
  def get_token(file) do
    {result, device} = File.open(file, [:read, :utf8])
    token = IO.read(device, :line) |> String.split("=") |> Enum.at(1) 
  end
end
