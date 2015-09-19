mygit
===

Githubのレポジトリをローカルで作成するクライアント

まず最初に`./mygit --configure`を実行して，Githubトークンを貼り付けて，

`token=*****`の形で`$HOME/.mygit.conf`ファイルに保存されます．

`$ ./mygit --repo=testrepo`でレポジトリを作成します．


```
$ mix deps.get
$ mix escript.build

$ ./mygit  # 使い方が表示されます
mygit --configure
  Accept a github token to create the '.mygit.conf' file
  mygit --repo=testrepo
    Create a repo named 'testrepo'

$ ./mygit --configure # githubのtokenが要求される
Please input your token:

$ ./mygit
mygit --configure
  Accept a github token to create the '.mygit.conf' file
mygit --repo=testrepo
  Create a repo named 'testrepo'

$ ./mygit --repo=testrepo # github.comにtestrepoレポジトリが作成される
Repository 'testrepo' created successfully.
You can clone the repository using the following command

git clone git://github.com/ColdFreak/testrepo.git
```
