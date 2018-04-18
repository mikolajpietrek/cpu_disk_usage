## FUNKCJE ################

spacje() {
  local str="$1"
  if [ $((${#str} % 2)) = 0 ]; then
    str="$str "
  fi
  while [ ${#str} -lt 19 ]; do
    str=" ""$str"" "
  done
  echo "$str"
}

jednostki() {
  local str="$1"
  if [ "$str" -lt 1024 ]; then
    str="$str"" B/s"
  elif [ "$str" -lt 1048576 ]; then
    str=`echo "scale=0; $str/1024" | bc -l`" kB/s"
  elif [ "$str" -lt 1073741824 ]; then
    str=`echo "scale=0; $str/1048576" | bc -l`" MB/s"
  fi
  echo "$str"
}

wykres() {
  local -n tabl=$1
  
  for d in `seq 0 9`; do
    buftab[$d]="${buftab[$d]} ║\e[34m"
  done

  for x in `seq 1 9`; do
    y=`echo "scale=0; 10*${tabl[$x]}/$2" | bc -l`
    for q in `seq 0 9`; do
      s=$((9-$q))
      if [ $s -lt $y ]; then
        buftab[$q]="${buftab[$q]}"" █"
      else
        buftab[$q]="${buftab[$q]}""  "
      fi
    done   
  done 

  for e in `seq 0 9`; do
    buftab[$e]="${buftab[$e]}\e[39m ║ "
  done
}


## PROGRAM ###############

#zmienne poczatkowe
trap 'tput cnorm; exit' SIGINT
tput civis
clear
ramka_pg=" ╔═══════════════════╗ "
ramka_g=" $ramka_pg$ramka_pg$ramka_pg\n"
ramka_ps=" ╠═══════════════════╣ "
ramka_s=" $ramka_ps$ramka_ps$ramka_ps\n"
ramka_pd=" ╚═══════════════════╝ "
ramka_d=" $ramka_pd$ramka_pd$ramka_pd\n"
dstat=`grep ' sda ' /proc/diskstats`;
osr=`echo $dstat | sed -E "s/.*sda ([0-9]+ ){2}([0-9]+).*/\2/"`
osw=`echo $dstat | sed -E "s/.*sda ([0-9]+ ){6}([0-9]+).*/\2/"`
ot=`date +%s%N | cut -b1-13`
tabr=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
tabw=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
tabc=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sleep 0.01

#nieskonczona petla
while [ 1 ]; do

#pobieranie nowych danych - czas sys, sektory przeczytane, sektory zapisane
  t=`date +%s%N | cut -b1-13`
  #printf `echo "scale=2; ($t-$ot)" | bc -l`
  dstat=`grep ' sda ' /proc/diskstats`;
  sr=`echo $dstat | sed -E "s/.*sda ([0-9]+ ){2}([0-9]+).*/\2/"`
  sw=`echo $dstat | sed -E "s/.*sda ([0-9]+ ){6}([0-9]+).*/\2/"`
  r=`echo "scale=0; (($sr-$osr)*512*1000)/($t-$ot)" | bc -l`
  w=`echo "scale=0; (($sw-$osw)*512*1000)/($t-$ot)" | bc -l`
  
#pobieranie nowych danych - loadavg
  lavg=`cat /proc/loadavg`;
  com=`echo $lavg | sed -E "s/ .*//"`
  comc=`echo "scale=0; $com*100" | bc -l| sed -E "s/\..*//"`

#zapamiętanie wartości w tablicy 
  tabr[0]=$r
  tabw[0]=$w
  tabc[0]=$comc

#inicjowanie zmiennych wartości maksymalnych
  maxr=1
  maxw=1
  maxc=1

#przesuwanie wszystkich elementów tablic o 1, wyznaczanie maksimum
  for x in `seq 0 8`; do
    x1=`echo "scale=0; 8-$x" | bc -l`
    x2=`echo "scale=0; 9-$x" | bc -l`
    tabr[$x2]=${tabr[$x1]}
    tabw[$x2]=${tabw[$x1]}
    tabc[$x2]=${tabc[$x1]}
    if [ "${tabr[$x2]}" -gt $maxr ]; then
      wyklr=`echo "(l(${tabr[$x2]}) / l(2))+1" | bc -l | sed -E "s/\..*//"` 
      maxr=`echo "scale=0; 2^$wyklr" | bc -l` 
      #maxr="${tabr[$x2]}"
    fi
    if [ "${tabw[$x2]}" -gt $maxw ]; then
      wyklw=`echo "(l(${tabw[$x2]}) / l(2))+1" | bc -l | sed -E "s/\..*//"` 
      maxw=`echo "scale=0; 2^$wyklw" | bc -l` 
      #maxw="${tabw[$x2]}"
    fi
    if [ "${tabc[$x2]}" -gt $maxc ]; then
      maxc="${tabc[$x2]}"
    fi
  done

#rysowanie wykresow
 wykres tabr "$maxr"
 wykres tabw "$maxw"
 wykres tabc "$maxc"

#przepisanie bufora liniowego do bufora glownego
  for u in `seq 0 9`; do
    buf="$buf"" ${buftab[$u]}""\n"
    buftab[$u]=""
  done   

#zapisanie wartosci tekstowych
  bufor_sr=$(jednostki "$maxr")
  bufor_sw=$(jednostki "$maxw")
  bufor_sc=`echo "scale=2; $maxc/100" | bc -l | sed -E "s/^(\.)/0\./"`
  bufor_vr="Odczyt: "$(jednostki "$r")
  bufor_vw="Zapis: "$(jednostki "$w")
  bufor_vc="CPU (1 min): ""$com"

#wysrodkowanie
  bufor_sr=$(spacje "↓ $bufor_sr")
  bufor_sw=$(spacje "↓ $bufor_sw")
  bufor_sc=$(spacje "↓ $bufor_sc")
  bufor_vr=$(spacje "$bufor_vr")
  bufor_vw=$(spacje "$bufor_vw")
  bufor_vc=$(spacje "$bufor_vc")

#buforowanie linii naglowkowych
  bufor_s="  ║$bufor_sr║  ║$bufor_sw║  ║$bufor_sc║ \n"
  bufor_v="   $bufor_vr    $bufor_vw    $bufor_vc \n"

#czyszczenie ekranu, drukowanie pelnego bufora
  wydruk="\n""$bufor_v""\n""$ramka_g""$bufor_s""$ramka_s""$buf""$ramka_d"
  buf=""
  tput cup 0 0 
  printf "$wydruk"

#zapisywanie poprzednich wartości sektorów i czasu
  osr=$sr
  osw=$sw
  ot=$t

#zasypianie
  tk=`date +%s%N | cut -b1-13`
  if [ `echo "scale=0; ($tk-$t)" | bc -l` -lt 1000 ]; then
    sleep `echo "scale=2; (1000-$tk+$t)/1000" | bc -l`
  fi
done
