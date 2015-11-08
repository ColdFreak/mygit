defmodule Mygit do
  require Logger
  def main(args) do
    args |> parse_args |> process
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args, switches: [repo: :string, configure: :boolean, list: :boolean ])
    # options is a Keyword list
    options
  end

  def process([]) do
    usage= ~s(mygit --configure\n  Accept a github token to create the '.mygit.conf' file\nmygit --repo=testrepo\n  Create a repo named 'testrepo'\n mygit --list\n  List remote repos
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

  def process([{:list, true} | _T]) do
    url = Application.get_env(:mygit, :post_url)
    home = System.user_home
    conf_file = Path.join([home, ".mygit.conf"])
    case get_token(conf_file) do
     {:ok, token} -> headers = [{"Authorization", "token #{token}"}]
     {:error, _} -> 
       IO.puts "failed to retrieve token from $HOME/.mygit.conf"
       exit("exit")
    end
    response = HTTPoison.get!(url, headers)
    result = handle_list_response(response)
    print_list(result)
  end

  ## [ok: "git@github.com:ColdFreak/Addition.git", ok: "git@github.com:ColdFreak/aws-test.git"]
  ## Enum.mapの結果は上のような結果が帰ってきて，Keyword.valuesでvalueを抽出する
  def handle_list_response(%HTTPoison.Response{body: body, status_code: 200}) do
    decoded_body = body |> Poison.decode!
    repo_list = Enum.map(decoded_body, fn(item) -> Map.fetch(item, "ssh_url") end) |> Keyword.values
    repo_list
  end
  
  def handle_response(%HTTPoison.Response{body: body, status_code: 201}, name) do
    decoded_body = body |> Poison.decode!
    {:ok, git_url} = decoded_body |> Map.fetch("git_url")
    clone_git = parse_url(git_url)
    output = ~s(Repository '#{name}' created successfully.\nYou can clone the repository using the following command\n\ngit clone #{clone_git}\n )
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
      {_result, device} = File.open(file, [:read, :utf8])
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

  # `git://github.com/ColdFreak/test.git` -> `git@github.com:ColdFreak/test.git`
  def parse_url(git_url) do
    url = String.replace(git_url, "git://github.com/", "git@github.com:") 
    url
  end

  def print_list(list) do
    Enum.map(list, fn(item) -> IO.puts item end)
  end
end
