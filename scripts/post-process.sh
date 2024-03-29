#!/bin/bash

#Directory with 3D-2PT installation
mypath=/home/mheyden1/3D-2PT

#Reference structure (*.gro format) for solute (center of mass at 0,0,0)a
refGRO=run-1/align_ref.gro

#The prefix of the output file names was set in the water3D and pot3D input files
#Provide their location here so that the prefix can be extracted from the last line
#NOTE: the same prefix is expected for the output files of water3D and pot3D 
input=run-1/water3D.input
if [ ! -f ${input} ]; then
echo "error: file ${input} not found"
exit
fi
prefix=`tail -n 1 ${input}`

#the following arrays contain identifying parts of the output filenames generated by water3D and pot3D
#this script should be run in a directory that contans sub-directories run-1, run-2,..., run-N
#each of these subdirectories must contain a full set of these files or an error is reported
#MODIFY IF NEEDED
cubes=( pot3D-numDens water3D-COMmsd-1.600ps water3D-plane2Prot water3D-rot1-1.600ps pot3D-Uss water3D-numDens water3D-pol2Prot water3D-rot2-1.600ps pot3D-Uxs water3D-OH2Prot water3D-pol water3D-rot3-1.600ps )
avCubes=( pot3D-numDens water3D-numDens )
w1avCubes=( pot3D-Uss pot3D-Uxs )
w2avCubes=( water3D-COMmsd-1.600ps water3D-plane2Prot water3D-rot1-1.600ps water3D-pol2Prot water3D-rot2-1.600ps water3D-OH2Prot water3D-pol water3D-rot3-1.600ps )
data=( water3D-AngMomProj1-VDOS_df-10.450wn_maxf-2090.000wn water3D-HydVel-VDOS_df-10.450wn_maxf-2090.000wn water3D-AngMomProj2-VDOS_df-10.450wn_maxf-2090.000wn water3D-AngMomProj3-VDOS_df-10.450wn_maxf-2090.000wn water3D-OxyVel-VDOS_df-10.450wn_maxf-2090.000wn water3D-COMvel-VDOS_df-10.450wn_maxf-2090.000wn )
Scubes=( water3D-rotS water3D-totalS water3D-transS )

################################################
#NO CHANGES SHOULD BE REQUIRED BEYOND THIS POINT
################################################

#now we count all run-x directories and check their content for completeness
i=1
while [ -d run-${i} ]
do
cd run-${i}
    for file in ${cubes[@]}
    do
        if [ ! -f ${prefix}_${file}.cube ]; then
            echo "-file run-${i}/${prefix}_${file}.cube not found"
            echo "-exiting"
            exit
        fi
    done
    for file in ${data[@]}
    do
        if [ ! -f ${prefix}_${file}.dat ]; then
            echo "-file run-${i}/${prefix}_${file}.dat not found"
            echo "-exiting"
            exit
        fi
    done
    echo "-directory run-${i} contains complete 3D-2PT data set"
cd ..
((i+= 1))
done
if [ ${i} -eq 1 ]; then
echo "-no 3D-2PT data found for averaging"
echo "-exiting"
exit
fi
iMax=`expr $i - 1`
echo "-found ${iMax} directories with complete 3D-2PT data sets for averaging"

#We extract the dimensions of the analysis grid directly from one of the output files
grid=`head -n 6 run-1/${prefix}_water3D-numDens.cube | tail -n 3 | awk '{printf("%d ",$1);};'`

mkdir average
cd average

