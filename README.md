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
      sxb-hackerは、WDC社で提供しているW65C816SXBトレーニング<br>
      ボード用に開発されたソフトでAndrew Jacobs氏が作成しました。<br>
      今回、このソフトをMEZW65C_RAM用に移植しました。<br>
      移植に際して、コマンドをなるべくユニバーサルモニタに合わせるように<br>
      変更してあります。？コマンドで見てください。<br>
      （https://github.com/andrew-jacobs/w65c816sxb-hacker）<br>
<br>
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

# PIC18F47Q43/Q84への書き込み
・snap<br>
マイクロチップ社の書き込みツールです。<br>
<br>
・PICkit3<br>
PICkitminus書き込みソフトを用いて、書き込むことが出来ます。以下で入手できます。<br>
http://kair.us/projects/pickitminus/<br>
<br>
<br>
PICへの書き込みツールを用いて、ヘキサファイルを書き込みます。<br>
書き込み用のデータは8MHz用と、4MHz用の2種類用意しました。<br>
<br>
・PIC18F47Q43<br>
　　- R1.2q43_8MHz.hex<br>
　　- R1.2q43_4MHz.hex<br>
<br>
・PIC18F47Q84<br>
　　- R1.2q84_8MHz.hex<br>
　　- R1.2q84_4MHz.hex<br>
<br>
動作周波数の設定は、src/boardsにあるソースファイルw65_bd.cで修正できます。<br>
9MHz以上の設定も出来ますが、動作が不安定です。11MHz以上は動作しません。<br>
<br>
（注意事項）<br>
アクセスタイム55nsのメモリを使用しているため、10MHz付近が限界のようです。<br>
W65C02Sでは、10MHzで動作しています。<br>
W65C816Sでは、エミュレーションモードでは10MHzで動作していますが、ネイティブ<br>
モードに切り替えた場合、BANK0以外では10MHzで動作しませんでした。<br>
<br>
<br>
# ＯＳについて（今後の開発目標）
<br>
MEZW65C_RAM上で動作するＯＳの移植が、今後の課題です。<br>
レトロPCで6502界隈は、現在も非常にアクティブに開発が行われている<br>
ようです。<br>
<br>
・DOS/65 (http://www.z80.eu/dos65.html)<br>
・cpm65 (https://github.com/davidgiven/cpm65?tab=readme-ov-file)<br>
・miniOS (https://github.com/zuiko21/minimOS)<br>
・GeckOS (http://www.6502.org/users/andre/osa/index.html)<br>
<br>
< SDK ><br>
・LLVM-MOS SDK（https://github.com/llvm-mos/llvm-mos-sdk）<br>
<br>
<エミュレーター><br>
・VICE（the Versatile Commodore Emulator）<br>
（https://vice-emu.sourceforge.io/）<br>
<br>
MEZW65C_RAMに移植するＯＳとして、GeckOSを検討しています。<br>
Linuxライクで非常にフレキシブルな構造をしたマルチタスクＯＳです。<br>
現在も開発が続いています。<br>
6502で、ここまでするかぁ～って感じですが、開発者André Fachatさんの<br>
すごい情熱を感じます。<br>
ドキュメントが半端なく揃えられていますが、物凄い量なので大変です。<br>
ファイルシステムは、FAT12をサポートしているとのことなので、<br>
MEZ88_RAMでMS-DOS V2.2を移植した同様の手口が使えるのではないかと思ってます。<br>
MS-DOSとかと違って、カーネルをソースから組み込む必要があり、GeckOS内部構造を<br>
きちんと理解する必要がありそうで、へっぽこボビーストにはかなりのハードルですね。<br>
<br>
ま、焦らず、ゆっくりと取り組んでいこうと思ってます。<br>
<br>
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
