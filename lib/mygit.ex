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
    case get_token(conf_file) do
      {:ok, token} -> headers = [{"Authorization", "token #{token}"}]
      {:error, _} -> 
        IO.puts "failed to retrieve token from $HOME/.mygit.conf"
        exit("exit")
    end
  
    url = Application.get_env(:mygit, :post_url)
    # 送信するjsonデータを組み立てる
    json_data = %{name: name, auto_init: true, private: false, gitignore_template: "nanoc"} |> Poison.encode!
    HTTPoison.post!(url, json_data, headers)
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
    try do
      {result, device} = File.open(file, [:read, :utf8])
      token = IO.read(device, :line) |> String.split("=") |> Enum.at(1) 
      {:ok, token}
    rescue
      RuntimeError -> {:error, "Invalid file"}
      ArgumentError -> {:error, "Token not found"}
    end
  end
end