cubeIdx=0
while [ ${cubeIdx} -lt ${#avCubes[@]} ]
do
i=1
while [ $i -le ${iMax} ]
do
if [ $i -eq 1 ]; then
echo "${iMax}"
fi
echo "../run-${i}/${prefix}_${avCubes[cubeIdx]}.cube"
if [ $i -eq ${iMax} ]; then
echo "${prefix}_${avCubes[cubeIdx]}.cube"
fi
((i+= 1))
done >& avercube.input
${mypath}/bin/averCubefiles.exe < avercube.input
((cubeIdx+= 1))
done

cubeIdx=0
while [ ${cubeIdx} -lt ${#w1avCubes[@]} ]
do
i=1
while [ $i -le ${iMax} ]
do
if [ $i -eq 1 ]; then
echo "${iMax}"
fi
echo "../run-${i}/${prefix}_${w1avCubes[cubeIdx]}.cube"
echo "../run-${i}/${prefix}_pot3D-numDens.cube"
if [ $i -eq ${iMax} ]; then
echo "${prefix}_${w1avCubes[cubeIdx]}.cube"
fi
((i+= 1))
done >& avercube.input
${mypath}/bin/weightedAverCubeFiles.exe < avercube.input
((cubeIdx+= 1))
done

cubeIdx=0
while [ ${cubeIdx} -lt ${#w2avCubes[@]} ]
do
i=1
while [ $i -le ${iMax} ]
do
if [ $i -eq 1 ]; then
echo "${iMax}"
fi
echo "../run-${i}/${prefix}_${w2avCubes[cubeIdx]}.cube"
echo "../run-${i}/${prefix}_water3D-numDens.cube"
if [ $i -eq ${iMax} ]; then
echo "${prefix}_${w2avCubes[cubeIdx]}.cube"
fi
((i+= 1))
done >& avercube.input
${mypath}/bin/weightedAverCubeFiles.exe < avercube.input
((cubeIdx+= 1))
done

for file in ${cubes[@]}
do
    if [ ! -f ${prefix}_${file}.cube ]; then
        echo "-file average/${prefix}_${file}.cube not found"
        echo "-averaging seems to have failed"
        echo "-exiting"
        exit
    fi
    size=`ls -rtl ${prefix}_${file}.cube | awk '{printf("%s\n",$5);};'`
    if [ ${size} -lt 100 ]; then
        echo "-file average/${prefix}_${file}.cube is too small (${size} kB)"
        echo "-averaging seems to have failed"
        echo "-exiting"
        exit
    fi
done

dataIdx=0
while [ ${dataIdx} -lt ${#data[@]} ]
do
i=1
while [ $i -le ${iMax} ]
do
if [ $i -eq 1 ]; then
echo "${iMax}"
fi
echo "../run-${i}/${prefix}_${data[dataIdx]}.dat"
if [ $i -eq ${iMax} ]; then
echo "200"
echo "${grid}"
echo "${prefix}_${data[dataIdx]}.dat"
fi
((i+= 1))
done >& average.input
${mypath}/bin/average.exe average.input 
((dataIdx+= 1))
done

for file in ${data[@]}
do
    if [ ! -f ${prefix}_${file}.dat ]; then
        echo "-file average/${prefix}_${file}.dat not found"
        echo "-averaging seems to have failed"
        echo "-exiting"
        exit
    fi
    size=`ls -rtl ${prefix}_${file}.dat | awk '{printf("%s\n",$5);};'`
    if [ ${size} -lt 100 ]; then
        echo "-file average/${prefix}_${file}.dat is too small (${size} kB)"
        echo "-averaging seems to have failed"
        echo "-exiting"
        exit
    fi
done

#CONVERT LOCAL VIBRATIONAL DENSITY OF STATES INTO ENTROPIES
${mypath}/bin/trans-vdos2entropy_lowMem.exe ${prefix}_water3D-COMvel-VDOS_df-10.450wn_maxf-2090.000wn.dat ${prefix}_water3D-numDens.cube 33.4273 > ${prefix}_water3D-transS.cube
${mypath}/bin/rot-vdos2entropy_lowMem.exe ${prefix}_water3D-AngMomProj1-VDOS_df-10.450wn_maxf-2090.000wn.dat ${prefix}_water3D-AngMomProj2-VDOS_df-10.450wn_maxf-2090.000wn.dat ${prefix}_water3D-AngMomProj3-VDOS_df-10.450wn_maxf-2090.000wn.dat ${prefix}_water3D-numDens.cube 33.4273 > ${prefix}_water3D-rotS.cube
cat << STOP >& tmp
2
${prefix}_water3D-transS.cube
${prefix}_water3D-rotS.cube
STOP
${mypath}/bin/add_cubes.exe tmp > ${prefix}_water3D-totalS.cube
rm tmp

for file in ${Scubes[@]}
do
    if [ ! -f ${prefix}_${file}.cube ]; then
        echo "-file average/${prefix}_${file}.cube not found"
        echo "-entropy calculation seems to have failed"
        echo "-exiting"
        exit
    fi
    size=`ls -rtl ${prefix}_${file}.cube | awk '{printf("%s\n",$5);};'`
    if [ ${size} -lt 100 ]; then
        echo "-file average/${prefix}_${file}.cube is too small (${size} kB)"
        echo "-entropy calculation seems to have failed"
        echo "-exiting"
        exit
    fi
done

echo "-averaging 3D-2PT output for ${iMax} data sets complete"

#Compute Solvation Free Energy Maps and Total Solvation Free Energies
echo "-processing 3D-2PT data in directory average"
if [ -f ${refGRO} ]; then
ref=${refGRO}
elif [ -f ../${refGRO} ]; then
ref=../${refGRO}
else
echo "file ${refGRO} not found"
exit
fi
cat << STOP >& process.input
${ref}
${prefix}_pot3D-numDens.cube
10.0
${prefix}_pot3D-numDens.cube
${prefix}_pot3D-Uxs.cube
${prefix}_pot3D-Uss.cube
${prefix}_water3D-numDens.cube
${prefix}_water3D-totalS.cube
300
0.2
STOP
${mypath}/bin/process-cube.exe < process.input

cd ..
echo "DONE"
