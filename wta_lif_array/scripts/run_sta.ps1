# OpenSTA (WSL の Ubuntu にビルド済み: ~/tools/OpenSTA/build/sta) を Windows 側から呼ぶラッパー。
# 使い方 (設計フォルダの中で):
#   ..\run_sta.ps1 sta_timing.tcl            # ログは sta.log
#   ..\run_sta.ps1 sta_power.tcl sta_power.log
# カレントディレクトリを /mnt/c/... に変換して WSL 側で cd し、Tcl スクリプトを渡す。
# 文字コード: OpenSTA は UTF-8 で出力するので、コンソールの受け取りを UTF-8 にし (これをしないと
# 日本語見出しが化ける)、ログも UTF-8 で保存する (Tee-Object -FilePath は UTF-16 になるので使わない)。
param(
    [Parameter(Mandatory = $true)][string]$Script,
    [string]$Log = "sta.log"
)
$drive   = $PWD.Path.Substring(0, 1).ToLower()
$rest    = $PWD.Path.Substring(2).Replace([string][char]92, '/')
$wslPath = "/mnt/$drive$rest"
$prevEnc = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try {
    wsl -d Ubuntu -- bash -lc "cd '$wslPath' && ~/tools/OpenSTA/build/sta -no_splash -exit '$Script'" | Tee-Object -Variable lines
} finally {
    [Console]::OutputEncoding = $prevEnc
}
$lines | Set-Content -Path $Log -Encoding UTF8
