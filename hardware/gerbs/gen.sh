#!/bin/bash
mv radar-Inner1_Cu.gbr radar.g3l
mv radar-Inner2_Cu.gbr radar.g2l
mv radar-Edge_Cuts.gbr radar.gko
rm radar.zip
rm *NPTH*
zip radar.zip *
