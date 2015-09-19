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
    usage= ~s(mygit --configure\n  Accept a github token to create the '.mygit.conf' file\nmygit --repo=testrepo\n  Create a repo named 'testrepo'
    )
    IO.puts usage
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
    response = HTTPoison.post!(url, json_data, headers)
    result = handle_response(response, name)
    IO.puts result
  end


  def process([{:configure, true} | _T]) do
    input_token = get_input
    home = System.user_home
    conf_file = Path.join([home, ".mygit.conf"])
    {:ok, file} = File.open conf_file, [:write]
    IO.binwrite file, "token=#{input_token}"
    File.close file
  end
  
  def handle_response(%HTTPoison.Response{body: body, status_code: 201}, name) do
    decoded_body = body |> Poison.decode!
    {:ok, git_url} = decoded_body |> Map.fetch("git_url")
    output = ~s(Repository '#{name}' created successfully.\nYou can clone the repository using the following command\n\ngit clone #{git_url}\n )
    output

  end

  def handle_response(%HTTPoison.Response{status_code: 401}, name) do
    "Failed to create the repository '#{name}', please provide a valid token"
  end

  def handle_response(%HTTPoison.Response{status_code: 422}, name) do
    "Repository '#{name}' already exists on this account. Failed"
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

  def get_input do
    input = IO.gets "Please input your token: "
    input_token = input |> String.strip
    case String.length(input_token) do
      0 ->
        get_input
      _ ->
        input_token
    end
  end
end
