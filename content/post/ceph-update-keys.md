+++
date = '2026-11-14T20:46:13+09:00'
draft = false
title = 'Ceph のキー暗号化方式を変更する'
+++

ProxmoxVE のアップデートをしていると、 Ceph のヘルスが真っ赤になっていることに気がついた。
なんだろうと思ってみてみると、「正常に動作してはいるものの、 Ceph の認証周りで脆弱性が見つかったから新しい認証方式(正確に言えば鍵作成に利用される暗号方式)へ変更するまでは Health: WARN にするよ。」ということらしい。
とりあえず表示されている Ceph のリンクを踏んでやり方を学ぶ。

色々注意事項が書かれているが、普通に3つ以上のノードで立てている場合は表示されているコマンドでテストと実行を行えば良さそう。  
(複数ノードで同時に実行するな、とか root 権限で動かせ、とかは守らないと動作しないと思いますので、そこら辺はよしなに)

まずはちゃんと更新できるかの確認用コマンドを実行。  
`/usr/share/pve-manager/migrations/pve-cephx-rotate-service-keys --rotate-cluster-keys --verbose`

上記コマンドを流して最後に
```
Dry run finished
PASS: Preflight checks passed for the displayed plan.
```
と表示されれば更新できる。  
`Review the plan, then run this again with '--apply' to carry it out.` 
と言われるはずなので指示通り確認用コマンドに `--apply` をつけて再度実行する。

`/usr/share/pve-manager/migrations/pve-cephx-rotate-service-keys --rotate-cluster-keys --verbose --apply`

実行すると最初に
```
WARN: Do not start a rolling restart from the web interface until this run finishes: the lock guarding against that is advisory.
(注意: このコマンドによる処理を実行している間は Web インターフェースからローリングスタートを開始しないでください。ロック機構が動作しない恐れがあります。)

Apply this run, including recovery and any requested key confirmations? (y/N) 
(この処理を続行してリカバリと鍵を承認しますか?)
```
と聞かれるので y で続行。(カッコ内はざっくり和訳)

```
Done
PASS: The manager, metadata, server, and OSD keys of this cluster now use the 'aes256k' cipher.
```
と表示されれば更新終了。  
`/etc/pve/priv/cephx-key-migration.json` は結構重要なもので、以降のステップが完全に終了するまで大事に保管すること、とのことなので中身をぶっこ抜いてどうにかする。 `Remaining migration steps` として残りのステップが表示されていたので実行していく。
 
`/usr/share/pve-manager/migrations/pve-cephx-rotate-service-keys --rotate-all-storage-keys --rotate-admin-key --verbose`  
を実行し通しで成功するか確認する。
```
Done run finished
PASS: Preflight checks passed for the displayed plan.
```
と表示されれば成功。

成功したら `--apply` をつけて再度実行する。
途中に y/N を聞かれるが問題ないので y で続行。
PASS が 2 回ほど表示されて最後に Done と出れば実行完了。

ここで VM をマイグレーションしたり LXC を停止して再起動したりする工程が入る。
今回は ProxmoxVE のホスト側にも Linux カーネルの更新が溜まっていたのでホストごと再起動する。

再起動完了後に  
`/usr/share/pve-manager/migrations/pve-cephx-roate-service-keys --apply --confirm-all-clients-refreshed --restrict-ciphers`  
を実行。
確認を y で許可。

最後に `Done` が表示されれば OK
ここまで実行してもまだ Ceph の WebUI でのヘルス表示が WARN になっていることがあるが、 `cpeh health detail` を実行して 
```
[WRN] AUTH_INSECURE_ROTATING_SERVICE_KEY_TYPE: ~~~ 
```
のように表示されていれば OK。数時間もすれば古い鍵の期限が切れて自動的に新しい鍵へ移行し警告は消える。

やった〜
