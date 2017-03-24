#!/bin/csh
## Shell script to run Q-GCM double gyre example.
## Q-GCM will run in segments of 5 years

## Choose file structure
set basedir = ./
set run = double_gyre_test
set qgdir = ../../src
## Choose to run maxcount segments of yrinc years each.
set maxcount = 10
set yrinc = 5   ## This must match trun in input.params.

if ( -f count.file ) then
    echo "Count file exists"
    ## ensure model will start off lastday file, rather than rbal
    sed -e "s/rbal/lastday.nc/g" input.params > tmp.params
    cp tmp.params input.params
    rm tmp.params
else
    echo "Count file does not exist - making count.file ..."
    echo 1 >count.file || exit
    chmod 0400 count.file # read-only
    ## make a new data directory
    echo "... and making directory "$run
    mkdir $basedir/$run || exit # exit if $run dir already exists
    ## set model to start off as rbal
    sed -e "s/lastday.nc/rbal/g" input.params > tmp.params
    cp tmp.params input.params
    rm tmp.params
endif

set count=`cat <count.file` || exit # exits if count.file has no read access
chmod 0000 count.file # no access - prevents a concurrent run of this script unless we're very unlucky with timing

echo "Run number " $count " of " $maxcount

if ( $count > $maxcount ) then
    echo "Count exceeds maxcount. Removing count.file and exiting."
    chmod 0200 count.file # write-only
    rm count.file
    exit
endif

if ( -d $basedir/$run ) then # if count.file already existed but $runs doesn't
else
    echo "Error: "$basedir/$run" doesn't exist. Removing count.file and exiting."
    chmod 0200 count.file # write-only
    rm count.file
    exit
endif

echo "q-gcm starting  ..... "
date
echo "---------------------"

cp input.params outdata/
cp parameter.src outdata/
cp qgrun.sh outdata/
setenv OMP_NUM_THREADS 4 

time nice $qgdir/q-gcm >& outdata/zz.out

echo "q-gcm finished"
echo "---------------------"
date

## copy a restart file here
cp outdata/lastday.nc .

## move data to data directory, with yrs file structure
@ ppa =  $yrinc * ($count - 1)
@ ppb =  $yrinc * $count
printf %03d-%03d $ppa $ppb > tmp.zz
set ct=`cat <tmp.zz`
rm tmp.zz
mkdir $basedir/$run/yrs$ct
mv outdata/*  $basedir/$run/yrs$ct/
echo "Saving data to $basedir/$run/yrs"$ct
 
if ( $count >= $maxcount ) then
    echo "All " $count " Jobs Finished"
    chmod 0200 count.file # write-only
    rm count.file # NB: a re-run starts from count=1 but with lastday.nc from the end of this run
    exit
else
    echo "Jobs Not Finished"
    echo "Self-submitting next job"
endif
@ count++
chmod 0200 count.file # write-only
echo $count >count.file
chmod 0400 count.file # read-only

./qgrun.sh &

exit
