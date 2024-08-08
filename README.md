# MEZW65C_RAM<br>
<br>
EMUZ80で、W65C02Sを動かすメザニンボードとして、＠S_OkueさんのEMUZ80-6502RAM<br>
が2022年にGithubで公開されています。<br>
https://github.com/satoshiokue/EMUZ80-6502RAM
<br>
<br>
EMUZ80-6502RAMは、PIC18F47QXX（PIC18F47Q43/Q84/Q83）によってコントロール<br>
されています。とてもシンプルな構造となっており、6502に初めて触れる人には最適<br>
と言えます。<br>
<br>
EMUZ80は、電脳伝説さんが開発し公開されているSBCです。Z80の制御にPIC18F57Q43を<br>
使用し、最小限度の部品構成でZ80を動かしています。<br>
<br>
＜電脳伝説 - EMUZ80が完成＞  <br>
https://vintagechips.wordpress.com/2022/03/05/emuz80_reference  <br>
<br>
今回、W65C816Sと、W65C02S用に、512KBのメモリとSDカードI/Fを追加したメザニンボード、<br>
MEZW65C_RAMを作成しました。EMUZ80にアドオンすることで動作します。<br>
PIC18F47QXX（PIC18F47Q43/Q84/Q83）から、SDカード上にある6502用のプログラムを<br>
読み込んで、W65C816S/W65C02Sで実行させることが出来ます。
<br>

MEZW65C_RAMを搭載したEMUZ80<br>
![MEZW65C_RAM 1](photo/p1.JPG)
<br>

MEZW65C_RAMM拡大<br>
![MEZW65C_RAM 2](photo/p2.JPG)

# 特徴<br>
<br>
・CPU : W65C816Sまたは、W65C02相当 8MHz動作<br>
　　　　(W65C816S6TPG-14, W65C02S6TPG-14で確認）<br>
・Microcontroller : PIC18F47Q43, PIC18F47Q84, PIC18F47Q83<br>
・512K SRAM搭載(AS6C4008-55PCN)<br>
・μSDカードI/F（SPI)<br>
・UART（9600bps無手順）<br>
・動作ソフト（起動時に選択可能）<br>
　　1) Universal Monitor 6502<br>
　　2) 6502_EhBASIC_V2.22<br>
　　3) W65C816用ネイティブモニタ（sxb-hacker）<br>
<br>

6502 EhBASIC V2.22の起動画面<br>
![MEZW65C_RAM 3](photo/W65C816S_basic.png)







ASCIIARTの実行結果<br>
![MEZW65C_RAM 8](photo/ascii.png)


Universal Monitor 6502の起動画面<br>
![MEZW65C_RAM 4](photo/unimon.png)


W65C816Sのネイティブモニタ起動画面<br>
![MEZ68K8_RAM 5](photo/nativeMon.png)


MEZ68K8_RAMシルク画像<br>
![MEZ68K8_RAM 6](photo/sm_white_top.png)


# ファームウェア（FW）
@hanyazouさんが作成したZ80で動作しているCP/M-80用のFWを<br>
(https://github.com/hanyazou/SuperMEZ80) 源流（ベース）にしています。<br>
今回は、MEZ68K8_RAM（https://github.com/akih-san/MEZ68K8_RAM） 用のFWを<br>
ベースにMWZW65C_RAM用のFWとして動作するように修正を加えました。<br>
<br>
<br>
# 開発環境<br>
・WDCTools<br>
アセンブラ、リンカーは、WDC社が提供するW65C816S/W65C02S開発ツールを使用しています。<br>
ここから、入手できます。<br>
https://wdc65xx.com/WDCTools<br>
<br>
・bin2mot.exe、mot2bin.exe<br>
モトローラフォーマットのヘキサファイルとバイナリファイル相互変換ツール<br>
ソースとバイナリファイルは、ここから入手できます。<br>
https://sourceforge.net/projects/bin2mot/files/<br>
<br>
<br>
# その他のツール
・FWのソースのコンパイルは、マイクロチップ社の<br>
<br>
　「MPLAB® X Integrated Development Environment (IDE)」<br>
<br>
　を使っています。（MPLAB X IDE v6.20）コンパイラは、XC8を使用しています。<br>
（https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide）<br>
<br>
・FatFsはR0.15を使用しています。<br>
　＜FatFs - Generic FAT Filesystem Module＞<br>
　http://elm-chan.org/fsw/ff/00index_e.html<br>
<br>

# 参考
＜EMUZ80＞<br>
EUMZ80はZ80CPUとPIC18F47Q43のDIP40ピンIC2つで構成されるシンプルなコンピュータです。<br>
（電脳伝説 - EMUZ80が完成）  <br>
https://vintagechips.wordpress.com/2022/03/05/emuz80_reference  <br>
<br>
＜SuperMEZ80＞<br>
SuperMEZ80は、EMUZ80にSRAMを追加しZ80をノーウェイトで動かすことができます。<br>
<br>
＜SuperMEZ80＞<br>
https://github.com/satoshiokue/SuperMEZ80<br>
<br>
＜＠hanyazouさんのソース＞<br>
https://github.com/hanyazou/SuperMEZ80/tree/mez80ram-cpm<br>
<br>
＜@electrelicさんのユニバーサルモニタ＞<br>
https://electrelic.com/electrelic/node/1317<br>

＜オレンジピコショップ＞  <br>
オレンジピコさんでEMUZ80、その他メザニンボードの購入できます。<br>
<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-051.html<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-061.html<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-062.html<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-079.html<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-087.html<br>
https://store.shopping.yahoo.co.jp/orangepicoshop/pico-a-089.html<br>
